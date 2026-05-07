import Foundation
import SwiftData

// MARK: - PainRecord

@Model
final class PainRecord {
    var id: UUID
    var date: Date
    var nrsScore: Int
    var painTypes: [String]
    var redness: Bool         // 발적 + 움직이기 어려움 (combined)
    var swelling: Bool        // 부종 (정보 수집용)
    var canWalk: Bool         // 보행 가능 (정보 수집용)
    var fever: Bool           // 발열 (정보 수집용)
    var podDay: Int
    var hasWoundDischarge: Bool  // 창상 진물/고름
    var painPersists: Bool       // 통증 NRS 7+ → 30분 이상 지속
    var hasFallInjury: Bool      // 낙상 후 출혈/불편
    var stsCanStand: Bool        // STS: 의자에서 혼자 일어날 수 있는지 (Box 1 #10)

    init(
        date: Date = .now,
        nrsScore: Int = 0,
        painTypes: [String] = [],
        redness: Bool = false,
        swelling: Bool = false,
        canWalk: Bool = true,
        fever: Bool = false,
        podDay: Int = 0,
        hasWoundDischarge: Bool = false,
        painPersists: Bool = false,
        hasFallInjury: Bool = false,
        stsCanStand: Bool = true
    ) {
        self.id = UUID()
        self.date = date
        self.nrsScore = nrsScore
        self.painTypes = painTypes
        self.redness = redness
        self.swelling = swelling
        self.canWalk = canWalk
        self.fever = fever
        self.podDay = podDay
        self.hasWoundDischarge = hasWoundDischarge
        self.painPersists = painPersists
        self.hasFallInjury = hasFallInjury
        self.stsCanStand = stsCanStand
    }

    // 운동 전면 차단 조건 (가드레일) — 하나라도 해당 시 운동 중단 + 외래 권고
    var isRedFlag: Bool {
        hasWoundDischarge ||                        // 창상 진물/고름
        redness ||                                  // 발적 + 움직이기 어려움
        (nrsScore >= 7 && painPersists) ||          // NRS 7+ 통증 30분+ 지속
        hasFallInjury                               // 낙상 후 출혈/불편
    }
}

// MARK: - ROMData

@Model
final class ROMData {
    var id: UUID
    var date: Date
    var kneeFlexion: Double
    var kneeExtension: Double
    var ankleDorsiflexion: Double    // 발목 배굴 (목표 20°+)
    var anklePlantarflexion: Double  // 발목 저굴 (목표 45°+)
    var podDay: Int

    init(
        date: Date = .now,
        kneeFlexion: Double = 0,
        kneeExtension: Double = 0,
        ankleDorsiflexion: Double = 0,
        anklePlantarflexion: Double = 0,
        podDay: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.kneeFlexion = kneeFlexion
        self.kneeExtension = kneeExtension
        self.ankleDorsiflexion = ankleDorsiflexion
        self.anklePlantarflexion = anklePlantarflexion
        self.podDay = podDay
    }
}

// MARK: - PatientProfile

