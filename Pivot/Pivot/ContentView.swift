import SwiftUI
import SwiftData
import Charts
import AVFoundation
import Combine
import CoreMotion

// MARK: - Color System

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

    static let brand         = Color(hex: "5B7CF6")
    static let brandBg       = Color(hex: "F0F2FF")
    static let brandDeep     = Color(hex: "4A6BE0")
    static let success       = Color(hex: "2ECC71")
    static let successBg     = Color(hex: "E8F9F0")
    static let warning       = Color(hex: "F59E0B")
    static let warningBg     = Color(hex: "FFF3E0")
    static let danger        = Color(hex: "E8697A")
    static let dangerBg      = Color(hex: "FDEEF0")
    static let appBg         = Color.white
    static let surfaceBg     = Color(hex: "F8F8FB")
    static let appCard       = Color.white
    static let textPrimary   = Color(hex: "1C1C1E")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary  = Color(hex: "C7C7CC")
    static let divider       = Color(hex: "F2F2F7")
    static let exMain        = Color(hex: "8B72CF")
    static let exLight       = Color(hex: "F0ECFA")
}

// MARK: - Toss-style Face Emoji

struct PainFaceView: View {
    let score: Int

    var faceColor: Color {
        if score <= 3 { return .success }
        if score <= 6 { return .warning }
        return .danger
    }
    var faceBg: Color {
        if score <= 3 { return Color(hex: "E8F9F0") }
        if score <= 6 { return Color(hex: "FFF3E0") }
        return Color(hex: "FDEEF0")
    }
    var mouthCurve: CGFloat {
        switch score {
        case 0...2: return 1.0
        case 3...4: return 0.4
        case 5...6: return 0.0
        case 7...8: return -0.5
        default:    return -1.0
        }
    }

    var body: some View {
        ZStack {
            Circle().fill(faceBg).frame(width: 64, height: 64)
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    if score >= 9 {
                        eyeWithTear; eyeWithTear
                    } else if score >= 7 {
                        xEye; xEye
                    } else {
                        normalEye; normalEye
                    }
                }
                MouthCurve(curve: mouthCurve)
                    .stroke(faceColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 22, height: 12)
            }
        }
        .frame(width: 64, height: 64)
    }

    var normalEye: some View { Circle().fill(faceColor).frame(width: 7, height: 7) }
    var xEye: some View { Text("×").font(.system(size: 11, weight: .black)).foregroundColor(faceColor) }
    var eyeWithTear: some View {
        VStack(spacing: 1) {
            Circle().fill(faceColor).frame(width: 7, height: 7)
            Capsule().fill(faceColor.opacity(0.5)).frame(width: 3, height: 6)
        }
    }
}

struct MouthCurve: Shape {
    let curve: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.midY - curve * 9))
        return p
    }
}

// MARK: - PivotIcon

struct PivotIcon: View {
    let systemName: String
    let color: Color
    let bgColor: Color
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(LinearGradient(colors: [bgColor, bgColor.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Shared Components

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 12, weight: .semibold))
            .foregroundColor(.textSecondary).kerning(0.5).textCase(.uppercase)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 17, weight: .bold)).foregroundColor(.textPrimary)
            Text(subtitle).font(.system(size: 14)).foregroundColor(.textSecondary)
        }
    }
}

struct PivotCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content().padding(20).background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
    }
}

struct SymptomToggleRow: View {
    let systemName: String; let color: Color; let title: String; let subtitle: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            PivotIcon(systemName: systemName, color: color, bgColor: color.opacity(0.12), size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .medium)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 13)).foregroundColor(.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).tint(color).labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct NRSDotRow: View {
    let score: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0...10, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(dotBg(i)).frame(width: 26, height: 26)
                    Text("\(i)").font(.system(size: 10, weight: .bold)).foregroundColor(dotFg(i))
                }
            }
        }
    }
    func dotBg(_ i: Int) -> Color {
        if i == score { return i <= 3 ? .success : i <= 6 ? .warning : .danger }
        if i < score  { return i <= 3 ? .successBg : .warningBg }
        return .divider
    }
    func dotFg(_ i: Int) -> Color {
        if i == score { return .white }
        if i < score  { return i <= 3 ? .success : .warning }
        return .textTertiary
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    @Query private var profiles: [PatientProfile]

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("홈", systemImage: selectedTab == 0 ? "house.fill" : "house") }.tag(0)
            ROMCameraView()
                .tabItem { Label("ROM", systemImage: "camera.viewfinder") }.tag(1)
            MyRecordsView()
                .tabItem { Label("기록", systemImage: "chart.line.uptrend.xyaxis") }.tag(2)
            ProfileView()
                .tabItem { Label("내 정보", systemImage: selectedTab == 3 ? "person.fill" : "person") }.tag(3)
        }
        .tint(.brand)
        .onAppear { if profiles.isEmpty { showOnboarding = true } }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0

    // Step 0: 수술 정보
    @State private var name = ""
    @State private var surgeryDate = Date()
    @State private var operatedSide = "우측"

    // Step 1: 신체 정보
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var legDiffText = ""
    @State private var useInsole = false

    // Step 2: 생활/임상 정보
    @State private var preSurgeryActivity = "집안일 수준"
    @State private var contralateralLegStatus = "괜찮아요"
    @State private var currentAid = "없음"

    let activityOptions = ["거의 누워·앉아", "집안일 수준", "동네 산책", "정기적 운동"]
    let contralateralOptions = ["괜찮아요", "가끔 불편함", "자주 아픔"]
    let aidOptions = ["없음", "지팡이", "목발", "워커"]

    var canProceed: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    func save() {
        let profile = PatientProfile(
            patientCode: name.trimmingCharacters(in: .whitespaces).isEmpty ? "환자" : name,
            surgeryDate: surgeryDate,
            operatedSide: operatedSide,
            legLengthDifferenceMM: Double(legDiffText) ?? 0,
            useInsole: useInsole,
            age: Int(ageText) ?? 0,
            weightKg: Double(weightText) ?? 0,
            heightCm: Double(heightText) ?? 0,
            preSurgeryActivity: preSurgeryActivity,
            contralateralLegStatus: contralateralLegStatus,
            currentAid: currentAid
        )
        modelContext.insert(profile)
        dismiss()
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                TabView(selection: $step) {
                    step0View.tag(0)
                    step1View.tag(1)
                    step2View.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                bottomButton
            }
        }
        .interactiveDismissDisabled()
    }

    var progressBar: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= step ? Color.brand : Color.divider)
                        .frame(height: 4)
                        .animation(.spring(response: 0.4), value: step)
                }
            }
            .padding(.horizontal, 28)
            Text("Step \(step + 1) / 3").font(.system(size: 12)).foregroundColor(.textSecondary)
        }
        .padding(.top, 60).padding(.bottom, 8)
    }

    var bottomButton: some View {
        VStack(spacing: 12) {
            Button {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    save()
                }
            } label: {
                Text(step < 2 ? "다음" : "시작하기")
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(canProceed ? Color.brand : Color.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!canProceed)

            if step > 0 {
                Button { withAnimation { step -= 1 } } label: {
                    Text("이전").font(.system(size: 15)).foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 28).padding(.bottom, 40).padding(.top, 12)
    }

    // MARK: Step 0 - 수술 정보

    var step0View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                stepHeader(icon: "cross.case.fill", color: .brand,
                           title: "수술 정보를 입력해요",
                           subtitle: "회복 단계와 운동 프로그램을\n정확하게 맞춰드릴게요")

                VStack(alignment: .leading, spacing: 20) {
                    onboardingField(label: "이름") {
                        TextField("이름을 입력하세요", text: $name)
                            .font(.system(size: 16)).textInputAutocapitalization(.never)
                    }

                    onboardingField(label: "수술일") {
                        DatePicker("", selection: $surgeryDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                    }

                    onboardingField(label: "수술 측") {
                        HStack(spacing: 10) {
                            ForEach(["우측", "좌측", "양측"], id: \.self) { side in
                                Button {
                                    operatedSide = side
                                } label: {
                                    Text(side)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(operatedSide == side ? .white : .textSecondary)
                                        .padding(.horizontal, 24).padding(.vertical, 11)
                                        .background(operatedSide == side ? Color.brand : Color.surfaceBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 20)
        }
    }

    // MARK: Step 1 - 신체 정보

    var step1View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                stepHeader(icon: "figure.stand", color: .success,
                           title: "신체 정보를 입력해요",
                           subtitle: "BMI와 운동 강도 설정에\n활용돼요")

                VStack(alignment: .leading, spacing: 20) {
                    onboardingField(label: "나이") {
                        HStack {
                            TextField("0", text: $ageText).keyboardType(.numberPad)
                                .font(.system(size: 16))
                            Text("세").font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                    }

                    onboardingField(label: "키") {
                        HStack {
                            TextField("0", text: $heightText).keyboardType(.decimalPad)
                                .font(.system(size: 16))
                            Text("cm").font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                    }

                    onboardingField(label: "몸무게") {
                        HStack {
                            TextField("0", text: $weightText).keyboardType(.decimalPad)
                                .font(.system(size: 16))
                            Text("kg").font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                    }

                    onboardingField(label: "다리 길이 차이") {
                        HStack {
                            TextField("0", text: $legDiffText).keyboardType(.decimalPad)
                                .font(.system(size: 16))
                            Text("mm").font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                    }

                    onboardingField(label: "깔창 착용 여부") {
                        Toggle("", isOn: $useInsole).tint(.brand)
                    }
                }
            }
            .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 20)
        }
    }

    // MARK: Step 2 - 생활/임상 정보

    var step2View: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                stepHeader(icon: "heart.text.clipboard.fill", color: .warning,
                           title: "생활 정보를 입력해요",
                           subtitle: "운동 권고 수준과 안전 관리에\n사용돼요")

                VStack(alignment: .leading, spacing: 20) {
                    onboardingField(label: "수술 전 활동도") {
                        segmentedPicker(options: activityOptions, selected: $preSurgeryActivity)
                    }

                    onboardingField(label: "반대쪽 다리 상태") {
                        segmentedPicker(options: contralateralOptions, selected: $contralateralLegStatus)
                    }

                    onboardingField(label: "현재 보조기구") {
                        segmentedPicker(options: aidOptions, selected: $currentAid)
                    }

                }
            }
            .padding(.horizontal, 28).padding(.top, 8).padding(.bottom, 20)
        }
    }

    // MARK: Helpers

    @ViewBuilder
    func stepHeader(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 56, height: 56)
                Image(systemName: icon).font(.system(size: 24)).foregroundColor(color)
            }
            Text(title).font(.system(size: 24, weight: .bold)).foregroundColor(.textPrimary)
            Text(subtitle).font(.system(size: 15)).foregroundColor(.textSecondary).lineSpacing(4)
        }
    }

    @ViewBuilder
    func onboardingField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
            HStack {
                content()
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.surfaceBg).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    func segmentedPicker(options: [String], selected: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button { selected.wrappedValue = opt } label: {
                        Text(opt)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selected.wrappedValue == opt ? .white : .textSecondary)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(selected.wrappedValue == opt ? Color.brand : Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                selected.wrappedValue == opt ? Color.brand : Color.divider, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - SafetyGateBlockView

struct SafetyGateBlockView: View {
    enum SafetyBlockReason { case redFlag, acutePhase, muaRisk }

    let reason: SafetyBlockReason
    @Environment(\.dismiss) private var dismiss

    var icon: String {
        switch reason {
        case .redFlag:    return "exclamationmark.triangle.fill"
        case .acutePhase: return "bed.double.fill"
        case .muaRisk:    return "calendar.badge.exclamationmark"
        }
    }
    var iconColor: Color {
        switch reason {
        case .redFlag:    return .danger
        case .acutePhase: return .warning
        case .muaRisk:    return .brand
        }
    }
    var title: String {
        switch reason {
        case .redFlag:    return "운동을 중단하세요"
        case .acutePhase: return "아직 운동할 시기가 아니에요"
        case .muaRisk:    return "외래 방문이 필요해요"
        }
    }
    var body_text: String {
        switch reason {
        case .redFlag:
            return "현재 증상이 위험 신호에 해당해요.\n지금 바로 병원에 연락하세요.\n\n운동을 계속하면 회복에 방해가 될 수 있어요."
        case .acutePhase:
            return "수술 후 7일까지는 입원 치료 기간이에요.\n이 시기에는 앱 운동 프로그램을 사용하지 않아요.\n\n의료진 지시에 따라 안전하게 회복하세요."
        case .muaRisk:
            return "수술 후 6주가 지났지만 무릎 굴곡이 90° 미만이에요.\n관절 유착 예방을 위해 외래 방문이 필요해요.\n\n운동 전에 먼저 의료진과 상담하세요."
        }
    }
    var actionLabel: String {
        switch reason {
        case .redFlag:    return "병원 연락하기"
        case .acutePhase: return "확인했어요"
        case .muaRisk:    return "외래 예약 확인"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3).fill(Color.divider)
                .frame(width: 36, height: 5).padding(.top, 12).padding(.bottom, 24)

            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.12)).frame(width: 80, height: 80)
                    Image(systemName: icon).font(.system(size: 36)).foregroundColor(iconColor)
                }

                VStack(spacing: 10) {
                    Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(.textPrimary)
                    Text(body_text).font(.system(size: 15)).foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center).lineSpacing(5)
                }

                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text(actionLabel)
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(iconColor).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    if reason != .acutePhase {
                        Button { dismiss() } label: {
                            Text("닫기").font(.system(size: 15)).foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            Spacer()
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var selectedTab: Int
    @Query private var profiles: [PatientProfile]
    @Query(sort: \PainRecord.date, order: .reverse) private var painRecords: [PainRecord]
    @Query(sort: \ROMData.date, order: .reverse) private var romRecords: [ROMData]
    @State private var showPainCheck = false
    @State private var showExercise = false
    @State private var showSafetyBlock = false
    @State private var safetyBlockReason: SafetyGateBlockView.SafetyBlockReason = .redFlag

    var profile: PatientProfile? { profiles.first }
    var lastPain: PainRecord? { painRecords.first }

    var safetyCheck: SafetyGateBlockView.SafetyBlockReason? {
        guard let p = profile else { return nil }
        if p.podDay <= 14 { return .acutePhase }
        if let pain = lastPain, pain.isRedFlag { return .redFlag }
        if p.podDay >= 42, let lastROM = romRecords.first, lastROM.kneeFlexion < 90 { return .muaRisk }
        return nil
    }

    func onExerciseTap() {
        if let reason = safetyCheck {
            safetyBlockReason = reason
            showSafetyBlock = true
        } else {
            showExercise = true
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        HomeHeroSection(profile: profile)
                        HomeROMCard(selectedTab: $selectedTab).padding(.bottom, 24)
                        if let p = profile {
                            FollowUpScheduleCard(profile: p)
                                .id("followUp")
                                .padding(.bottom, 24)
                        }
                        HomeQuickMenu(
                            showPainCheck: $showPainCheck,
                            onExerciseTap: onExerciseTap,
                            selectedTab: $selectedTab,
                            phase: profile?.phase ?? "중기 회복기",
                            onFollowUpTap: { withAnimation { proxy.scrollTo("followUp", anchor: .top) } }
                        )
                        .padding(.bottom, 24)
                        if let p = profile {
                            GapAnalysisNudge(profile: p).padding(.bottom, 24)
                        }
                        if let pain = lastPain { HomeRecentPainCard(record: pain).padding(.bottom, 24) }
                        HomeWeeklyChart()
                        Color.clear.frame(height: 100)
                    }
                }
                .background(Color.appBg).navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showPainCheck) { PainCheckView().presentationDetents([.large]) }
        .sheet(isPresented: $showExercise) { ExerciseRecommendView().presentationDetents([.large]) }
        .sheet(isPresented: $showSafetyBlock) {
            SafetyGateBlockView(reason: safetyBlockReason).presentationDetents([.medium])
        }
    }
}

