import SwiftUI
import SwiftData
import AVFoundation
import Vision
import Combine

// MARK: - Camera preview (UIKit bridge)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - Joint skeleton overlay

struct JointOverlayView: View {
    let result: ROMResult?

    var body: some View {
        GeometryReader { geo in
            if let r = result,
               let hip = r.hipPoint, let knee = r.kneePoint, let ankle = r.anklePoint {
                let hipS   = visionToScreen(hip,   size: geo.size)
                let kneeS  = visionToScreen(knee,  size: geo.size)
                let ankleS = visionToScreen(ankle, size: geo.size)

                Canvas { ctx, _ in
                    var bone = Path()
                    bone.move(to: hipS)
                    bone.addLine(to: kneeS)
                    bone.addLine(to: ankleS)
                    ctx.stroke(bone, with: .color(.white.opacity(0.75)), lineWidth: 3)

                    for pt in [hipS, ankleS] {
                        let r = CGRect(x: pt.x - 6, y: pt.y - 6, width: 12, height: 12)
                        ctx.fill(Path(ellipseIn: r), with: .color(Color(hex: "5B7CF6").opacity(0.85)))
                        ctx.stroke(Path(ellipseIn: r), with: .color(.white), lineWidth: 1.5)
                    }
                    // Knee: larger highlight
                    let kr = CGRect(x: kneeS.x - 8, y: kneeS.y - 8, width: 16, height: 16)
                    ctx.fill(Path(ellipseIn: kr), with: .color(Color(hex: "5B7CF6")))
                    ctx.stroke(Path(ellipseIn: kr), with: .color(.white), lineWidth: 2)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // Vision: origin bottom-left. Screen: origin top-left.
    private func visionToScreen(_ pt: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(x: pt.x * size.width, y: (1 - pt.y) * size.height)
    }
}

// MARK: - ViewModel

final class CameraROMViewModel: NSObject, ObservableObject {
    @Published var romResult: ROMResult?
    @Published var isRunning = false
    @Published var permissionDenied = false
    @Published var maxFlexion: Double = 0

    let session = AVCaptureSession()
    private(set) var romService: VisionROMService
    private let videoQueue = DispatchQueue(label: "pivot.rom.video", qos: .userInteractive)

    var side: OperatedSide { didSet { romService = VisionROMService(side: side, isSupine: isSupine) } }
    var isSupine: Bool     { didSet { romService.isSupine = isSupine } }

    init(side: OperatedSide = .right, isSupine: Bool = false) {
        self.side = side
        self.isSupine = isSupine
        self.romService = VisionROMService(side: side, isSupine: isSupine)
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureAndStart() } else { self?.permissionDenied = true }
                }
            }
        default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    func stop() {
        videoQueue.async { [weak self] in self?.session.stopRunning() }
        isRunning = false
        romResult = nil
    }

    func resetMax() { maxFlexion = 0 }

    private func configureAndStart() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { session.commitConfiguration(); return }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { session.commitConfiguration(); return }
        session.addOutput(output)
        session.commitConfiguration()

        videoQueue.async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { self?.isRunning = true }
        }
    }
}

extension CameraROMViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let result = romService.processFrame(pixelBuffer)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.romResult = result
            if let r = result, r.kneeFlexion > self.maxFlexion {
                self.maxFlexion = r.kneeFlexion
            }
        }
    }
}

// MARK: - CameraVisionROMView

struct CameraVisionROMView: View {
    @StateObject private var vm: CameraROMViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PatientProfile]

    @State private var showSaved = false
    @State private var savedFlexion: Double = 0

    init(side: OperatedSide) {
        _vm = StateObject(wrappedValue: CameraROMViewModel(side: side))
    }

    var podDay: Int { profiles.first?.podDay ?? 0 }

    var confidenceColor: Color {
        guard let c = vm.romResult?.confidence else { return .textTertiary }
        return c > 0.8 ? .success : c > 0.6 ? .warning : .danger
    }

    var podTarget: String {
        podDay < 43 ? "90°" : podDay < 85 ? "110°" : "120°"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: vm.session).ignoresSafeArea()
            JointOverlayView(result: vm.romResult).ignoresSafeArea()

            // 시뮬레이터 또는 카메라 미지원 기기 안내
            if !vm.isRunning && !vm.permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "camera.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text("카메라를 시작할 수 없어요")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("실제 아이폰에서 실행해주세요.\n시뮬레이터에서는 카메라가 지원되지 않아요.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(32)
            }

            VStack(spacing: 0) {
                topBar.padding(.top, 16).padding(.horizontal, 20)
                Spacer()
                bottomPanel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .alert("카메라 권한 필요", isPresented: $vm.permissionDenied) {
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) { dismiss() }
        } message: {
            Text("ROM 측정을 위해 카메라 접근을 허용해주세요.")
        }
    }

    // MARK: Top bar

    var topBar: some View {
        HStack(alignment: .center) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("카메라 ROM 측정")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text(vm.side.resolved == .right ? "우측 무릎" : "좌측 무릎")
                    .font(.caption2).foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            // 앙와위 토글
            Button {
                vm.isSupine.toggle()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: vm.isSupine ? "bed.double.fill" : "figure.stand")
                        .font(.system(size: 14))
                    Text(vm.isSupine ? "앙와위" : "직립")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(vm.isSupine ? .brand : .white.opacity(0.6))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(vm.isSupine ? Color.brand.opacity(0.2) : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Bottom panel

    var bottomPanel: some View {
        VStack(spacing: 12) {
            // Live angle
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(vm.romResult.map { String(format: "%.1f", $0.kneeFlexion) } ?? "--")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.brand)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.08), value: vm.romResult?.kneeFlexion)
                Text("°").font(.system(size: 26)).foregroundColor(.brand.opacity(0.7))

                Spacer()

                if let conf = vm.romResult?.confidence {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f%%", conf * 100))
                            .font(.system(size: 16, weight: .bold)).foregroundColor(confidenceColor)
                        Text("신뢰도").font(.caption2).foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            // Stats row
            HStack(spacing: 10) {
                statChip(label: "최대", value: String(format: "%.1f°", vm.maxFlexion), color: .exMain)
                statChip(label: "POD 목표", value: podTarget, color: .success)
                statChip(label: "POD", value: "\(podDay)일", color: .textSecondary)
            }

            if showSaved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.success)
                    Text("저장됨 — \(String(format: "%.1f", savedFlexion))°")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.success)
                }
                .padding(10)
                .background(Color.success.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    vm.resetMax()
                    showSaved = false
                } label: {
                    Text("초기화")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 22).padding(.vertical, 15)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button { saveMax() } label: {
                    Text("최대값 저장")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.brand.opacity(0.45), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(vm.maxFlexion < 1)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    func statChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func saveMax() {
        let record = ROMData(
            kneeFlexion:         vm.maxFlexion,
            kneeExtension:       max(0, 180 - vm.maxFlexion),
            ankleDorsiflexion:   0,
            anklePlantarflexion: 0,
            podDay:              podDay
        )
        modelContext.insert(record)
        savedFlexion = vm.maxFlexion
        withAnimation { showSaved = true }
    }
}
