import Foundation
import SwiftData

// MARK: - PainRecord

@Model
final class PainRecord {
    var id: UUID
    var date: Date
    var nrsScore: Int
    var painTypes: [String]
    var redness: Bool
    var swelling: Bool
    var canWalk: Bool
    var fever: Bool
    var podDay: Int

    init(
        date: Date = .now,
        nrsScore: Int = 0,
        painTypes: [String] = [],
        redness: Bool = false,
        swelling: Bool = false,
        canWalk: Bool = true,
        fever: Bool = false,
        podDay: Int = 0
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
    }

    var isRedFlag: Bool { redness && swelling && fever }
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

    var podDay: Int {
        max(0, Calendar.current.dateComponents([.day], from: surgeryDate, to: .now).day ?? 0)
    }

    // 임상 기준 POD 단계 (강동경희대병원 프로토콜)
    // 급성기 0-2w: 병원 입원 → 앱 불필요
    // 초기 회복기 2-6w, 중기 회복기 6-12w, 후기/유지기 12w+
    var phase: String {
        switch podDay {
        case 0...14:  return "급성기"
        case 15...42: return "초기 회복기"
        case 43...84: return "중기 회복기"
        default:      return "후기/유지기"
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

    init(
        patientCode: String = "P001",
        surgeryDate: Date = Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now,
        operatedSide: String = "우측",
        legLengthDifferenceMM: Double = 0,
        useInsole: Bool = false
    ) {
        self.id = UUID()
        self.patientCode = patientCode
        self.surgeryDate = surgeryDate
        self.operatedSide = operatedSide
        self.legLengthDifferenceMM = legLengthDifferenceMM
        self.useInsole = useInsole
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
        case early = "초기 회복기"
        case mid   = "중기 회복기"
        case late  = "후기/유지기"
    }

    static let mockData: [ExerciseItem] = [
        ExerciseItem(
            title: "발목 펌프 운동",
            sfSymbol: "arrow.up.arrow.down",
            durationMin: 5, phase: .early,
            description: "누운 자세에서 발목을 위아래로 천천히 움직여요. 혈액순환에 도움이 돼요.",
            targetContractionSec: 0, targetSets: 20,
            speedGuide: "올리기 2초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "무릎 굴곡 스트레칭",
            sfSymbol: "figure.flexibility",
            durationMin: 10, phase: .early,
            description: "앉아서 천천히 무릎을 구부렸다 펴요. 통증 없는 범위에서만 해요.",
            targetContractionSec: 3, targetSets: 10,
            speedGuide: "구부리기 3초 → 유지 3초 → 펴기 3초"
        ),
        ExerciseItem(
            title: "쿼드 세팅 (근육 조이기)",
            sfSymbol: "bolt.fill",
            durationMin: 8, phase: .mid,
            description: "누워서 넙다리근육을 수축시켜요. 5초 유지 후 이완, 10회 반복해요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "수축 → 5초 유지 → 이완 2초"
        ),
        ExerciseItem(
            title: "직다리 들기 (SLR)",
            sfSymbol: "figure.strengthtraining.functional",
            durationMin: 10, phase: .mid,
            description: "무릎을 편 채로 다리를 45도까지 들어올려요. 근력 강화에 효과적이에요.",
            targetContractionSec: 5, targetSets: 10,
            speedGuide: "올리기 2초 → 유지 5초 → 내리기 2초"
        ),
        ExerciseItem(
            title: "미니 스쿼트",
            sfSymbol: "figure.squat",
            durationMin: 12, phase: .late,
            description: "벽에 기대어 30도 정도 무릎을 구부려요. 균형과 근력을 함께 키워요.",
            targetContractionSec: 5, targetSets: 15,
            speedGuide: "내려가기 3초 → 유지 5초 → 올라오기 3초"
        ),
        ExerciseItem(
            title: "계단 오르기 연습",
            sfSymbol: "figure.stair.stepper",
            durationMin: 15, phase: .late,
            description: "낮은 계단을 이용해 한 칸씩 올라요. 수술한 쪽 발을 먼저 올리세요.",
            targetContractionSec: 0, targetSets: 10,
            speedGuide: "한 칸씩, 천천히 안정적으로"
        ),
    ]
}