// MARK: - Home: Hero

struct HomeHeroSection: View {
    let profile: PatientProfile?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("안녕하세요").font(.system(size: 14)).foregroundColor(.textSecondary)
            Text("\(profile?.patientCode ?? "이소민") 님,\n오늘도 함께 회복해요")
                .font(.system(size: 24, weight: .bold)).foregroundColor(.textPrimary).lineSpacing(4)
            podChip
        }
        .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 24)
    }

    var podChip: some View {
        let day = profile?.podDay ?? 56
        let phase = profile?.phase ?? "중기 회복기"
        return HStack(spacing: 7) {
            Circle().fill(Color.brand).frame(width: 7, height: 7)
            Text("수술 후 \(day)일째  •  \(phase)")
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.brand)
        }
        .padding(.horizontal, 14).padding(.vertical, 8).background(Color.brandBg).clipShape(Capsule())
    }
}

// MARK: - Home: ROM Card
// 신전 목표: 0° ~ -5°, 굴곡 목표: 초기 90° → 최종 120-140°

struct HomeROMCard: View {
    @Binding var selectedTab: Int
    @Query(sort: \ROMData.date, order: .reverse) private var romRecords: [ROMData]

    let flexionGoal: Double = 120

    var latest: ROMData? { romRecords.first }
    var flexion: Double { latest?.kneeFlexion ?? 0 }
    var extension_: Double { latest?.kneeExtension ?? 0 }
    var hasData: Bool { latest != nil }
    var progress: Double { hasData ? min(flexion / flexionGoal, 1.0) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader
            if hasData {
                statsRow
                progressBar
            } else {
                emptyState
            }
            measureButton
        }
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "EEF1FF"), Color(hex: "F5F0FF")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.brand.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("무릎 가동 범위 (ROM)").font(.system(size: 13)).foregroundColor(.textSecondary)
                Text(hasData ? "최근 측정 결과" : "오늘의 측정")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
            }
            Spacer()
            if let d = latest?.date {
                Text(d.formatted(.dateTime.month().day()))
                    .font(.system(size: 12)).foregroundColor(.textSecondary)
            } else {
                Text("측정하기").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.brand).clipShape(Capsule())
            }
        }
    }

    var statsRow: some View {
        HStack(spacing: 0) {
            ROMStatView(value: flexion, label: "굴곡", sublabel: "목표 \(Int(flexionGoal))°", color: .brand)
            Divider().frame(height: 52).padding(.horizontal, 16)
            ROMStatView(value: extension_, label: "신전", sublabel: "목표 0°~-5°", color: .success)
            Divider().frame(height: 52).padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 4) {
                let remaining = flexionGoal - flexion
                Text("\(Int(flexionGoal))°")
                    .font(.system(size: 26, weight: .bold)).foregroundColor(.textPrimary)
                Text(remaining > 0 ? "+\(Int(remaining))° 남음" : "목표 달성!")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(remaining > 0 ? .success : .brand)
                Text("굴곡 목표").font(.system(size: 12, weight: .semibold)).foregroundColor(.brand)
            }
        }
    }

    var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("목표까지").font(.system(size: 12)).foregroundColor(.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%").font(.system(size: 13, weight: .bold)).foregroundColor(.brand)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.brand.opacity(0.12)).frame(height: 7)
                    Capsule().fill(Color.brand)
                        .frame(width: geo.size.width * CGFloat(progress), height: 7)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 7)
        }
    }

    var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "ruler").foregroundColor(.brand).font(.subheadline)
            Text("아직 ROM 측정 기록이 없어요. 지금 측정해 보세요.")
                .font(.system(size: 13)).foregroundColor(.textSecondary).lineSpacing(3)
        }
        .padding(12).background(Color.brand.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var measureButton: some View {
        Button { selectedTab = 1 } label: {
            HStack(spacing: 8) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill").font(.title3)
                Text("센서로 ROM 측정하기").font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.brand.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct ROMStatView: View {
    let value: Double; let label: String; let sublabel: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", value)).font(.system(size: 26, weight: .bold)).foregroundColor(.textPrimary)
                Text("°").font(.system(size: 13)).foregroundColor(.textSecondary)
            }
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            Text(sublabel).font(.system(size: 10)).foregroundColor(.textTertiary)
        }
    }
}

// MARK: - Home: 외래 추적관찰 일정 (6)