@Model
final class PatientProfile {
    var id: UUID
    var patientCode: String
    var surgeryDate: Date
    var operatedSide: String           // "우측" / "좌측"
    var legLengthDifferenceMM: Double  // 다리 길이 차이 (mm)
    var useInsole: Bool                // 깔창 착용 여부
    var age: Int                       // 나이
    var weightKg: Double               // 몸무게 (kg)
    var heightCm: Double               // 키 (cm)
    var preSurgeryActivity: String     // "비활동적" / "보통" / "활동적" / "매우 활동적"
    var contralateralLegStatus: String // "정상" / "이상 있음" / "수술 예정"
    var currentAid: String             // "없음" / "지팡이" / "목발" / "워커"
    var fallHistoryCount: Int          // 낙상 이력 횟수
    var recoveryGoal: String           // Box 1 #8: "집안보행" / "동네외출" / "가벼운운동" / "적극여가"
    var hasBed: Bool                   // Box 1 #11: 침대 있음
    var hasHighToilet: Bool            // Box 1 #11: 높은 변기(좌변기) 있음
    var hasStairs: Bool                // Box 1 #11: 집에 계단 있음

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let h = heightCm / 100
        return weightKg / (h * h)
    }

    var podDay: Int {
        max(0, Calendar.current.dateComponents([.day], from: surgeryDate, to: .now).day ?? 0)
    }

    // 임상 기준 POD 단계 (Mass General Brigham 프로토콜)
    // 급성기 0-1w: 입원 중 → 앱 운동 차단
    // 조기 1-4w, 중기 4-8w, 후기 8-12w, 유지기 12w+
    var phase: String {
        switch podDay {
        case 0...7:   return "급성기"
        case 8...28:  return "조기 회복기"
        case 29...56: return "중기 회복기"
        case 57...84: return "후기 회복기"
        default:      return "유지기"
        }
    }

    // 외래 추적관찰 일정: 4w, 8w, 12w, 52w, 104w
    var followUpDates: [FollowUpEntry] {
        [4, 8, 12, 52, 104].compactMap { week in
            guard let d = Calendar.current.date(byAdding: .weekOfYear, value: week, to: surgeryDate)
            else { return nil }
            return FollowUpEntry(week: week, date: d)
        }
    }

    var nextFollowUp: FollowUpEntry? {
        followUpDates.first { $0.date > .now }
    }

    // Box 2 Step 4 – Pace (보수/표준/적극)
    var pace: String {
        var score = 0
        if age < 65 { score -= 1 } else if age >= 80 { score += 1 }
        if fallHistoryCount == 1 { score += 1 } else if fallHistoryCount >= 2 { score += 2 }
        switch preSurgeryActivity {
        case "비활동적": score += 1
        case "활동적", "매우 활동적": score -= 1
        default: break
        }
        if contralateralLegStatus != "정상" { score += 1 }
        if score <= -1 { return "적극" }
        if score <= 1  { return "표준" }
        return "보수"
    }

    // Box 2 Step 4 – Exercise endpoint (운동 카탈로그 상한선)
    var exerciseEndpoint: ExerciseItem.PODPhase {
        switch recoveryGoal {
        case "집안보행": return .mid
        case "동네외출": return .late
        default:        return .maintenance
        }
    }

    // Box 2 Step 5 – Lifestyle flags (거주환경 + 단계별 금기 자세)
    var lifestyleFlags: [String] {
        var flags: [String] = []
        if podDay <= 56 {
            flags.append("무릎 아래 쿠션·베개 금지 — 굴곡 구축 위험")
        }
        if !hasBed {
            flags.append("바닥 생활 시 일어날 때 한쪽 무릎 집중 체중 금지")
        }
        if !hasHighToilet {
            flags.append("낮은 변기 사용 시 과굴곡 주의 — 보조 기구 권장")
        }
        if hasStairs {
            if podDay < 57 {
                flags.append("계단 사용 삼가기 — 후기 회복기 이후부터 가능")
            } else {
                flags.append("계단 이용 시 난간 잡고 한 칸씩 천천히")
            }
        }
        return flags
    }

    // Box 2 Step 6 – Weight-bearing level & gap analysis
    var wbLevel: String {
        switch currentAid {
        case "워커":   return "NWB"
        case "목발":   return "PWB"
        case "지팡이": return "WBAT"
        default:      return "FWB"
        }
    }

    private var expectedWbLevel: String {
        if podDay <= 7  { return "NWB"  }
        if podDay <= 21 { return "PWB"  }
        if podDay <= 42 { return "WBAT" }
        return "FWB"
    }

    // "positive" = 예상보다 빠른 회복 (보조기 적게 사용)
    // "negative" = 예상보다 느린 회복 (보조기 과의존)
    // "none" = 프로토콜 부합
    var gapAnalysis: String {
        let order = ["NWB", "PWB", "WBAT", "FWB"]
        guard let actualIdx   = order.firstIndex(of: wbLevel),
              let expectedIdx = order.firstIndex(of: expectedWbLevel)
        else { return "none" }
        if actualIdx > expectedIdx { return "positive" }
        if actualIdx < expectedIdx { return "negative" }
        return "none"
    }

    init(
        patientCode: String = "P001",
        surgeryDate: Date = Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now,
        operatedSide: String = "우측",
        legLengthDifferenceMM: Double = 0,
        useInsole: Bool = false,
        age: Int = 0,
        weightKg: Double = 0,
        heightCm: Double = 0,
        preSurgeryActivity: String = "보통",
        contralateralLegStatus: String = "정상",
        currentAid: String = "없음",
        fallHistoryCount: Int = 0,
        recoveryGoal: String = "동네외출",
        hasBed: Bool = true,
        hasHighToilet: Bool = false,
        hasStairs: Bool = false
    ) {
        self.id = UUID()
        self.patientCode = patientCode
        self.surgeryDate = surgeryDate
        self.operatedSide = operatedSide
        self.legLengthDifferenceMM = legLengthDifferenceMM
        self.useInsole = useInsole
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.preSurgeryActivity = preSurgeryActivity
        self.contralateralLegStatus = contralateralLegStatus
        self.currentAid = currentAid
        self.fallHistoryCount = fallHistoryCount
        self.recoveryGoal = recoveryGoal
        self.hasBed = hasBed
        self.hasHighToilet = hasHighToilet
        self.hasStairs = hasStairs
    }
}

