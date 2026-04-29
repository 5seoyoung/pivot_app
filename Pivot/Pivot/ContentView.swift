import SwiftUI
import Charts
import AVFoundation

// MARK: - Design System

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    // Background
    static let appBg        = Color(hex: "F5F6FA")
    static let appCard      = Color.white

    // Text
    static let textPrimary   = Color(hex: "1C1C1E")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary  = Color(hex: "C7C7CC")

    // Separator
    static let divider = Color(hex: "F2F2F7")

    // Tab 1 — ROM (파란 계열)
    static let romMain  = Color(hex: "5B9BF5")
    static let romLight = Color(hex: "EBF3FF")

    // Tab 2 — Pain (로즈 계열)
    static let painMain  = Color(hex: "E8697A")
    static let painLight = Color(hex: "FDEEF0")

    // Tab 3 — Exercise (바이올렛 계열)
    static let exMain  = Color(hex: "8B72CF")
    static let exLight = Color(hex: "F0ECFA")

    // Tab 4 — Records (민트 계열)
    static let recMain  = Color(hex: "4CB88A")
    static let recLight = Color(hex: "E8F7F1")
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
        }
    }
}

struct PivotCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        content()
            .padding(20)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct SymptomToggleRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let activeColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(activeColor)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            ROMCameraView()
                .tabItem { Label("운동 가이드", systemImage: "camera.viewfinder") }
                .tag(0)

            PainCheckView()
                .tabItem { Label("통증 체크", systemImage: "heart.text.square.fill") }
                .tag(1)

            ExerciseRecommendView()
                .tabItem { Label("운동 추천", systemImage: "play.rectangle.fill") }
                .tag(2)

            MyRecordsView()
                .tabItem { Label("내 기록", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)
        }
        .tint(.romMain)
    }
}

// MARK: - ROMCameraView (Shell)

struct ROMCameraView: View {
    @State private var cameraAuthorized = false
    @State private var isMeasuring = false
    @State private var measuredFlexion: Double = 87.5
    @State private var measuredExtension: Double = -3.0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "0D1117"), Color(hex: "1A1F2E")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    angleOverlay
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    Spacer()
                    kneeGuide
                    Spacer()

                    bottomPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .onAppear { requestCamera() }
        }
    }

    var angleOverlay: some View {
        HStack(spacing: 12) {
            AngleCard(label: "굴곡", value: isMeasuring ? measuredFlexion : 0, color: .romMain)
            AngleCard(label: "신전", value: isMeasuring ? measuredExtension : 0, color: .recMain)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("오늘 목표")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                Text("90°")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var kneeGuide: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isMeasuring ? Color.romMain : Color.white.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isMeasuring)

            if isMeasuring {
                VStack(spacing: 8) {
                    Text("🦵")
                        .font(.system(size: 52))
                    Text("측정 중...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.romMain)
                }
            } else {
                VStack(spacing: 10) {
                    Text("🦵")
                        .font(.system(size: 52))
                    Text("무릎을 원 안에\n맞춰 주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
            }
        }
    }

    var bottomPanel: some View {
        VStack(spacing: 14) {
            if !cameraAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white.opacity(0.6))
                    Text("설정에서 카메라 권한을 허용해 주세요")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    isMeasuring.toggle()
                    if isMeasuring {
                        measuredFlexion = Double.random(in: 85...92)
                        measuredExtension = Double.random(in: -4 ... -2)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isMeasuring ? "stop.circle.fill" : "circle.fill")
                        .font(.title2)
                    Text(isMeasuring ? "측정 완료" : "📐 측정 시작")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isMeasuring ? Color.painMain : Color.romMain)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: (isMeasuring ? Color.painMain : Color.romMain).opacity(0.5),
                    radius: 14, x: 0, y: 5
                )
            }
            .buttonStyle(.plain)
        }
    }

    func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { cameraAuthorized = granted }
        }
    }
}

struct AngleCard: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
                Text("°")
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.8))
            }
        }
    }
}

// MARK: - PainCheckView ★★★