struct FollowUpScheduleCard: View {
    let profile: PatientProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "외래 추적관찰 일정").padding(.horizontal, 20)
            VStack(alignment: .leading, spacing: 12) {
                if let next = profile.nextFollowUp { nextVisitBanner(next) }
                VStack(spacing: 0) {
                    ForEach(profile.followUpDates) { item in
                        FollowUpRow(week: item.week, date: item.date,
                                    isNext: profile.nextFollowUp?.week == item.week)
                        if item.week != 104 { Divider().padding(.leading, 16) }
                    }
                }
                .background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
        }
    }

    func nextVisitBanner(_ next: FollowUpEntry) -> some View {
        let days = Calendar.current.dateComponents([.day], from: .now, to: next.date).day ?? 0
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("다음 외래 방문").font(.system(size: 12)).foregroundColor(.brand)
                Text("\(next.week)주차 추적관찰")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                Text(next.date.formatted(.dateTime.year().month().day()))
                    .font(.system(size: 13)).foregroundColor(.textSecondary)
            }
            Spacer()
            Text(days <= 0 ? "오늘!" : "D-\(days)")
                .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.brand).clipShape(Capsule())
        }
        .padding(14).background(Color.brandBg).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct FollowUpRow: View {
    let week: Int; let date: Date; let isNext: Bool
    var isPast: Bool { date < .now }
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isPast ? Color.success : isNext ? Color.brand : Color.divider)
                .frame(width: 8, height: 8)
            Text("\(week)주차").font(.system(size: 14, weight: .semibold))
                .foregroundColor(isNext ? .brand : isPast ? .textSecondary : .textPrimary)
            Text(weekLabel(week)).font(.system(size: 12)).foregroundColor(.textTertiary)
            Spacer()
            Text(date.formatted(.dateTime.month().day()))
                .font(.system(size: 13)).foregroundColor(isPast ? .textSecondary : .textPrimary)
            if isPast {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.success).font(.caption)
            } else if isNext {
                Image(systemName: "chevron.right").foregroundColor(.brand).font(.caption2)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    func weekLabel(_ w: Int) -> String {
        switch w {
        case 4:   return "POD 4w"
        case 8:   return "POD 8w"
        case 12:  return "POD 12w"
        case 52:  return "POD 1년"
        case 104: return "POD 2년"
        default:  return ""
        }
    }
}

// MARK: - Home: Quick Menu

struct HomeQuickMenu: View {
    @Binding var showPainCheck: Bool
    let onExerciseTap: () -> Void
    @Binding var selectedTab: Int
    let phase: String
    let onFollowUpTap: () -> Void

    @Query(sort: \PainRecord.date, order: .reverse) private var painRecords: [PainRecord]
    @Query(sort: \ROMData.date, order: .reverse) private var romRecords: [ROMData]

    var todayHasPain: Bool {
        guard let latest = painRecords.first else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }

    var exerciseCount: Int {
        ExerciseItem.mockData.filter { $0.phase.rawValue == phase }.count
    }

