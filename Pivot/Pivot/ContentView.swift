import SwiftUI
import SwiftData
import Charts
import AVFoundation
import Combine

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
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var selectedTab: Int
    @Query private var profiles: [PatientProfile]
    @Query(sort: \PainRecord.date, order: .reverse) private var painRecords: [PainRecord]
    @State private var showPainCheck = false
    @State private var showExercise = false

    var profile: PatientProfile? { profiles.first }
    var lastPain: PainRecord? { painRecords.first }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HomeHeroSection(profile: profile)
                    HomeROMCard(selectedTab: $selectedTab).padding(.bottom, 24)
                    if let p = profile { FollowUpScheduleCard(profile: p).padding(.bottom, 24) }
                    HomeQuickMenu(showPainCheck: $showPainCheck, showExercise: $showExercise,
                                  selectedTab: $selectedTab, phase: profile?.phase ?? "중기 회복기")
                        .padding(.bottom, 24)
                    if let pain = lastPain { HomeRecentPainCard(record: pain).padding(.bottom, 24) }
                    HomeWeeklyChart()
                    Color.clear.frame(height: 100)
                }
            }
            .background(Color.appBg).navigationBarHidden(true)
        }
        .sheet(isPresented: $showPainCheck) { PainCheckView().presentationDetents([.large]) }
        .sheet(isPresented: $showExercise) { ExerciseRecommendView().presentationDetents([.large]) }
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
    let flexion: Double = 98
    let extension_: Double = -2
    let flexionGoal: Double = 120
    let extensionGoal: Double = -5
    var progress: Double { min(flexion / flexionGoal, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader
            statsRow
            progressBar
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
                Text("오늘의 측정").font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
            }
            Spacer()
            Text("측정하기").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.brand).clipShape(Capsule())
        }
    }

    var statsRow: some View {
        HStack(spacing: 0) {
            ROMStatView(value: flexion, label: "굴곡", sublabel: "목표 \(Int(flexionGoal))°", color: .brand)
            Divider().frame(height: 52).padding(.horizontal, 16)
            ROMStatView(value: extension_, label: "신전", sublabel: "목표 0°~-5°", color: .success)
            Divider().frame(height: 52).padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(flexionGoal))°")
                    .font(.system(size: 26, weight: .bold)).foregroundColor(.textPrimary)
                Text("+\(Int(flexionGoal - flexion))° 남음")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.success)
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
                    Capsule().fill(Color.brand).frame(width: geo.size.width * CGFloat(progress), height: 7)
                }
            }
            .frame(height: 7)
        }
    }

    var measureButton: some View {
        Button { selectedTab = 1 } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder").font(.title3)
                Text("카메라로 ROM 측정하기").font(.system(size: 16, weight: .bold))
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
    @Binding var showExercise: Bool
    @Binding var selectedTab: Int
    let phase: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "빠른 메뉴").padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickMenuCard(icon: "cross.case.fill", color: .warning, bgColor: .warningBg,
                              title: "통증 체크", subtitle: "오늘 증상 기록",
                              badge: "오늘 미완료", badgeColor: .warning, badgeBg: .warningBg) { showPainCheck = true }
                QuickMenuCard(icon: "figure.run", color: .exMain, bgColor: .exLight,
                              title: "운동 추천", subtitle: "\(phase) 맞춤",
                              badge: "3개 추천", badgeColor: .brand, badgeBg: .brandBg) { showExercise = true }
                QuickMenuCard(icon: "chart.line.uptrend.xyaxis", color: .success, bgColor: .successBg,
                              title: "내 기록", subtitle: "ROM 추이 보기",
                              badge: "7일 연속", badgeColor: .success, badgeBg: .successBg) { selectedTab = 2 }
                QuickMenuCard(icon: "calendar.badge.clock", color: .brand, bgColor: .brandBg,
                              title: "다음 진료", subtitle: "외래 일정 확인",
                              badge: "일정 보기", badgeColor: .brand, badgeBg: .brandBg) {}
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
    let data: [(String, Double)] = [
        ("월", 88), ("화", 90), ("수", 92), ("목", 91), ("금", 94), ("토", 96), ("일", 98)
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "이번 주 ROM 추이").padding(.horizontal, 20)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("무릎 굴곡 각도").font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                    Spacer()
                    Text("오늘 98° ↑10°").font(.system(size: 12, weight: .bold)).foregroundColor(.brand)
                }
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<data.count, id: \.self) { i in
                        WeeklyBarItem(day: data[i].0, value: data[i].1, isToday: data[i].0 == "일")
                    }
                }
                .frame(height: 90)
                HStack {
                    Text("시작 88°").font(.system(size: 11)).foregroundColor(.textSecondary)
                    Spacer()
                    Text("오늘 98°").font(.system(size: 11, weight: .bold)).foregroundColor(.brand)
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
    let day: String; let value: Double; let isToday: Bool
    var barHeight: CGFloat { CGFloat((value - 80.0) / 20.0 * 60.0) + 20.0 }
    var body: some View {
        VStack(spacing: 5) {
            if isToday {
                Text("\(Int(value))°").font(.system(size: 10, weight: .bold)).foregroundColor(.brand)
            } else {
                Color.clear.frame(height: 14)
            }
            RoundedRectangle(cornerRadius: 5)
                .fill(isToday ? Color.brand : Color.brand.opacity(0.25)).frame(height: barHeight)
            Text(day).font(.system(size: 11))
                .foregroundColor(isToday ? .brand : .textSecondary).fontWeight(isToday ? .bold : .regular)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - ROMCameraView
// 무릎 ROM(카메라) + 발목 ROM(수동 입력) 통합 (1, 2)

struct ROMCameraView: View {
    @State private var cameraAuthorized = false
    @State private var isMeasuring = false
    @State private var measuredFlexion: Double = 87.5
    @State private var measuredExtension: Double = -2.0
    @State private var showAnkleInput = false
    @State private var ankleDorsiflexion: Double = 15
    @State private var anklePlantarflexion: Double = 35

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "0D1117"), Color(hex: "1A1F2E")],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 0) {
                    angleOverlay.padding(.top, 16).padding(.horizontal, 20)
                    Spacer()
                    kneeGuide
                    Spacer()
                    bottomPanel.padding(.horizontal, 20).padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .onAppear { checkCameraStatus() }
            .sheet(isPresented: $showAnkleInput) {
                AnkleROMInputSheet(dorsiflexion: $ankleDorsiflexion, plantarflexion: $anklePlantarflexion)
                    .presentationDetents([.medium])
            }
        }
    }

    var angleOverlay: some View {
        HStack(spacing: 14) {
            AngleCard(label: "굴곡", value: isMeasuring ? measuredFlexion : 0, color: .brand)
            AngleCard(label: "신전", value: isMeasuring ? measuredExtension : 0, color: .success)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("굴곡 목표").font(.caption2).foregroundColor(.white.opacity(0.5))
                Text("120°").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("신전 목표 0°~-5°").font(.caption2).foregroundColor(.success.opacity(0.8))
            }
        }
        .padding(18).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var kneeGuide: some View {
        ZStack {
            Circle()
                .strokeBorder(isMeasuring ? Color.brand : Color.white.opacity(0.3),
                              style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isMeasuring)
            VStack(spacing: 10) {
                Image(systemName: isMeasuring ? "waveform.path.ecg" : "figure.stand")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(isMeasuring ? .brand : .white.opacity(0.7))
                Text(isMeasuring ? "측정 중..." : "무릎을 원 안에\n맞춰 주세요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isMeasuring ? .brand : .white.opacity(0.75))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
        }
    }

    var bottomPanel: some View {
        VStack(spacing: 10) {
            if !cameraAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill").foregroundColor(.white.opacity(0.6))
                    Text("설정에서 카메라 권한을 허용해 주세요")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 10).padding(.horizontal, 18)
                .background(.ultraThinMaterial).clipShape(Capsule())
            }
            HStack(spacing: 10) {
                Button { showAnkleInput = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down").font(.subheadline)
                        Text("발목 ROM").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    if !cameraAuthorized { requestCamera(); return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        isMeasuring.toggle()
                        if isMeasuring {
                            measuredFlexion = Double.random(in: 85...100)
                            measuredExtension = Double.random(in: -5 ... 0)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isMeasuring ? "stop.circle.fill" : "circle.fill").font(.title2)
                        Text(isMeasuring ? "측정 완료" : "측정 시작").font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(isMeasuring ? Color.danger : Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: (isMeasuring ? Color.danger : Color.brand).opacity(0.5), radius: 14, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func checkCameraStatus() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { cameraAuthorized = granted }
        }
    }
}

struct AngleCard: View {
    let label: String; let value: Double; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(String(format: "%.1f", value)).font(.system(size: 26, weight: .bold)).foregroundColor(color)
                    .contentTransition(.numericText())
                Text("°").font(.subheadline).foregroundColor(color.opacity(0.8))
            }
        }
    }
}