// MARK: - ExerciseLog

@Model
final class ExerciseLog {
    var id: UUID
    var date: Date
    var exerciseTitle: String
    var contractionSeconds: Int  // 수축 유지 시간 (초)
    var completedSets: Int
    var targetSets: Int
    var speedRating: String      // "적절" / "빠름" / "느림"
    var podDay: Int

    init(
        date: Date = .now,
        exerciseTitle: String = "",
        contractionSeconds: Int = 5,
        completedSets: Int = 0,
        targetSets: Int = 10,
        speedRating: String = "적절",
        podDay: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.exerciseTitle = exerciseTitle
        self.contractionSeconds = contractionSeconds
        self.completedSets = completedSets
        self.targetSets = targetSets
        self.speedRating = speedRating
        self.podDay = podDay
    }
}

// MARK: - FollowUpEntry

struct FollowUpEntry: Identifiable {
    let week: Int
    let date: Date
    var id: Int { week }
}

// MARK: - ExerciseItem

struct ExerciseItem: Identifiable {
    let id = UUID()
    let title: String
    let sfSymbol: String
    let durationMin: Int
    let phase: PODPhase
    let description: String
    let targetContractionSec: Int  // 수축 유지 목표 시간 (0 = 해당 없음)
    let targetSets: Int
    let speedGuide: String         // 운동 속도 가이드 문구

    enum PODPhase: String, CaseIterable {
        case early       = "조기 회복기"
        case mid         = "중기 회복기"
        case late        = "후기 회복기"
        case maintenance = "유지기"
    }

    // MARK: - 운동 카탈로그 (24개, 4단계)

    static let mockData: [ExerciseItem] = earlyExercises + midExercises + lateExercises + maintenanceExercises

    // 조기 회복기 (1–4주) — 부종 감소, ROM 회복, 기초 근력 활성화
    static let earlyExercises: [ExerciseItem] = [
        ExerciseItem(
            title: "발목 펌프 운동",
            sfSymbol: "arrow.up.arrow.down",
            durationMin: 5, phase: .early,
            description: "누운 자세에서 발목을 위아래로 천천히 움직여요. 혈액순환을 촉진하고 혈전 예방에 도움이 돼요.",
            targetContractionSec: 0, targetSets: 20,
            speedGuide: "올리기 2초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "발뒤꿈치 밀기 (Heel Slides)",
            sfSymbol: "figure.flexibility",
            durationMin: 8, phase: .early,
            description: "누운 자세에서 발뒤꿈치를 침대 위로 천천히 당겨 무릎을 구부려요. 통증 없는 범위까지만 해요.",
            targetContractionSec: 3, targetSets: 10,
            speedGuide: "당기기 3초 → 유지 3초 → 펴기 3초"
        ),
        ExerciseItem(
            title: "대퇴사두근 수축 (Quad Sets)",
            sfSymbol: "bolt.fill",
            durationMin: 8, phase: .early,
            description: "무릎 아래 수건을 넣고 무릎을 바닥 쪽으로 눌러 대퇴사두근을 수축시켜요. 수술 후 근육 위축 예방에 필수적이에요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "수축 → 5초 유지 → 천천히 이완"
        ),
        ExerciseItem(
            title: "발목 원 그리기",
            sfSymbol: "arrow.clockwise.circle",
            durationMin: 5, phase: .early,
            description: "누운 자세에서 발목을 천천히 원을 그리듯 돌려요. 관절 가동범위 유지와 부종 감소에 도움이 돼요.",
            targetContractionSec: 0, targetSets: 10,
            speedGuide: "시계 방향 10회 → 반시계 방향 10회"
        ),
        ExerciseItem(
            title: "엉덩이 수축 운동 (Gluteal Sets)",
            sfSymbol: "figure.walk",
            durationMin: 6, phase: .early,
            description: "누운 자세에서 엉덩이 근육을 조여요. 고관절 안정성과 자세 유지에 중요한 운동이에요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "수축 → 5초 유지 → 이완 2초"
        ),
        ExerciseItem(
            title: "무릎 굴곡 스트레칭",
            sfSymbol: "figure.mind.and.body",
            durationMin: 10, phase: .early,
            description: "의자에 앉아 수건을 이용해 무릎을 천천히 구부려요. 중력을 이용해 굴곡 각도를 늘려가요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "구부리기 3초 → 유지 5초 → 펴기 3초"
        ),
    ]