    var recordStreakDays: Int {
        guard !romRecords.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        for _ in 0..<30 {
            let hasRecord = romRecords.contains { Calendar.current.isDate($0.date, inSameDayAs: checkDate) }
            if hasRecord { streak += 1 } else { break }
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "빠른 메뉴").padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickMenuCard(icon: "cross.case.fill", color: .warning, bgColor: .warningBg,
                              title: "통증 체크", subtitle: "오늘 증상 기록",
                              badge: todayHasPain ? "오늘 완료" : "오늘 미완료",
                              badgeColor: todayHasPain ? .success : .warning,
                              badgeBg: todayHasPain ? .successBg : .warningBg) { showPainCheck = true }
                QuickMenuCard(icon: "figure.run", color: .exMain, bgColor: .exLight,
                              title: "운동 추천", subtitle: "\(phase) 맞춤",
                              badge: "\(exerciseCount)개 추천", badgeColor: .brand, badgeBg: .brandBg) { onExerciseTap() }
                QuickMenuCard(icon: "chart.line.uptrend.xyaxis", color: .success, bgColor: .successBg,
                              title: "내 기록", subtitle: "ROM 추이 보기",
                              badge: recordStreakDays > 0 ? "\(recordStreakDays)일 연속" : "기록 없음",
                              badgeColor: recordStreakDays > 0 ? .success : .textSecondary,
                              badgeBg: recordStreakDays > 0 ? .successBg : Color.divider) { selectedTab = 2 }
                QuickMenuCard(icon: "calendar.badge.clock", color: .brand, bgColor: .brandBg,
                              title: "다음 진료", subtitle: "외래 일정 확인",
                              badge: "일정 보기", badgeColor: .brand, badgeBg: .brandBg) { onFollowUpTap() }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Home: Recent Pain Card

struct HomeRecentPainCard: View {
    let record: PainRecord
    var chips: [String] {
        var r = Array(record.painTypes.prefix(3))
        if !record.swelling { r.append("부종 없음") }
        if !record.redness  { r.append("발적 없음") }
        return r
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "최근 통증 기록").padding(.horizontal, 20)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("최근 통증 체크").font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                    Spacer()
                    Text(record.date.formatted(.dateTime.month().day().hour().minute()))
                        .font(.system(size: 12)).foregroundColor(.textSecondary)
                }
                NRSDotRow(score: record.nrsScore)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip).font(.system(size: 11, weight: .semibold)).foregroundColor(.textPrimary)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.divider).clipShape(Capsule())
                        }
                    }
                }
                if record.isRedFlag {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.danger)
                        Text("의사 상담이 필요한 증상이 있어요")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.danger)
                    }
                    .padding(12).background(Color.dangerBg).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18).background(Color(hex: "FFF8F0"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Home: Weekly Chart

struct HomeWeeklyChart: View {
    @Query(sort: \ROMData.date, order: .reverse) private var romRecords: [ROMData]

    private let cal = Calendar.current
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var weekData: [(label: String, value: Double, isToday: Bool)] {
        (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: -(6 - offset), to: .now) ?? .now
            let label = weekdayLabels[cal.component(.weekday, from: date) - 1]
            let best = romRecords
                .filter { cal.isDate($0.date, inSameDayAs: date) }
                .map { $0.kneeFlexion }.max() ?? 0
            return (label, best, offset == 6)
        }
    }

    var todayValue: Double { weekData.last?.value ?? 0 }
    var firstValue: Double { weekData.first(where: { $0.value > 0 })?.value ?? 0 }
    var hasAnyData: Bool { weekData.contains(where: { $0.value > 0 }) }

    var trendText: String {
        guard todayValue > 0, firstValue > 0 else { return "-" }
        let diff = todayValue - firstValue
        return diff >= 0 ? "오늘 \(Int(todayValue))° ↑\(Int(diff))°" : "오늘 \(Int(todayValue))° ↓\(Int(-diff))°"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "이번 주 ROM 추이").padding(.horizontal, 20)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("무릎 굴곡 각도").font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                    Spacer()
                    Text(trendText).font(.system(size: 12, weight: .bold)).foregroundColor(.brand)
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<weekData.count, id: \.self) { i in
                        WeeklyBarItem(day: weekData[i].label, value: weekData[i].value, isToday: weekData[i].isToday)
                    }
                }
                .frame(height: 90)
                if hasAnyData {
                    HStack {
                        Text(firstValue > 0 ? "7일 전 \(Int(firstValue))°" : "")
                            .font(.system(size: 11)).foregroundColor(.textSecondary)
                        Spacer()
                        Text(todayValue > 0 ? "오늘 \(Int(todayValue))°" : "오늘 기록 없음")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(todayValue > 0 ? .brand : .textTertiary)
                    }
                } else {
                    Text("이번 주 측정 기록이 없어요").font(.system(size: 12))
                        .foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(18).background(Color.surfaceBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
}

struct WeeklyBarItem: View {
    let day: String
    let value: Double   // 0 = 기록 없음
    let isToday: Bool

    var hasData: Bool { value > 0 }
    var barHeight: CGFloat {
        guard hasData else { return 4 }
        return max(8, CGFloat((value - 60.0) / 80.0 * 70.0) + 10.0)
    }

    var body: some View {
        VStack(spacing: 5) {
            if isToday && hasData {
                Text("\(Int(value))°").font(.system(size: 10, weight: .bold)).foregroundColor(.brand)
            } else {
                Color.clear.frame(height: 14)
            }
            RoundedRectangle(cornerRadius: 5)
                .fill(hasData ? (isToday ? Color.brand : Color.brand.opacity(0.3)) : Color.divider)
                .frame(height: barHeight)
            Text(day).font(.system(size: 11))
                .foregroundColor(isToday ? .brand : .textSecondary)
                .fontWeight(isToday ? .bold : .regular)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Box 2 Step 6: Gap Analysis Nudge

struct GapAnalysisNudge: View {
    let profile: PatientProfile

    var body: some View {
        let gap = profile.gapAnalysis
        if gap == "none" { EmptyView() } else {
            let isPositive = gap == "positive"
            let color: Color = isPositive ? .success : .warning
            let bgColor: Color = isPositive ? .successBg : .warningBg
            let icon = isPositive ? "figure.walk" : "figure.walk.motion"
            let message = isPositive
                ? "보조기 없이 잘 걷고 계세요. 체중부하가 예상보다 빠르게 진행 중이에요. (\(profile.wbLevel))"
                : "보조기 의존도가 높아요. 안전한 범위에서 보행 연습을 늘려보세요. (\(profile.wbLevel))"

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "보행 보조기 Gap 분석").padding(.horizontal, 20)
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                        Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
                    }
                    Text(message)
                        .font(.system(size: 13)).foregroundColor(.textPrimary)
                        .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                }
                .padding(16).background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Quick Menu Card

struct QuickMenuCard: View {
    let icon: String; let color: Color; let bgColor: Color
    let title: String; let subtitle: String
    let badge: String; let badgeColor: Color; let badgeBg: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                PivotIcon(systemName: icon, color: color, bgColor: bgColor, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                    Text(subtitle).font(.system(size: 12)).foregroundColor(.textSecondary)
                }
                Text(badge).font(.system(size: 11, weight: .bold)).foregroundColor(badgeColor)
                    .padding(.horizontal, 9).padding(.vertical, 4).background(badgeBg).clipShape(Capsule())
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.spring(response: 0.2)) { pressed = true } }
            .onEnded { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - ROM Motion Manager

final class ROMMotionManager: ObservableObject {
    private let cm = CMMotionManager()
    @Published var angle: Double = 0.0
    @Published var isStable: Bool = false

    private var history: [Double] = []
    var isAvailable: Bool { cm.isDeviceMotionAvailable }

    func start() {
        guard cm.isDeviceMotionAvailable else { return }
        cm.deviceMotionUpdateInterval = 1.0 / 30.0
        cm.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let g = data?.gravity else { return }
            // Angle of phone's long axis (Y) from downward direction
            // 0° = vertical (hanging down), 90° = horizontal, 180° = vertical (pointing up)
            let a = atan2(sqrt(g.x * g.x + g.z * g.z), g.y) * 180.0 / .pi
            self.angle = a
            self.history.append(a)
            if self.history.count > 20 { self.history.removeFirst() }
            if self.history.count >= 10 {
                let range = (self.history.max() ?? 0) - (self.history.min() ?? 0)
                self.isStable = range < 1.5
            }
        }
    }

    func stop() {
        cm.stopDeviceMotionUpdates()
        history.removeAll()
        isStable = false
    }
}

// MARK: - ROMCameraView (가속도계 기반 ROM 측정)

struct ROMCameraView: View {
    @StateObject private var motion = ROMMotionManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PatientProfile]

    @State private var step = 0          // 0=intro 1=reference 2=flexion 3=result
    @State private var referenceAngle: Double = 0
    @State private var flexionAngle: Double = 0
    @State private var showAnkleInput = false
    @State private var ankleDorsiflexion: Double = 15
    @State private var anklePlantarflexion: Double = 35
    @State private var kneeExtension: Double = 0
    @State private var showSaved = false

    var podDay: Int { profiles.first?.podDay ?? 0 }
    var kneeFlexion: Double { max(0, flexionAngle - referenceAngle) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "0D1117"), Color(hex: "1A1F2E")],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar.padding(.top, 16).padding(.horizontal, 20)
                    Spacer()
                    stepContent.padding(.horizontal, 28)
                    Spacer()
                    bottomBar.padding(.horizontal, 20).padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
            .sheet(isPresented: $showAnkleInput) {
                AnkleROMInputSheet(dorsiflexion: $ankleDorsiflexion, plantarflexion: $anklePlantarflexion,
                                   kneeExtension: $kneeExtension)
                    .presentationDetents([.large])
            }
        }
    }

    // MARK: Top bar

    var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ROM 측정").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                Text(stepSubtitle).font(.system(size: 13)).foregroundColor(.white.opacity(0.55))
            }
            Spacer()
            if step == 1 || step == 2 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("현재 각도").font(.caption2).foregroundColor(.white.opacity(0.45))
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text(String(format: "%.1f", motion.angle))
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.brand)
                            .contentTransition(.numericText()).animation(.easeOut(duration: 0.1), value: motion.angle)
                        Text("°").font(.subheadline).foregroundColor(.brand.opacity(0.8))
                    }
                }
            }
        }
    }

    var stepSubtitle: String {
        switch step {
        case 0: return "가속도계로 무릎 굴곡을 측정해요"
        case 1: return "Step 1 / 2 — 기준 각도 설정"
        case 2: return "Step 2 / 2 — 굴곡 측정"
        default: return "측정 완료"
        }
    }

    // MARK: Step content

    @ViewBuilder
    var stepContent: some View {
        switch step {
        case 0: introStep
        case 1: referenceStep
        case 2: flexionStep
        default: resultStep
        }
    }

    var introStep: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(Color.brand.opacity(0.12)).frame(width: 120, height: 120)
                Image(systemName: "iphone.homebutton.landscape")
                    .font(.system(size: 50)).foregroundColor(.brand)
            }
            VStack(spacing: 12) {
                Text("스마트폰으로\n무릎 ROM을 측정해요")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    .multilineTextAlignment(.center).lineSpacing(4)
                Text("가속도 센서를 이용해 정확한\n굴곡 각도를 측정할 수 있어요")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(num: "1", text: "의자에 앉아 발을 바닥에 자연스럽게 내려놓으세요")
                instructionRow(num: "2", text: "스마트폰 옆면(측면)을 정강이 앞에 세로로 밀착하세요")
                instructionRow(num: "3", text: "화면이 앞을 향하도록 잡고 흔들리지 않게 고정하세요")
            }
            .padding(18).background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))

            if !motion.isAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.warning)
                    Text("이 기기에서 동작 센서를 사용할 수 없어요").font(.system(size: 13)).foregroundColor(.warning)
                }
            }
        }
    }

    var referenceStep: some View {
        VStack(spacing: 28) {
            arcDisplay(angle: motion.angle, color: .success, label: "기준 각도")
            VStack(spacing: 8) {
                Text("다리를 자연스럽게 내리세요")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("발을 바닥에 놓고 정강이를\n최대한 수직으로 유지해 주세요")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            stabilityBadge
        }
    }

    var flexionStep: some View {
        VStack(spacing: 28) {
            arcDisplay(angle: max(0, motion.angle - referenceAngle), color: .brand, label: "굴곡 각도")
            VStack(spacing: 8) {
                Text("무릎을 최대한 구부리세요")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("통증 없는 범위에서 구부린 뒤\n그 자세를 유지해 주세요")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            stabilityBadge
        }
    }

    var resultStep: some View {
        VStack(spacing: 28) {
            arcDisplay(angle: kneeFlexion, color: kneeFlexion >= 90 ? .brand : .warning, label: "무릎 굴곡 ROM")
            romTargetRow
            if showSaved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.success)
                    Text("기록이 저장되었어요").font(.system(size: 14, weight: .semibold)).foregroundColor(.success)
                }
                .padding(12).background(Color.success.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: Bottom bar

    var bottomBar: some View {
        HStack(spacing: 10) {
            if step == 1 || step == 2 {
                Button { showAnkleInput = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down").font(.subheadline)
                        Text("발목 ROM").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 18).padding(.vertical, 15)
                    .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            Button { handleAction() } label: {
                Text(actionLabel)
                    .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(actionColor).clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: actionColor.opacity(0.5), radius: 14, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(step == 3 && showSaved == false ? false : false) // always enabled
        }
    }

    var actionLabel: String {
        switch step {
        case 0: return "시작하기"
        case 1: return "기준 각도 설정"
        case 2: return "측정 완료"
        default: return showSaved ? "다시 측정" : "기록 저장"
        }
    }

    var actionColor: Color {
        switch step {
        case 0: return .brand
        case 1: return .success
        case 2: return .brand
        default: return showSaved ? Color(hex: "555567") : .success
        }
    }

    func handleAction() {
        switch step {
        case 0:
            withAnimation(.easeInOut(duration: 0.3)) { step = 1 }
        case 1:
            referenceAngle = motion.angle
            withAnimation(.easeInOut(duration: 0.3)) { step = 2 }
        case 2:
            flexionAngle = motion.angle
            withAnimation(.easeInOut(duration: 0.3)) { step = 3 }
        default:
            if showSaved {
                showSaved = false
                withAnimation(.easeInOut(duration: 0.3)) { step = 1 }
            } else {
                saveROM()
            }
        }
    }

    func saveROM() {
        let record = ROMData(
            kneeFlexion: kneeFlexion,
            kneeExtension: kneeExtension,
            ankleDorsiflexion: ankleDorsiflexion,
            anklePlantarflexion: anklePlantarflexion,
            podDay: podDay
        )
        modelContext.insert(record)
        showSaved = true
    }

    // MARK: Subviews

    @ViewBuilder
    func arcDisplay(angle: Double, color: Color, label: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(color.opacity(0.12), lineWidth: 10).frame(width: 160, height: 160)
                Circle().trim(from: 0, to: min(angle / 140.0, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 160, height: 160)
                    .animation(.easeOut(duration: 0.15), value: angle)
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", max(0, angle)))
                        .font(.system(size: 44, weight: .bold)).foregroundColor(color)
                        .contentTransition(.numericText()).animation(.easeOut(duration: 0.1), value: angle)
                    Text("°").font(.system(size: 18)).foregroundColor(color.opacity(0.7))
                }
            }
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.55))
        }
    }

    @ViewBuilder
    func instructionRow(num: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.brand.opacity(0.3)).frame(width: 26, height: 26)
                Text(num).font(.system(size: 13, weight: .bold)).foregroundColor(.brand)
            }
            Text(text).font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
        }
    }

    var stabilityBadge: some View {
        HStack(spacing: 8) {
            Circle().fill(motion.isStable ? Color.success : Color.warning)
                .frame(width: 8, height: 8)
                .shadow(color: (motion.isStable ? Color.success : Color.warning).opacity(0.6), radius: 4)
            Text(motion.isStable ? "안정됨 — 버튼을 눌러주세요" : "기기를 고정해 주세요...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(motion.isStable ? .success : .warning)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(.ultraThinMaterial).clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: motion.isStable)
    }

    var romTargetRow: some View {
        HStack(spacing: 0) {
            Spacer()
            romTarget(label: "4주 목표", value: "90°", met: kneeFlexion >= 90, color: .success)
            Spacer()
            Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 44)
            Spacer()
            romTarget(label: "8주 목표", value: "120°", met: kneeFlexion >= 120, color: .brand)
            Spacer()
            Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 44)
            Spacer()
            romTarget(label: "최종 목표", value: "140°", met: kneeFlexion >= 140, color: .exMain)
            Spacer()
        }
        .padding(16).background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    func romTarget(label: String, value: String, met: Bool, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20)).foregroundColor(met ? color : .white.opacity(0.25))
            Text(value).font(.system(size: 16, weight: .bold))
                .foregroundColor(met ? color : .white.opacity(0.4))
            Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.45))
        }
    }
}

// MARK: - 발목 ROM 입력 시트 (1)