// MARK: - 발목 ROM 입력 시트 (1)

struct AnkleROMInputSheet: View {
    @Binding var dorsiflexion: Double
    @Binding var plantarflexion: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("발목 가동범위 (Ankle ROM)").font(.title3.bold()).foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 8)

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

                ankleGuide.padding(.horizontal, 20)

                Button {
                    dismiss()
                } label: {
                    Text("저장").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.brand).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain).padding(.horizontal, 20)
                Spacer()
            }
            .background(Color.appBg)
            .navigationBarHidden(true)
        }
    }

    var ankleGuide: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(.brand).font(.subheadline)
            Text("발목을 충분히 수축/이완되게, 너무 빠르거나 느리지 않은 속도로 측정해 주세요.")
                .font(.system(size: 13)).foregroundColor(.textSecondary).lineSpacing(4)
        }
        .padding(14).background(Color.brandBg).clipShape(RoundedRectangle(cornerRadius: 12))
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
    @Binding var redness: Bool; @Binding var swelling: Bool
    @Binding var canWalk: Bool; @Binding var fever: Bool
    var body: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "다음 증상이 있나요?", subtitle: "현재 상태를 모두 체크해 주세요")
                VStack(spacing: 0) {
                    SymptomToggleRow(systemName: "circle.fill", color: .danger, title: "발적", subtitle: "무릎이 붉어지거나 따뜻해요", isOn: $redness)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "drop.fill", color: .brand, title: "부종", subtitle: "무릎이 부었어요", isOn: $swelling)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "figure.walk", color: .success, title: "보행 가능", subtitle: "혼자 걸을 수 있어요", isOn: $canWalk)
                    Divider().padding(.leading, 54).padding(.vertical, 2)
                    SymptomToggleRow(systemName: "thermometer.medium", color: .warning, title: "발열", subtitle: "열이 나는 것 같아요", isOn: $fever)
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
    @State private var redness = false; @State private var swelling = false
    @State private var canWalk = true;  @State private var fever = false
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
    var isRedFlag: Bool { redness && swelling && fever }

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
                SymptomSectionCard(redness: $redness, swelling: $swelling, canWalk: $canWalk, fever: $fever)
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
                Text("의사 상담이 필요해요").font(.system(size: 16, weight: .bold)).foregroundColor(.danger)
                Text("발적, 부종, 발열이 동시에 나타나고 있어요.\n담당 의사에게 빨리 연락해 주세요.")
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
            redness: redness, swelling: swelling, canWalk: canWalk, fever: fever, podDay: podDay
        ))
        withAnimation(.spring(response: 0.4)) { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showSavedBanner = false } }
        selectedPainTypes = []; nrsScore = 0
        redness = false; swelling = false; canWalk = true; fever = false
    }
}