struct PainCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PainRecord.date, order: .reverse) private var records: [PainRecord]
    @Query private var profiles: [PatientProfile]

    @State private var selectedPainTypes: Set<String> = []
    @State private var nrsScore: Double = 0
    @State private var redness = false
    @State private var swelling = false
    @State private var canWalk = true
    @State private var fever = false
    @State private var showSavedBanner = false

    let painOptions: [(label: String, emoji: String)] = [
        ("찌릿함", "⚡️"), ("저릿함", "🌊"),
        ("묵직함", "🪨"), ("욱신거림", "🔥"),
        ("없음", "✅"),
    ]

    var podDay: Int { profiles.first?.podDay ?? 42 }
    var phase: String { profiles.first?.phase ?? "중기" }
    var isRedFlag: Bool { redness && swelling && fever }

    var nrsColor: Color {
        switch Int(nrsScore) {
        case 0...2: return .recMain
        case 3...5: return Color(hex: "F5A623")
        case 6...8: return .painMain
        default: return Color(hex: "C0392B")
        }
    }

    var nrsEmoji: String {
        ["😊","😊","🙂","🙂","😐","😐","😣","😣","😫","😭","😭"][Int(nrsScore)]
    }

    var nrsLabel: String {
        ["통증 없음","매우 약함","약함","약함","보통","보통","심함","심함","매우 심함","극심함","극심함"][Int(nrsScore)]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        headerCard
                        painTypeSection
                        nrsSection
                        symptomSection
                        if isRedFlag { redFlagCard.transition(.scale.combined(with: .opacity)) }
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                    .animation(.spring(response: 0.4), value: isRedFlag)
                }
            }
            .navigationTitle("💊 통증 체크")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if showSavedBanner {
                    savedBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
        }
    }

    // MARK: Header
    var headerCard: some View {
        PivotCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(Date.now.formatted(.dateTime.month().day().weekday()))
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Text("오늘의 통증 기록")
                        .font(.title3.bold())
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("수술 후")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("POD \(podDay)일")
                        .font(.title3.bold())
                        .foregroundColor(.painMain)
                    Text(phase)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.painMain)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: Pain Types
    var painTypeSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "어떤 통증이 느껴지나요?", subtitle: "해당하는 것을 모두 선택해 주세요")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(painOptions, id: \.label) { option in
                        let selected = selectedPainTypes.contains(option.label)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if option.label == "없음" {
                                    selectedPainTypes = selected ? [] : ["없음"]
                                } else {
                                    selectedPainTypes.remove("없음")
                                    if selected { selectedPainTypes.remove(option.label) }
                                    else { selectedPainTypes.insert(option.label) }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(option.emoji).font(.title3)
                                Text(option.label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(selected ? .white : .textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(selected ? Color.painMain : Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected ? Color.painMain : Color.divider, lineWidth: 1.5)
                            )
                            .shadow(
                                color: selected ? Color.painMain.opacity(0.25) : .black.opacity(0.03),
                                radius: 6, x: 0, y: 2
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(selected ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3), value: selected)
                    }
                }
            }
        }
    }

    // MARK: NRS Slider
    var nrsSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "통증이 얼마나 심한가요?", subtitle: "0은 통증 없음, 10은 극심한 통증이에요")

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nrsEmoji)
                            .font(.system(size: 44))
                            .contentTransition(.numericText())
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(Int(nrsScore))")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(nrsColor)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3), value: Int(nrsScore))
                            Text("점")
                                .font(.title3.weight(.medium))
                                .foregroundColor(nrsColor.opacity(0.7))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Text(nrsLabel)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(nrsColor)
                            .animation(.easeInOut, value: nrsLabel)
                        Text("NRS 통증 척도")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                VStack(spacing: 6) {
                    Slider(value: $nrsScore, in: 0...10, step: 1)
                        .tint(nrsColor)
                        .animation(.easeInOut(duration: 0.2), value: nrsColor)
                    HStack {
                        ForEach(["없음", "약함", "보통", "심함", "극심"], id: \.self) { label in
                            Text(label).font(.system(size: 11)).foregroundColor(.textSecondary)
                            if label != "극심" { Spacer() }
                        }
                    }
                }
            }
        }
    }

    // MARK: Symptoms
    var symptomSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "다음 증상이 있나요?", subtitle: "현재 상태를 모두 체크해 주세요")

                VStack(spacing: 0) {
                    SymptomToggleRow(emoji: "🔴", title: "발적", subtitle: "무릎이 붉어지거나 따뜻해요", isOn: $redness, activeColor: .painMain)
                    Divider().padding(.leading, 50).padding(.vertical, 2)
                    SymptomToggleRow(emoji: "💧", title: "부종", subtitle: "무릎이 부었어요", isOn: $swelling, activeColor: .romMain)
                    Divider().padding(.leading, 50).padding(.vertical, 2)
                    SymptomToggleRow(emoji: "🚶", title: "보행 가능", subtitle: "혼자 걸을 수 있어요", isOn: $canWalk, activeColor: .recMain)
                    Divider().padding(.leading, 50).padding(.vertical, 2)
                    SymptomToggleRow(emoji: "🌡️", title: "발열", subtitle: "열이 나는 것 같아요", isOn: $fever, activeColor: .painMain)
                }
            }
        }
    }

    // MARK: Red Flag
    var redFlagCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("⚠️").font(.title2)
            VStack(alignment: .leading, spacing: 6) {
                Text("의사 상담이 필요해요")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "C0392B"))
                Text("발적, 부종, 발열이 동시에 나타나고 있어요.\n담당 의사에게 빨리 연락해 주세요.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .background(Color(hex: "FFF0EE"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.painMain.opacity(0.4), lineWidth: 1.5))
    }

    // MARK: Save Button
    var saveButton: some View {
        Button { savePainRecord() } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").font(.title2)
                Text("오늘 기록 완료")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.painMain)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.painMain.opacity(0.4), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: Saved Banner
    var savedBanner: some View {
        HStack(spacing: 10) {
            Text("✅")
            Text("통증 기록이 저장됐어요!")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(Color.recMain)
        .clipShape(Capsule())
        .shadow(color: Color.recMain.opacity(0.4), radius: 14, x: 0, y: 5)
        .padding(.top, 62)
    }

    // MARK: Actions
    func savePainRecord() {
        let record = PainRecord(
            nrsScore: Int(nrsScore),
            painTypes: Array(selectedPainTypes),
            redness: redness, swelling: swelling,
            canWalk: canWalk, fever: fever,
            podDay: podDay
        )
        modelContext.insert(record)

        withAnimation(.spring(response: 0.4)) { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showSavedBanner = false }
        }

        selectedPainTypes = []
        nrsScore = 0
        redness = false; swelling = false; canWalk = true; fever = false
    }
}