struct AnkleROMInputSheet: View {
    @Binding var dorsiflexion: Double
    @Binding var plantarflexion: Double
    @Binding var kneeExtension: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text("추가 ROM 입력").font(.title3.bold()).foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 8)

                    PivotCard {
                        VStack(spacing: 20) {
                            KneeExtensionSlider(value: $kneeExtension)
                        }
                    }
                    .padding(.horizontal, 20)

                    PivotCard {
                        VStack(spacing: 20) {
                            AnkleSlider(label: "배굴 (Dorsiflexion)",
                                        detail: "발등 방향으로 올리기",
                                        value: $dorsiflexion, range: 0...30, target: 20)
                            Divider()
                            AnkleSlider(label: "저굴 (Plantarflexion)",
                                        detail: "발바닥 방향으로 내리기",
                                        value: $plantarflexion, range: 0...60, target: 45)
                        }
                    }
                    .padding(.horizontal, 20)

                    inputGuide.padding(.horizontal, 20)

                    Button {
                        dismiss()
                    } label: {
                        Text("저장").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain).padding(.horizontal, 20)
                    Color.clear.frame(height: 20)
                }
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
        }
    }

    var inputGuide: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(.brand).font(.subheadline)
            Text("신전: 다리를 최대한 폈을 때 남은 굽힘 각도예요. 완전히 펴지면 0°, 굽힘이 남으면 양수 값이에요.")
                .font(.system(size: 13)).foregroundColor(.textSecondary).lineSpacing(4)
        }
        .padding(14).background(Color.brandBg).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct KneeExtensionSlider: View {
    @Binding var value: Double

    var color: Color { value <= 5 ? .success : value <= 15 ? .warning : .danger }
    var goalText: String { value <= 0 ? "완전 신전 달성!" : "목표 0°까지 \(Int(value))° 남음" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("신전 부족 (Extension Lag)").font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                    Text("다리를 완전히 폈을 때 남는 굽힘 각도").font(.system(size: 12)).foregroundColor(.textSecondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", value)).font(.system(size: 26, weight: .bold)).foregroundColor(color)
                    Text("°").font(.system(size: 13)).foregroundColor(.textSecondary)
                }
            }
            Slider(value: $value, in: 0...40, step: 1).tint(color)
            HStack {
                Text(goalText).font(.system(size: 11)).foregroundColor(color)
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(color.opacity(0.15)).frame(height: 4)
                        Capsule().fill(color)
                            .frame(width: min(geo.size.width * CGFloat(value / 40.0), geo.size.width), height: 4)
                    }
                }
                .frame(width: 80, height: 4)
            }
        }
    }
}

struct AnkleSlider: View {
    let label: String; let detail: String
    @Binding var value: Double
    let range: ClosedRange<Double>; let target: Double

    var color: Color { value >= target ? .success : value >= target * 0.7 ? .warning : .danger }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                    Text(detail).font(.system(size: 12)).foregroundColor(.textSecondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", value)).font(.system(size: 26, weight: .bold)).foregroundColor(color)
                    Text("°").font(.system(size: 13)).foregroundColor(.textSecondary)
                }
            }
            Slider(value: $value, in: range, step: 1).tint(color)
            HStack {
                Text("목표 \(Int(target))° 이상").font(.system(size: 11)).foregroundColor(.textSecondary)
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(color.opacity(0.15)).frame(height: 4)
                        Capsule().fill(color)
                            .frame(width: min(geo.size.width * CGFloat(value / (range.upperBound)), geo.size.width), height: 4)
                    }
                }
                .frame(width: 80, height: 4)
            }
        }
    }
}

// MARK: - PainCheck Sub-views

struct PainHeaderCard: View {
    let podDay: Int; let phase: String
    var body: some View {
        PivotCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(Date.now.formatted(.dateTime.month().day().weekday()))
                        .font(.subheadline).foregroundColor(.textSecondary)
                    Text("오늘의 통증 기록").font(.title3.bold()).foregroundColor(.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("수술 후").font(.caption).foregroundColor(.textSecondary)
                    Text("POD \(podDay)일").font(.title3.bold()).foregroundColor(.danger)
                    Text(phase).font(.caption.bold()).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.danger).clipShape(Capsule())
                }
            }
        }
    }
}

struct PainTypeButton: View {
    let label: String; let sfSymbol: String; let iconColor: Color
    @Binding var selectedPainTypes: Set<String>
    var selected: Bool { selectedPainTypes.contains(label) }

    var body: some View {
        Button { toggleSelection() } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(selected ? Color.white.opacity(0.25) : iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: sfSymbol).font(.system(size: 18, weight: .semibold))
                        .foregroundColor(selected ? .white : iconColor)
                }
                Text(label).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(selected ? .white : .textPrimary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(selected ? Color.danger : Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color.danger : Color.divider, lineWidth: 1.5))
            .shadow(color: selected ? Color.danger.opacity(0.25) : .black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain).scaleEffect(selected ? 0.97 : 1.0).animation(.spring(response: 0.3), value: selected)
    }

    func toggleSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if label == "없음" {
                selectedPainTypes = selected ? [] : ["없음"]
            } else {
                selectedPainTypes.remove("없음")
                if selected { selectedPainTypes.remove(label) } else { selectedPainTypes.insert(label) }
            }
        }
    }
}

struct NRSSliderSection: View {
    @Binding var nrsScore: Double

    var nrsColor: Color {
        let s = Int(nrsScore)
        if s <= 3 { return .success }
        if s <= 6 { return .warning }
        return .danger
    }
    var nrsLabel: String {
        let a = ["없음","매우 약함","약함","약함","보통","보통","심함","심함","매우 심함","극심함","극심함"]
        return a[min(Int(nrsScore), 10)]
    }

    var body: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "통증이 얼마나 심한가요?", subtitle: "0은 통증 없음, 10은 극심한 통증이에요")
                scoreDisplay
                sliderWithLabels
            }
        }
    }

    var scoreDisplay: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                PainFaceView(score: Int(nrsScore))
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(nrsScore))").font(.system(size: 42, weight: .bold)).foregroundColor(nrsColor)
                    Text("점").font(.title3.weight(.medium)).foregroundColor(nrsColor.opacity(0.7))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(nrsLabel).font(.system(size: 16, weight: .bold)).foregroundColor(nrsColor)
                Text("NRS 통증 척도").font(.caption).foregroundColor(.textSecondary)
            }
        }
    }

    var sliderWithLabels: some View {
        VStack(spacing: 6) {
            Slider(value: $nrsScore, in: 0...10, step: 1).tint(nrsColor)
            HStack {
                Text("없음").font(.system(size: 11)).foregroundColor(.textSecondary)
                Spacer()
                Text("약함").font(.system(size: 11)).foregroundColor(.textSecondary)
                Spacer()
                Text("보통").font(.system(size: 11)).foregroundColor(.textSecondary)
                Spacer()
                Text("심함").font(.system(size: 11)).foregroundColor(.textSecondary)
                Spacer()
                Text("극심").font(.system(size: 11)).foregroundColor(.textSecondary)
            }
        }
    }
}

struct SymptomSectionCard: View {
    @Binding var hasWoundDischarge: Bool
    @Binding var redness: Bool
    @Binding var swelling: Bool
    @Binding var canWalk: Bool
    @Binding var fever: Bool
    @Binding var hasFallInjury: Bool

    var body: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "다음 증상이 있나요?", subtitle: "현재 상태를 모두 체크해 주세요")
                VStack(spacing: 0) {
                    SymptomToggleRow(systemName: "cross.case.fill", color: .danger,
                                     title: "창상 분비물", subtitle: "절개 부위에서 진물이나 고름이 나와요",
                                     isOn: $hasWoundDischarge)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "circle.fill", color: .danger,
                                     title: "발적 + 움직임 어려움", subtitle: "수술 부위가 붉어지며 움직이기 어려워요",
                                     isOn: $redness)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "figure.fall", color: .warning,
                                     title: "낙상", subtitle: "최근 넘어져서 출혈이나 불편함이 있어요",
                                     isOn: $hasFallInjury)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "drop.fill", color: .brand,
                                     title: "부종", subtitle: "반대쪽과 비교해 눈에 띄게 붓거나 움직임이 불편해요",
                                     isOn: $swelling)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "figure.walk", color: .success,
                                     title: "보행 가능", subtitle: "혼자 걸을 수 있어요",
                                     isOn: $canWalk)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "thermometer.medium", color: .warning,
                                     title: "수술 부위 열감", subtitle: "무릎 주변에 화끈한 느낌이 나면 체크해 주세요",
                                     isOn: $fever)
                }
            }
        }
    }
}

// NRS 7+ 시 등장하는 통증 지속 확인 카드
struct PainPersistCard: View {
    @Binding var painPersists: Bool
    var body: some View {
        PivotCard {
            HStack(spacing: 14) {
                PivotIcon(systemName: "clock.badge.exclamationmark", color: .danger, bgColor: .dangerBg, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("통증 지속 여부 확인").font(.system(size: 15, weight: .semibold)).foregroundColor(.danger)
                    Text("30분 이상 쉬어도 통증이 가라앉지 않나요?")
                        .font(.system(size: 13)).foregroundColor(.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $painPersists).tint(.danger).labelsHidden()
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.danger.opacity(0.4), lineWidth: 1.5))
    }
}

struct STSCheckCard: View {
    @Binding var stsScore: Int

    private let options: [(Int, String, Color)] = [
        (1, "도움 없이 가능", .success),
        (2, "한 손 짚으면 가능", .brand),
        (3, "두 손 짚어야 가능", .warning),
        (4, "못 일어남", .danger)
    ]