// MARK: - ExerciseRecommendView

struct ExerciseRecommendView: View {
    @State private var selectedPhase: ExerciseItem.PODPhase = .mid
    var filtered: [ExerciseItem] { ExerciseItem.mockData.filter { $0.phase == selectedPhase } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        phaseFilter
                        ForEach(filtered) { ExerciseCard(exercise: $0) }
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("운동 추천").navigationBarTitleDisplayMode(.large)
        }
    }

    var phaseFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseItem.PODPhase.allCases, id: \.rawValue) { phase in
                    ExercisePhaseButton(phase: phase, selectedPhase: $selectedPhase)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ExercisePhaseButton: View {
    let phase: ExerciseItem.PODPhase
    @Binding var selectedPhase: ExerciseItem.PODPhase
    var selected: Bool { selectedPhase == phase }
    var body: some View {
        Button { withAnimation(.spring(response: 0.3)) { selectedPhase = phase } } label: {
            Text(phase.rawValue).font(.system(size: 14, weight: .medium))
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
    @State private var expanded = false

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
                ContractionTimer(targetSec: exercise.targetContractionSec, targetSets: exercise.targetSets)
            } else {
                RepCounter(targetSets: exercise.targetSets)
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
                completedSets = min(completedSets + 1, targetSets)
                if completedSets < targetSets { elapsed = 0 }
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
                Button { count = min(targetSets, count + 1) } label: {
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
    enum TimeRange: String, CaseIterable { case week = "7일"; case month = "30일"; case all = "전체" }

    var romPoints: [ROMDataPoint] {
        (0..<14).map { i in
            ROMDataPoint(id: i,
                         date: Calendar.current.date(byAdding: .day, value: -13 + i, to: .now) ?? .now,
                         value: 65 + Double(i) * 2.2)
        }
    }
    var painPoints: [PainDataPoint] {
        (0..<7).map { i in
            PainDataPoint(id: i,
                          date: Calendar.current.date(byAdding: .day, value: -6 + i, to: .now) ?? .now,
                          nrs: max(1, 5 - i / 3))
        }
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
                              value: "89°", label: "최대 굴곡", sub: "목표 120°")
            RecordSummaryCard(icon: "cross.case.fill", color: .danger, bgColor: .dangerBg,
                              value: "3.2점", label: "평균 통증", sub: "지난 7일")
            RecordSummaryCard(icon: "checkmark.seal.fill", color: .success, bgColor: .successBg,
                              value: "12회", label: "측정 횟수", sub: "이번 달")
        }
    }

    var romChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "무릎 굴곡 변화", subtitle: "Knee Flexion 각도 (°)")
                ROMLineChart(points: romPoints)
            }
        }
    }

    var painChartCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "통증 점수 변화", subtitle: "NRS 통증 척도 (0–10)")
                PainBarChart(points: painPoints)
            }
        }
    }

    var recoveryPhaseCard: some View {
        PivotCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "회복 단계", subtitle: "임상 기준 (강동경희대병원)")
                HStack(alignment: .top, spacing: 0) {
                    PhaseStep(label: "초기\n2-6주", stepState: .done, color: .success)
                    Spacer()
                    Rectangle().fill(Color.success).frame(height: 3).padding(.top, 9)
                    Spacer()
                    PhaseStep(label: "중기\n6-12주", stepState: .current, color: .brand)
                    Spacer()
                    Rectangle().fill(Color.divider).frame(height: 3).padding(.top, 9)
                    Spacer()
                    PhaseStep(label: "후기/유지\n12주+", stepState: .upcoming, color: .exMain)
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
    var profile: PatientProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        profileCard
                        rehabInfoSection
                        legInfoSection
                        appInfoSection
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
                }
            }
            .navigationTitle("내 정보").navigationBarTitleDisplayMode(.large)
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
                    Text(profile?.patientCode ?? "이소민")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
                    HStack(spacing: 6) {
                        Circle().fill(Color.brand).frame(width: 6, height: 6)
                        Text("수술 후 \(profile?.podDay ?? 0)일 • \(profile?.phase ?? "중기 회복기")")
                            .font(.system(size: 13)).foregroundColor(.brand)
                    }
                }
                Spacer()
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
                        value: profile?.phase ?? "중기 회복기")
                Divider()
                InfoRow(icon: "hand.point.right.fill", color: .brand, title: "수술 측",
                        value: profile?.operatedSide ?? "우측")
                Divider()
                InfoRow(icon: "target", color: .warning, title: "굴곡 목표", value: "120° → 140°")
                Divider()
                InfoRow(icon: "arrow.left.and.right", color: .success, title: "신전 목표", value: "0° ~ -5°")
            }
        }
    }

    // 다리 길이 차이 + 깔창 (5)
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

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [PainRecord.self, ROMData.self, PatientProfile.self, ExerciseLog.self], inMemory: true)
}