// MARK: - ExerciseRecommendView

struct ExerciseRecommendView: View {
    @State private var selectedPhase: ExerciseItem.PODPhase = .mid

    var filtered: [ExerciseItem] {
        ExerciseItem.mockData.filter { $0.phase == selectedPhase }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        phaseFilter
                        ForEach(filtered) { exercise in
                            ExerciseCard(exercise: exercise)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("🎯 운동 추천")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var phaseFilter: some View {
        HStack(spacing: 8) {
            ForEach(ExerciseItem.PODPhase.allCases, id: \.rawValue) { phase in
                let selected = selectedPhase == phase
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedPhase = phase }
                } label: {
                    Text(phase.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selected ? .white : .textSecondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(selected ? Color.exMain : Color.appCard)
                        .clipShape(Capsule())
                        .shadow(
                            color: selected ? Color.exMain.opacity(0.3) : .black.opacity(0.04),
                            radius: 5, x: 0, y: 2
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

struct ExerciseCard: View {
    let exercise: ExerciseItem
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    Text(exercise.emoji)
                        .font(.system(size: 34))
                        .frame(width: 62, height: 62)
                        .background(Color.exLight)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        HStack(spacing: 6) {
                            Label("\(exercise.durationMin)분", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Text("·").foregroundColor(.textTertiary)
                            Text(exercise.phase.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(.exMain)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.exLight)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.exMain)
                        .animation(.easeInOut(duration: 0.2), value: expanded)
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 14) {
                        Divider().padding(.top, 14)
                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineSpacing(5)
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("운동 시작")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Color.exMain)
                        .clipShape(Capsule())
                        .shadow(color: Color.exMain.opacity(0.35), radius: 8, x: 0, y: 3)
                    }
                }
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

// MARK: - MyRecordsView

struct MyRecordsView: View {
    @Query(sort: \ROMData.date) private var romRecords: [ROMData]
    @Query(sort: \PainRecord.date) private var painRecords: [PainRecord]
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable { case week = "7일"; case month = "30일"; case all = "전체" }

    let mockROM: [(date: Date, flexion: Double)] = (0..<14).map { i in
        let d = Calendar.current.date(byAdding: .day, value: -13 + i, to: .now)!
        return (d, 65 + Double(i) * 2.2 + Double.random(in: -2...2))
    }

    let mockPain: [(date: Date, nrs: Int)] = (0..<7).map { i in
        let d = Calendar.current.date(byAdding: .day, value: -6 + i, to: .now)!
        return (d, max(1, Int.random(in: 2...6) - i / 3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        timeRangePicker
                        summaryRow
                        romChartCard
                        painChartCard
                        recoveryPhaseCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("📊 내 기록")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.rawValue) { range in
                let selected = timeRange == range
                Button {
                    withAnimation(.spring(response: 0.3)) { timeRange = range }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selected ? .white : .textSecondary)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(selected ? Color.recMain : Color.appCard)
                        .clipShape(Capsule())
                        .shadow(color: selected ? Color.recMain.opacity(0.3) : .black.opacity(0.04), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    var summaryRow: some View {
        HStack(spacing: 10) {
            SummaryCard(emoji: "🦵", title: "최대 굴곡", value: "89°", subtitle: "목표 90°", color: .romMain)
            SummaryCard(emoji: "💊", title: "평균 통증", value: "3.2점", subtitle: "지난 7일", color: .painMain)
            SummaryCard(emoji: "📈", title: "측정 횟수", value: "12회", subtitle: "이번 달", color: .recMain)
        }
    }

    var romChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "무릎 굴곡 변화", subtitle: "Knee Flexion 각도 (°)")

                Chart {
                    ForEach(mockROM, id: \.date) { point in
                        AreaMark(x: .value("날짜", point.date), y: .value("굴곡", point.flexion))
                            .foregroundStyle(Color.romMain.opacity(0.12))
                        LineMark(x: .value("날짜", point.date), y: .value("굴곡", point.flexion))
                            .foregroundStyle(Color.romMain)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        PointMark(x: .value("날짜", point.date), y: .value("굴곡", point.flexion))
                            .foregroundStyle(Color.romMain)
                            .symbolSize(28)
                    }
                    RuleMark(y: .value("목표", 90))
                        .foregroundStyle(Color.recMain.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .annotation(position: .trailing) {
                            Text("목표").font(.caption).foregroundColor(.recMain)
                        }
                }
                .frame(height: 170)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month().day()).font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { v in
                        AxisValueLabel { Text("\(v.as(Int.self) ?? 0)°").font(.caption) }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    }
                }
            }
        }
    }

    var painChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "통증 점수 변화", subtitle: "NRS 통증 척도 (0–10)")

                Chart {
                    ForEach(mockPain, id: \.date) { point in
                        BarMark(x: .value("날짜", point.date), y: .value("통증", point.nrs))
                            .foregroundStyle(
                                point.nrs <= 3 ? Color.recMain :
                                point.nrs <= 6 ? Color(hex: "F5A623") : Color.painMain
                            )
                            .cornerRadius(6)
                    }
                }
                .frame(height: 130)
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month().day()).font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 5, 10]) { v in
                        AxisValueLabel { Text("\(v.as(Int.self) ?? 0)").font(.caption) }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    }
                }
            }
        }
    }

    var recoveryPhaseCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "회복 단계", subtitle: "현재 위치를 확인해 보세요")

                HStack(alignment: .top, spacing: 0) {
                    PhaseStep(label: "초기\n0-2주", state: .done, color: .recMain)
                    Spacer()
                    Rectangle().fill(Color.recMain).frame(height: 3).padding(.top, 9)
                    Spacer()
                    PhaseStep(label: "중기\n2-6주", state: .current, color: .romMain)
                    Spacer()
                    Rectangle().fill(Color.divider).frame(height: 3).padding(.top, 9)
                    Spacer()
                    PhaseStep(label: "후기\n6주+", state: .upcoming, color: .exMain)
                }
            }
        }
    }
}

struct SummaryCard: View {
    let emoji: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji).font(.title2)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PhaseStep: View {
    enum State { case done, current, upcoming }
    let label: String
    let state: State
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(state == .upcoming ? Color.divider : color.opacity(state == .done ? 0.5 : 1.0))
                    .frame(width: 20, height: 20)
                if state == .current {
                    Circle()
                        .stroke(color, lineWidth: 3)
                        .frame(width: 28, height: 28)
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(state == .current ? color : .textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [PainRecord.self, ROMData.self, PatientProfile.self], inMemory: true)
}