    var body: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    PivotIcon(systemName: "figure.stand", color: .brand, bgColor: .brandBg, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("의자 일어나기 (STS)").font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                        Text("의자에서 일어날 때 어떻게 하시나요?")
                            .font(.system(size: 13)).foregroundColor(.textSecondary)
                    }
                    Spacer()
                }
                VStack(spacing: 8) {
                    ForEach(options, id: \.0) { value, label, color in
                        let selected = stsScore == value
                        Button { stsScore = value } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(selected ? color : Color.divider)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().fill(.white).frame(width: 6, height: 6).opacity(selected ? 1 : 0))
                                Text(label)
                                    .font(.system(size: 14, weight: selected ? .semibold : .regular))
                                    .foregroundColor(selected ? color : .textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(selected ? color.opacity(0.1) : Color.surfaceBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - PainCheckView

struct PainCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PatientProfile]
    @State private var selectedPainTypes: Set<String> = []
    @State private var nrsScore: Double = 0
    @State private var redness = false
    @State private var swelling = false
    @State private var canWalk = true
    @State private var fever = false
    @State private var hasWoundDischarge = false
    @State private var painPersists = false
    @State private var hasFallInjury = false
    @State private var stsScore = 1
    @State private var showSavedBanner = false

    let painOptions: [(String, String, Color)] = [
        ("찌릿함",   "bolt.fill",             Color(hex: "F59E0B")),
        ("저릿함",   "waveform",              Color(hex: "5B7CF6")),
        ("묵직함",   "scalemass.fill",        Color(hex: "8E8E93")),
        ("욱신거림", "heart.fill",             Color(hex: "E8697A")),
        ("없음",     "checkmark.circle.fill", Color(hex: "2ECC71"))
    ]

    var podDay: Int { profiles.first?.podDay ?? 42 }
    var phase: String { profiles.first?.phase ?? "중기 회복기" }

    // 가드레일: 하나라도 해당 시 운동 전면 차단
    var isRedFlag: Bool {
        hasWoundDischarge ||
        redness ||
        Int(nrsScore) >= 6 ||
        hasFallInjury
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBg.ignoresSafeArea()
                mainScroll
            }
            .navigationTitle("통증 체크").navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if showSavedBanner { savedBanner.transition(.move(edge: .top).combined(with: .opacity)).zIndex(100) }
            }
        }
    }

    var mainScroll: some View {
        ScrollView {
            VStack(spacing: 14) {
                PainHeaderCard(podDay: podDay, phase: phase)
                painTypeGrid
                NRSSliderSection(nrsScore: $nrsScore)
                SymptomSectionCard(hasWoundDischarge: $hasWoundDischarge, redness: $redness,
                                   swelling: $swelling, canWalk: $canWalk, fever: $fever,
                                   hasFallInjury: $hasFallInjury)
                STSCheckCard(stsScore: $stsScore)
                if isRedFlag { redFlagCard.transition(.scale.combined(with: .opacity)) }
                saveButton
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
            .animation(.spring(response: 0.4), value: isRedFlag)
        }
    }

    var painTypeGrid: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "어떤 통증이 느껴지나요?", subtitle: "해당하는 것을 모두 선택해 주세요")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(0..<painOptions.count, id: \.self) { i in
                        PainTypeButton(label: painOptions[i].0, sfSymbol: painOptions[i].1,
                                       iconColor: painOptions[i].2, selectedPainTypes: $selectedPainTypes)
                    }
                }
            }
        }
    }

    var redFlagCard: some View {
        HStack(alignment: .top, spacing: 14) {
            PivotIcon(systemName: "exclamationmark.triangle.fill", color: .danger, bgColor: .dangerBg, size: 40)
            VStack(alignment: .leading, spacing: 6) {
                Text("지금 바로 병원에 연락하세요").font(.system(size: 16, weight: .bold)).foregroundColor(.danger)
                Text("위험 신호가 감지됐어요. 운동을 중단하고\n담당 의사에게 빨리 연락하거나 외래에 내원해 주세요.")
                    .font(.subheadline).foregroundColor(.textSecondary).lineSpacing(4)
            }
        }
        .padding(20).background(Color.dangerBg).clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.danger.opacity(0.35), lineWidth: 1.5))
    }

    var saveButton: some View {
        Button { savePainRecord() } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").font(.title2)
                Text("오늘 기록 완료").font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(Color.danger).clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.danger.opacity(0.4), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    var savedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundColor(.white)
            Text("통증 기록이 저장됐어요!").font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 22).padding(.vertical, 13)
        .background(Color.success).clipShape(Capsule())
        .shadow(color: Color.success.opacity(0.4), radius: 14, x: 0, y: 5).padding(.top, 62)
    }

    func savePainRecord() {
        modelContext.insert(PainRecord(
            nrsScore: Int(nrsScore), painTypes: Array(selectedPainTypes),
            redness: redness, swelling: swelling, canWalk: canWalk, fever: fever, podDay: podDay,
            hasWoundDischarge: hasWoundDischarge, painPersists: painPersists,
            hasFallInjury: hasFallInjury, stsScore: stsScore
        ))
        withAnimation(.spring(response: 0.4)) { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showSavedBanner = false } }
        selectedPainTypes = []; nrsScore = 0
        redness = false; swelling = false; canWalk = true; fever = false
        hasWoundDischarge = false; painPersists = false; hasFallInjury = false; stsScore = 1
    }
}

// MARK: - ExerciseRecommendView

struct ExerciseRecommendView: View {
    @Query private var profiles: [PatientProfile]
    @State private var selectedPhase: ExerciseItem.PODPhase = .mid
    @State private var didSetInitialPhase = false

    var profile: PatientProfile? { profiles.first }

    var currentPODPhase: ExerciseItem.PODPhase {
        switch profile?.phase ?? "" {
        case "급성기", "초기 회복기": return .early
        case "중기 회복기":           return .mid
        case "후기/유지기":           return .late
        default:                      return .early
        }
    }

    var podDay: Int { profile?.podDay ?? 0 }

    var filtered: [ExerciseItem] { ExerciseItem.mockData.filter { $0.phase == selectedPhase } }

    var isCurrentPhase: Bool { selectedPhase == currentPODPhase }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        if let p = profile {
                            paceBanner(p)
                        }
                        phaseFilter
                        if !isCurrentPhase {
                            phaseNotice
                        }
                        ForEach(filtered) { item in
                            ExerciseCard(exercise: item, podDay: podDay,
                                         isCurrent: item.phase == currentPODPhase)
                        }
                        if filtered.isEmpty {
                            Text("이 단계의 운동이 없어요").font(.subheadline)
                                .foregroundColor(.textSecondary).padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("운동 추천").navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if !didSetInitialPhase {
                selectedPhase = currentPODPhase
                didSetInitialPhase = true
            }
        }
    }

    func paceBanner(_ p: PatientProfile) -> some View {
        let paceColor: Color = p.pace == "적극" ? .success : p.pace == "보수" ? .warning : .brand
        let paceBg: Color = p.pace == "적극" ? .successBg : p.pace == "보수" ? .warningBg : .brandBg
        let paceIcon = p.pace == "적극" ? "hare.fill" : p.pace == "보수" ? "tortoise.fill" : "figure.walk"
        let paceDesc = p.pace == "적극" ? "더 빠른 진도가 권장돼요" : p.pace == "보수" ? "천천히 안전하게 진행해요" : "권장 속도로 진행해요"
        return HStack(spacing: 10) {
            Image(systemName: paceIcon).foregroundColor(paceColor).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("운동 속도").font(.system(size: 12)).foregroundColor(.textSecondary)
                    Text(p.pace).font(.system(size: 13, weight: .bold)).foregroundColor(paceColor)
                }
                Text(paceDesc).font(.system(size: 11)).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(12).background(paceBg).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var phaseFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseItem.PODPhase.allCases, id: \.rawValue) { phase in
                    ExercisePhaseButton(phase: phase, selectedPhase: $selectedPhase,
                                        isCurrent: phase == currentPODPhase)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    var phaseNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill").foregroundColor(.brand).font(.subheadline)
            Text("현재 회복 단계(\(currentPODPhase.rawValue))가 아닌 운동을 보고 있어요.")
                .font(.system(size: 13)).foregroundColor(.textSecondary).lineSpacing(3)
        }
        .padding(12).background(Color.brandBg).clipShape(RoundedRectangle(cornerRadius: 12))
    }

}

struct ExercisePhaseButton: View {
    let phase: ExerciseItem.PODPhase
    @Binding var selectedPhase: ExerciseItem.PODPhase
    let isCurrent: Bool
    var selected: Bool { selectedPhase == phase }
    var body: some View {
        Button { withAnimation(.spring(response: 0.3)) { selectedPhase = phase } } label: {
            HStack(spacing: 5) {
                Text(phase.rawValue).font(.system(size: 14, weight: .medium))
                if isCurrent {
                    Text("현재").font(.system(size: 11, weight: .bold))
                        .foregroundColor(selected ? .white.opacity(0.85) : .exMain)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(selected ? Color.white.opacity(0.25) : Color.exLight)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(selected ? .white : .textSecondary)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(selected ? Color.exMain : Color.surfaceBg).clipShape(Capsule())
            .shadow(color: selected ? Color.exMain.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ExerciseCard (근수축 타이머 + 속도 가이드 포함) (3, 4)

struct ExerciseCard: View {
    let exercise: ExerciseItem
    let podDay: Int
    let isCurrent: Bool
    @State private var expanded = false
    @State private var didSaveLog = false
    @Environment(\.modelContext) private var modelContext

    func saveLog(completedSets: Int) {
        guard !didSaveLog else { return }
        didSaveLog = true
        let log = ExerciseLog(
            exerciseTitle: exercise.title,
            contractionSeconds: exercise.targetContractionSec,
            completedSets: completedSets,
            targetSets: exercise.targetSets,
            podDay: podDay
        )
        modelContext.insert(log)
    }

    var body: some View {
        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { expanded.toggle() } } label: {
            VStack(alignment: .leading, spacing: 0) {
                exerciseRow
                if expanded { expandedContent }
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            if isCurrent {
                Text("지금 추천").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.exMain).clipShape(Capsule())
                    .padding(.top, 14).padding(.trailing, 14)
            }
        }
    }

    var exerciseRow: some View {
        HStack(spacing: 14) {
            PivotIcon(systemName: exercise.sfSymbol, color: .exMain, bgColor: .exLight, size: 60)
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.title).font(.system(size: 17, weight: .bold)).foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    Label("\(exercise.durationMin)분", systemImage: "clock").font(.subheadline).foregroundColor(.textSecondary)
                    Text("·").foregroundColor(.textTertiary)
                    Text(exercise.phase.rawValue).font(.caption.bold()).foregroundColor(.exMain)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Color.exLight).clipShape(Capsule())
                }
            }
            Spacer()
            Image(systemName: expanded ? "chevron.up" : "play.circle.fill").font(.title2).foregroundColor(.exMain)
        }
    }

    var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.top, 14)
            Text(exercise.description).font(.subheadline).foregroundColor(.textSecondary).lineSpacing(5)

            // 속도 가이드 (4)
            SpeedGuideRow(speedGuide: exercise.speedGuide)

            // 근수축 타이머 (3)
            if exercise.targetContractionSec > 0 {
                ContractionTimer(targetSec: exercise.targetContractionSec, targetSets: exercise.targetSets,
                                 onComplete: { saveLog(completedSets: exercise.targetSets) })
            } else {
                RepCounter(targetSets: exercise.targetSets,
                           onComplete: { saveLog(completedSets: exercise.targetSets) })
            }
        }
    }
}

// MARK: - 속도 가이드 (4)

struct SpeedGuideRow: View {
    let speedGuide: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "speedometer").foregroundColor(.brand).font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text("속도 가이드").font(.system(size: 12, weight: .semibold)).foregroundColor(.brand)
                Text(speedGuide).font(.system(size: 14)).foregroundColor(.textPrimary)
            }
        }
        .padding(12).background(Color.brandBg).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 근수축 타이머 (3)