    // 중기 회복기 (4–8주) — 근력 강화, ROM 90° 달성, 체중 부하 운동 시작
    static let midExercises: [ExerciseItem] = [
        ExerciseItem(
            title: "직다리 들기 (SLR)",
            sfSymbol: "figure.strengthtraining.functional",
            durationMin: 10, phase: .mid,
            description: "무릎을 완전히 편 채로 다리를 45도까지 들어올려요. 대퇴사두근과 고관절 굴곡근을 강화해요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "올리기 2초 → 유지 5초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "앉아서 무릎 굴곡 늘리기",
            sfSymbol: "figure.seated.seatbelt",
            durationMin: 10, phase: .mid,
            description: "의자에 앉아 수술한 발을 반대쪽 발 위에 얹어 천천히 굴곡을 늘려요. 90° 목표를 향해 꾸준히 해요.",
            targetContractionSec: 10, targetSets: 5,
            speedGuide: "서서히 눌러 10초 유지 → 이완 5초"
        ),
        ExerciseItem(
            title: "발뒤꿈치 들기 (Calf Raises)",
            sfSymbol: "figure.stand",
            durationMin: 8, phase: .mid,
            description: "의자를 잡고 서서 발뒤꿈치를 들어올려요. 종아리 근력과 균형을 함께 키워요.",
            targetContractionSec: 3, targetSets: 15,
            speedGuide: "올리기 2초 → 유지 3초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "앉아서 무릎 신전 (Seated Knee Extension)",
            sfSymbol: "arrow.up.right.circle",
            durationMin: 8, phase: .mid,
            description: "의자에 앉아 무릎을 천천히 펴 다리를 수평으로 만들어요. 신전 가동범위 회복에 중요해요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "펴기 2초 → 유지 5초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "고관절 외전 (Hip Abduction)",
            sfSymbol: "arrow.left.and.right.circle",
            durationMin: 8, phase: .mid,
            description: "옆으로 누워 다리를 30~45도 들어올려요. 고관절 외전근을 강화해 보행 안정성을 높여요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "올리기 2초 → 유지 5초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "터미널 무릎 신전 (TKE)",
            sfSymbol: "bolt.horizontal.fill",
            durationMin: 8, phase: .mid,
            description: "벽이나 의자를 잡고 무릎을 마지막 10~15도 완전히 펴는 연습을 해요. 신전 구축 예방에 핵심적이에요.",
            targetContractionSec: 5, targetSets: 15,
            speedGuide: "천천히 펴기 → 5초 유지 → 이완"
        ),
        ExerciseItem(
            title: "쿼드 세팅 강화 (Quad Sets+)",
            sfSymbol: "bolt.fill",
            durationMin: 10, phase: .mid,
            description: "수건을 무릎 아래 깔고 무릎을 강하게 눌러 대퇴사두근을 최대로 수축해요. 조기보다 강도를 높여요.",
            targetContractionSec: 7, targetSets: 15,
            speedGuide: "강하게 수축 → 7초 유지 → 이완 3초"
        ),
    ]