struct ContractionTimer: View {
    let targetSec: Int
    let targetSets: Int
    var onComplete: (() -> Void)? = nil
    @State private var elapsed = 0
    @State private var isRunning = false
    @State private var completedSets = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var progress: Double { min(Double(elapsed) / Double(targetSec), 1.0) }
    var isDone: Bool { completedSets >= targetSets }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("근수축 타이머").font(.system(size: 14, weight: .semibold)).foregroundColor(.exMain)
                Spacer()
                Text("\(completedSets) / \(targetSets) 세트")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(isDone ? .success : .textPrimary)
            }
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.exMain.opacity(0.15), lineWidth: 6).frame(width: 72, height: 72)
                    Circle().trim(from: 0, to: progress)
                        .stroke(Color.exMain, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90)).frame(width: 72, height: 72)
                    VStack(spacing: 0) {
                        Text(isRunning ? "\(min(elapsed, targetSec))" : "\(targetSec)")
                            .font(.system(size: 22, weight: .bold)).foregroundColor(.exMain)
                        Text("초").font(.system(size: 11)).foregroundColor(.textSecondary)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(timerStatusText).font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                    HStack(spacing: 8) {
                        Button { resetTimer() } label: {
                            Text("리셋").font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Color.surfaceBg).clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Button { toggleTimer() } label: {
                            Text(isRunning ? "일시정지" : isDone ? "완료!" : elapsed == 0 ? "시작" : "계속")
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(isDone ? Color.success : Color.exMain).clipShape(Capsule())
                        }
                        .buttonStyle(.plain).disabled(isDone)
                    }
                }
                Spacer()
            }
        }
        .padding(14).background(Color.exLight).clipShape(RoundedRectangle(cornerRadius: 14))
        .onReceive(timer) { _ in
            guard isRunning else { return }
            elapsed += 1
            if elapsed >= targetSec {
                isRunning = false
                let newCount = min(completedSets + 1, targetSets)
                completedSets = newCount
                if newCount < targetSets { elapsed = 0 }
                if newCount >= targetSets { onComplete?() }
            }
        }
    }

    var timerStatusText: String {
        if isDone { return "운동 완료!" }
        if isRunning { return "수축 유지 중..." }
        if elapsed == 0 { return "목표 \(targetSec)초 유지 × \(targetSets)세트" }
        return "일시정지"
    }

    func toggleTimer() {
        if elapsed >= targetSec { elapsed = 0 }
        isRunning.toggle()
    }
    func resetTimer() { isRunning = false; elapsed = 0; completedSets = 0 }
}

struct RepCounter: View {
    let targetSets: Int
    var onComplete: (() -> Void)? = nil
    @State private var count = 0
    var body: some View {
        HStack {
            Text("횟수 카운터").font(.system(size: 14, weight: .semibold)).foregroundColor(.exMain)
            Spacer()
            HStack(spacing: 16) {
                Button { count = max(0, count - 1) } label: {
                    Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(.textTertiary)
                }
                .buttonStyle(.plain)
                Text("\(count) / \(targetSets)").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
                Button {
                    let next = min(targetSets, count + 1)
                    count = next
                    if next >= targetSets { onComplete?() }
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.exMain)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12).background(Color.exLight).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Chart Data Models

struct ROMDataPoint: Identifiable {
    let id: Int; let date: Date; let value: Double
}
struct PainDataPoint: Identifiable {
    let id: Int; let date: Date; let nrs: Int
}

// MARK: - Chart Views

struct ROMLineChart: View {
    let points: [ROMDataPoint]
    var body: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("날짜", point.date), y: .value("굴곡", point.value))
                    .foregroundStyle(Color.brand.opacity(0.1))
                LineMark(x: .value("날짜", point.date), y: .value("굴곡", point.value))
                    .foregroundStyle(Color.brand).lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(x: .value("날짜", point.date), y: .value("굴곡", point.value))
                    .foregroundStyle(Color.brand).symbolSize(28)
            }
            RuleMark(y: .value("목표", 90)).foregroundStyle(Color.success.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .annotation(position: .trailing) {
                    Text("목표").font(.caption).foregroundColor(.success)
                }
        }
        .frame(height: 170)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisValueLabel(format: .dateTime.month().day()).font(.caption)
        }}
        .chartYAxis { AxisMarks { v in
            AxisValueLabel { Text("\(v.as(Int.self) ?? 0)°").font(.caption) }
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
        }}
    }
}

struct PainBarChart: View {
    let points: [PainDataPoint]
    var body: some View {
        Chart {
            ForEach(points) { point in
                BarMark(x: .value("날짜", point.date), y: .value("통증", point.nrs))
                    .foregroundStyle(barColor(point.nrs)).cornerRadius(6)
            }
        }
        .frame(height: 130).chartYScale(domain: 0...10)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) { _ in
            AxisValueLabel(format: .dateTime.month().day()).font(.caption)
        }}
        .chartYAxis { AxisMarks(values: [0, 5, 10]) { v in
            AxisValueLabel { Text("\(v.as(Int.self) ?? 0)").font(.caption) }
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
        }}
    }
    func barColor(_ nrs: Int) -> Color {
        if nrs <= 3 { return .success }
        if nrs <= 6 { return .warning }
        return .danger
    }
}

// MARK: - MyRecordsView

struct MyRecordsView: View {
    @State private var timeRange: TimeRange = .week
    @Query private var profiles: [PatientProfile]
    @Query(sort: \ROMData.date, order: .reverse) private var allROM: [ROMData]
    @Query(sort: \PainRecord.date, order: .reverse) private var allPain: [PainRecord]

    var profile: PatientProfile? { profiles.first }
    enum TimeRange: String, CaseIterable { case week = "7일"; case month = "30일"; case all = "전체" }

    var currentPhaseIndex: Int {
        switch profile?.phase ?? "" {
        case "급성기":      return 0
        case "초기 회복기": return 1
        case "중기 회복기": return 2
        case "후기/유지기": return 3
        default:            return 0
        }
    }

    var cutoff: Date {
        switch timeRange {
        case .week:  return Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        case .all:   return .distantPast
        }
    }

    var filteredROM: [ROMData]     { allROM.filter  { $0.date >= cutoff } }
    var filteredPain: [PainRecord] { allPain.filter { $0.date >= cutoff } }

    var maxFlexion: Double { filteredROM.map { $0.kneeFlexion }.max() ?? 0 }
    var avgNRS: Double {
        guard !filteredPain.isEmpty else { return 0 }
        return Double(filteredPain.map { $0.nrsScore }.reduce(0, +)) / Double(filteredPain.count)
    }

    var romPoints: [ROMDataPoint] {
        filteredROM.reversed().enumerated().map { i, r in ROMDataPoint(id: i, date: r.date, value: r.kneeFlexion) }
    }
    var painPoints: [PainDataPoint] {
        filteredPain.reversed().enumerated().map { i, p in PainDataPoint(id: i, date: p.date, nrs: p.nrsScore) }
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
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("기록").navigationBarTitleDisplayMode(.large)
        }
    }

    var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.rawValue) { range in
                TimeRangeButton(range: range, selectedRange: $timeRange)
            }
            Spacer()
        }
    }

    var summaryRow: some View {
        HStack(spacing: 10) {
            RecordSummaryCard(icon: "figure.walk.motion", color: .brand, bgColor: .brandBg,
                              value: maxFlexion > 0 ? "\(Int(maxFlexion))°" : "-",
                              label: "최대 굴곡", sub: "목표 120°")
            RecordSummaryCard(icon: "cross.case.fill", color: .danger, bgColor: .dangerBg,
                              value: filteredPain.isEmpty ? "-" : String(format: "%.1f점", avgNRS),
                              label: "평균 통증", sub: timeRange.rawValue + " 기준")
            RecordSummaryCard(icon: "checkmark.seal.fill", color: .success, bgColor: .successBg,
                              value: "\(filteredROM.count)회",
                              label: "ROM 측정", sub: timeRange.rawValue + " 기준")
        }
    }

    var romChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "무릎 굴곡 변화", subtitle: "Knee Flexion 각도 (°)")
                if romPoints.isEmpty {
                    chartEmptyState(message: "ROM 측정 기록이 없어요")
                } else {
                    ROMLineChart(points: romPoints)
                }
            }
        }
    }

    var painChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "통증 점수 변화", subtitle: "NRS 통증 척도 (0–10)")
                if painPoints.isEmpty {
                    chartEmptyState(message: "통증 체크 기록이 없어요")
                } else {
                    PainBarChart(points: painPoints)
                }
            }
        }
    }

    @ViewBuilder
    func chartEmptyState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32)).foregroundColor(.textTertiary)
            Text(message).font(.system(size: 14)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity).frame(height: 120)
    }

    var recoveryPhaseCard: some View {
        let phases: [(label: String, color: Color)] = [
            ("급성기\n0-2주", .danger),
            ("초기\n2-6주", .warning),
            ("중기\n6-12주", .brand),
            ("후기/유지기\n12주+", .exMain)
        ]
        let connectorColors: [Color] = [
            currentPhaseIndex > 0 ? .danger  : .divider,
            currentPhaseIndex > 1 ? .warning : .divider,
            currentPhaseIndex > 2 ? .brand   : .divider,
        ]
        return PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "회복 단계", subtitle: "마스터리스트 B-2 기준")
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<phases.count, id: \.self) { i in
                        let p = phases[i]
                        let state: PhaseStep.StepState = i < currentPhaseIndex ? .done
                                                       : i == currentPhaseIndex ? .current
                                                       : .upcoming
                        PhaseStep(label: p.label, stepState: state, color: p.color)
                        if i < phases.count - 1 {
                            Spacer()
                            Rectangle().fill(connectorColors[i]).frame(height: 3).padding(.top, 9)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct TimeRangeButton: View {
    let range: MyRecordsView.TimeRange
    @Binding var selectedRange: MyRecordsView.TimeRange
    var selected: Bool { selectedRange == range }
    var body: some View {
        Button { withAnimation(.spring(response: 0.3)) { selectedRange = range } } label: {
            Text(range.rawValue).font(.system(size: 15, weight: .medium))
                .foregroundColor(selected ? .white : .textSecondary)
                .padding(.horizontal, 18).padding(.vertical, 9)
                .background(selected ? Color.brand : Color.surfaceBg).clipShape(Capsule())
                .shadow(color: selected ? Color.brand.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct RecordSummaryCard: View {
    let icon: String; let color: Color; let bgColor: Color
    let value: String; let label: String; let sub: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PivotIcon(systemName: icon, color: color, bgColor: bgColor, size: 36)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary)
                Text(sub).font(.caption).foregroundColor(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(bgColor.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PhaseStep: View {
    enum StepState { case done, current, upcoming }
    let label: String; let stepState: StepState; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(stepState == .upcoming ? Color.divider : color.opacity(stepState == .done ? 0.5 : 1.0))
                    .frame(width: 20, height: 20)
                if stepState == .current { Circle().stroke(color, lineWidth: 3).frame(width: 28, height: 28) }
            }
            Text(label).font(.system(size: 11)).foregroundColor(stepState == .current ? color : .textSecondary)
                .multilineTextAlignment(.center).lineSpacing(3)
        }
    }
}

// MARK: - ProfileView (다리 길이 차이 + 깔창 포함) (5)

struct InfoRow: View {
    let icon: String; let color: Color; let title: String; let value: String
    var body: some View {
        HStack {
            PivotIcon(systemName: icon, color: color, bgColor: color.opacity(0.12), size: 36)
            Text(title).font(.system(size: 15)).foregroundColor(.textPrimary)
            Spacer()
            Text(value).font(.system(size: 15)).foregroundColor(.textSecondary)
        }
    }
}

struct ProfileView: View {
    @Query private var profiles: [PatientProfile]
    @State private var showEdit = false
    var profile: PatientProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        profileCard
                        bodyInfoSection
                        rehabInfoSection
                        legInfoSection
                        clinicalInfoSection
                        appInfoSection
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("내 정보").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("편집") { showEdit = true }
                        .font(.system(size: 15, weight: .medium)).foregroundColor(.brand)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let p = profile { EditProfileView(profile: p) }
        }
    }

    var profileCard: some View {
        PivotCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.brandBg).frame(width: 64, height: 64)
                    Image(systemName: "person.fill").font(.system(size: 28)).foregroundColor(.brand)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile?.patientCode ?? "-")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
                    HStack(spacing: 6) {
                        Circle().fill(Color.brand).frame(width: 6, height: 6)
                        Text("수술 후 \(profile?.podDay ?? 0)일 • \(profile?.phase ?? "-")")
                            .font(.system(size: 13)).foregroundColor(.brand)
                    }
                }
                Spacer()
            }
        }
    }

    var bodyInfoSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("신체 정보").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
                let age = profile?.age ?? 0
                InfoRow(icon: "person.text.rectangle", color: .brand, title: "나이",
                        value: age > 0 ? "\(age)세" : "-")
                Divider()
                let h = profile?.heightCm ?? 0
                let w = profile?.weightKg ?? 0
                InfoRow(icon: "ruler", color: .success, title: "키 / 몸무게",
                        value: h > 0 || w > 0 ? "\(Int(h))cm / \(Int(w))kg" : "-")
                Divider()
                let bmi = profile?.bmi ?? 0
                InfoRow(icon: "scalemass.fill", color: .warning, title: "BMI",
                        value: bmi > 0 ? String(format: "%.1f", bmi) : "-")
            }
        }
    }

    var rehabInfoSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("재활 정보").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
                InfoRow(icon: "calendar", color: .brand, title: "수술일",
                        value: profile?.surgeryDate.formatted(.dateTime.year().month().day()) ?? "-")
                Divider()
                InfoRow(icon: "figure.walk.motion", color: .success, title: "회복 단계",
                        value: profile?.phase ?? "-")
                Divider()
                InfoRow(icon: "hand.point.right.fill", color: .brand, title: "수술 측",
                        value: profile?.operatedSide ?? "-")
                Divider()
                InfoRow(icon: "target", color: .warning, title: "굴곡 목표", value: "120° → 140°")
                Divider()
                InfoRow(icon: "arrow.left.and.right", color: .success, title: "신전 목표", value: "0° ~ -5°")
            }
        }
    }

    var legInfoSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("하지 정보").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)

                HStack {
                    PivotIcon(systemName: "ruler.fill", color: .brand, bgColor: Color.brand.opacity(0.12), size: 36)
                    Text("다리 길이 차이").font(.system(size: 15)).foregroundColor(.textPrimary)
                    Spacer()
                    let diff = profile?.legLengthDifferenceMM ?? 0
                    Text(diff == 0 ? "차이 없음" : String(format: "%.1f mm", diff))
                        .font(.system(size: 15)).foregroundColor(diff == 0 ? .textSecondary : .warning)
                }
                Divider()

                HStack {
                    PivotIcon(systemName: "shoeprints.fill", color: .exMain, bgColor: Color.exMain.opacity(0.12), size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("깔창 착용").font(.system(size: 15)).foregroundColor(.textPrimary)
                        Text("다리 길이 차이 보정").font(.system(size: 12)).foregroundColor(.textSecondary)
                    }
                    Spacer()
                    let using = profile?.useInsole ?? false
                    Text(using ? "착용 중" : "미착용")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(using ? .success : .textSecondary)
                }

                if (profile?.legLengthDifferenceMM ?? 0) > 5 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(.warning)
                        Text("다리 길이 차이가 큰 경우 깔창 착용을 권장합니다.")
                            .font(.system(size: 12)).foregroundColor(.textSecondary)
                    }
                    .padding(10).background(Color.warningBg).clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    var clinicalInfoSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("생활/임상 정보").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
                InfoRow(icon: "flame.fill", color: .warning, title: "수술 전 활동도",
                        value: profile?.preSurgeryActivity ?? "-")
                Divider()
                InfoRow(icon: "figure.walk.diamond.fill", color: .brand, title: "반대쪽 다리",
                        value: profile?.contralateralLegStatus ?? "-")
                Divider()
                InfoRow(icon: "cane.and.walking.stick", color: .success, title: "현재 보조기구",
                        value: profile?.currentAid ?? "-")
            }
        }
    }

    var appInfoSection: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("앱 정보").font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
                InfoRow(icon: "info.circle", color: .brand, title: "버전", value: "1.0.0")
                Divider()
                InfoRow(icon: "shield.lefthalf.filled", color: .success, title: "개인정보 처리방침", value: "보기 →")
            }
        }
    }
}

// MARK: - EditProfileView

struct EditProfileView: View {
    @Bindable var profile: PatientProfile
    @Environment(\.dismiss) private var dismiss

    let activityOptions = ["거의 누워·앉아", "집안일 수준", "동네 산책", "정기적 운동"]
    let contralateralOptions = ["괜찮아요", "가끔 불편함", "자주 아픔"]
    let aidOptions = ["없음", "지팡이", "목발", "워커"]

    @State private var heightText = ""
    @State private var weightText = ""
    @State private var legDiffText = ""
    @State private var ageText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    editSection(title: "수술 정보") {
                        editField(label: "이름") {
                            TextField("이름", text: $profile.patientCode)
                                .font(.system(size: 15)).textInputAutocapitalization(.never)
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "수술일") {
                            DatePicker("", selection: $profile.surgeryDate, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                                .environment(\.locale, Locale(identifier: "ko_KR"))
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "수술 측") {
                            Picker("수술 측", selection: $profile.operatedSide) {
                                Text("우측").tag("우측")
                                Text("좌측").tag("좌측")
                                Text("양측").tag("양측")
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    editSection(title: "신체 정보") {
                        editField(label: "나이") {
                            HStack {
                                TextField("0", text: $ageText, onCommit: { profile.age = Int(ageText) ?? profile.age })
                                    .keyboardType(.numberPad).font(.system(size: 15))
                                Text("세").foregroundColor(.textSecondary).font(.system(size: 14))
                            }
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "키 (cm)") {
                            TextField("0", text: $heightText, onCommit: { profile.heightCm = Double(heightText) ?? profile.heightCm })
                                .keyboardType(.decimalPad).font(.system(size: 15))
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "몸무게 (kg)") {
                            TextField("0", text: $weightText, onCommit: { profile.weightKg = Double(weightText) ?? profile.weightKg })
                                .keyboardType(.decimalPad).font(.system(size: 15))
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "다리 길이 차이 (mm)") {
                            TextField("0", text: $legDiffText, onCommit: { profile.legLengthDifferenceMM = Double(legDiffText) ?? profile.legLengthDifferenceMM })
                                .keyboardType(.decimalPad).font(.system(size: 15))
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "깔창 착용") {
                            Toggle("", isOn: $profile.useInsole).tint(.brand)
                        }
                    }

                    editSection(title: "생활/임상 정보") {
                        editField(label: "수술 전 활동도") {
                            Picker("활동도", selection: $profile.preSurgeryActivity) {
                                ForEach(activityOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu).foregroundColor(.brand)
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "반대쪽 다리 상태") {
                            Picker("반대쪽 다리", selection: $profile.contralateralLegStatus) {
                                ForEach(contralateralOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu).foregroundColor(.brand)
                        }
                        Divider().padding(.horizontal, -4)
                        editField(label: "현재 보조기구") {
                            Picker("보조기구", selection: $profile.currentAid) {
                                ForEach(aidOptions, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu).foregroundColor(.brand)
                        }
                    }

                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 40)
            }
            .background(Color.appBg)
            .navigationTitle("정보 편집").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        profile.age = Int(ageText) ?? profile.age
                        profile.heightCm = Double(heightText) ?? profile.heightCm
                        profile.weightKg = Double(weightText) ?? profile.weightKg
                        profile.legLengthDifferenceMM = Double(legDiffText) ?? profile.legLengthDifferenceMM
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.brand)
                }
            }
        }
        .onAppear {
            ageText = profile.age > 0 ? "\(profile.age)" : ""
            heightText = profile.heightCm > 0 ? String(format: "%.0f", profile.heightCm) : ""
            weightText = profile.weightKg > 0 ? String(format: "%.1f", profile.weightKg) : ""
            legDiffText = profile.legLengthDifferenceMM > 0 ? String(format: "%.1f", profile.legLengthDifferenceMM) : ""
        }
    }

    @ViewBuilder
    func editSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
                .padding(.horizontal, 4).padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16).padding(.vertical, 4)
            .background(Color.appCard).clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    @ViewBuilder
    func editField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundColor(.textPrimary)
            Spacer()
            content()
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [PainRecord.self, ROMData.self, PatientProfile.self, ExerciseLog.self], inMemory: true)
}