    // 후기 회복기 (8–12주) — 기능적 근력, 균형, 계단/보행 훈련
    static let lateExercises: [ExerciseItem] = [
        ExerciseItem(
            title: "미니 스쿼트",
            sfSymbol: "figure.squat",
            durationMin: 12, phase: .late,
            description: "벽에 등을 대고 천천히 30도 내려가요. 대퇴사두근, 엉덩이, 종아리를 함께 강화해요.",
            targetContractionSec: 5, targetSets: 15,
            speedGuide: "내려가기 3초 → 유지 5초 → 올라오기 3초"
        ),
        ExerciseItem(
            title: "계단 오르기 연습",
            sfSymbol: "figure.stair.stepper",
            durationMin: 15, phase: .late,
            description: "낮은 계단 한 칸을 반복해서 올라요. 오를 때 수술한 쪽 발 먼저, 내려올 때 건강한 쪽 발 먼저예요.",
            targetContractionSec: 0, targetSets: 10,
            speedGuide: "한 칸씩, 난간 잡고 안정적으로"
        ),
        ExerciseItem(
            title: "벽 스쿼트 (Wall Squat)",
            sfSymbol: "figure.squat",
            durationMin: 12, phase: .late,
            description: "등을 벽에 붙이고 45~60도까지 내려가요. 미니 스쿼트보다 더 깊이 내려가 근력을 강화해요.",
            targetContractionSec: 10, targetSets: 10,
            speedGuide: "내려가기 3초 → 유지 10초 → 올라오기 3초"
        ),
        ExerciseItem(
            title: "한발 서기 균형 운동",
            sfSymbol: "figure.stand.line.dotted.figure.stand",
            durationMin: 10, phase: .late,
            description: "수술한 쪽 발로만 서서 균형을 유지해요. 처음엔 의자를 잡고, 익숙해지면 손을 떼요.",
            targetContractionSec: 10, targetSets: 10,
            speedGuide: "한발 서기 → 10초 유지 → 쉬기 5초"
        ),
        ExerciseItem(
            title: "스텝 업 (Step Up)",
            sfSymbol: "stairs",
            durationMin: 12, phase: .late,
            description: "낮은 발판 위로 수술한 쪽 발을 먼저 올리고 반대 발을 당겨요. 실제 계단 보행 능력을 키워요.",
            targetContractionSec: 0, targetSets: 15,
            speedGuide: "올리기 2초 → 내리기 2초, 리듬 있게"
        ),
        ExerciseItem(
            title: "발끝·발뒤꿈치 걷기",
            sfSymbol: "figure.walk.motion",
            durationMin: 10, phase: .late,
            description: "발끝으로 10걸음, 발뒤꿈치로 10걸음씩 교대로 걸어요. 종아리·전경골근 강화와 보행 패턴 교정에 도움이 돼요.",
            targetContractionSec: 0, targetSets: 5,
            speedGuide: "일정한 속도로 앞뒤 10걸음 반복"
        ),
    ]

    // 유지기 (12주+) — 일상·사회 복귀, 유산소, 고급 강화
    static let maintenanceExercises: [ExerciseItem] = [
        ExerciseItem(
            title: "고정 자전거 타기",
            sfSymbol: "bicycle",
            durationMin: 20, phase: .maintenance,
            description: "저항 없는 고정 자전거를 20분 이상 타요. 관절에 무리 없이 심폐 지구력과 ROM을 함께 키울 수 있어요.",
            targetContractionSec: 0, targetSets: 1,
            speedGuide: "편안한 속도 20분, 저항 최소로 시작"
        ),
        ExerciseItem(
            title: "걷기 훈련 (거리 늘리기)",
            sfSymbol: "figure.walk",
            durationMin: 30, phase: .maintenance,
            description: "매주 10~15분씩 걷기 시간을 늘려요. 평지에서 시작해 경사로로 점차 난이도를 높여요.",
            targetContractionSec: 0, targetSets: 1,
            speedGuide: "대화할 수 있는 속도, 절뚝거리면 즉시 중단"
        ),
        ExerciseItem(
            title: "런지 (수정형 Lunge)",
            sfSymbol: "figure.strengthtraining.functional",
            durationMin: 12, phase: .maintenance,
            description: "한 발을 앞으로 내딛어 앞무릎이 90도가 되도록 내려가요. 수술 부위 통증 없는 범위에서만 해요.",
            targetContractionSec: 3, targetSets: 10,
            speedGuide: "내려가기 3초 → 유지 3초 → 올라오기 2초"
        ),
        ExerciseItem(
            title: "스쿼트 심화 (Deep Squat 진행)",
            sfSymbol: "figure.squat",
            durationMin: 15, phase: .maintenance,
            description: "발을 어깨 너비로 벌리고 60~90도까지 앉아요. 무릎이 발끝을 넘지 않도록 주의해요.",
            targetContractionSec: 5, targetSets: 15,
            speedGuide: "내려가기 3초 → 유지 5초 → 올라오기 2초"
        ),
        ExerciseItem(
            title: "수중 보행 (Aquatic Walking)",
            sfSymbol: "figure.pool.swim",
            durationMin: 30, phase: .maintenance,
            description: "허리 깊이 물속에서 걸어요. 부력으로 관절 부담을 줄이면서 근력과 ROM을 동시에 키울 수 있어요.",
            targetContractionSec: 0, targetSets: 1,
            speedGuide: "15분 이상, 무릎을 높이 들어 걷기"
        ),
        ExerciseItem(
            title: "계단 오르내리기 강화",
            sfSymbol: "figure.stair.stepper",
            durationMin: 15, phase: .maintenance,
            description: "일반 계단을 여러 층 오르내려요. 속도를 높이거나 층수를 늘려 점진적으로 강도를 올려요.",
            targetContractionSec: 0, targetSets: 3,
            speedGuide: "안전한 속도로 2~3층, 난간 선택적으로 사용"
        ),
    ]
}
