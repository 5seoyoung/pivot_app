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
    var podDay: Int

    init(date: Date = .now, kneeFlexion: Double = 0, kneeExtension: Double = 0, podDay: Int = 0) {
        self.id = UUID()
        self.date = date
        self.kneeFlexion = kneeFlexion
        self.kneeExtension = kneeExtension
        self.podDay = podDay
    }
}

// MARK: - PatientProfile

@Model
final class PatientProfile {
    var id: UUID
    var patientCode: String
    var surgeryDate: Date

    var podDay: Int {
        max(0, Calendar.current.dateComponents([.day], from: surgeryDate, to: .now).day ?? 0)
    }

    var phase: String {
        switch podDay {
        case 0...14: return "초기"
        case 15...42: return "중기"
        default: return "후기"
        }
    }

    init(
        patientCode: String = "P001",
        surgeryDate: Date = Calendar.current.date(byAdding: .day, value: -42, to: .now) ?? .now
    ) {
        self.id = UUID()
        self.patientCode = patientCode
        self.surgeryDate = surgeryDate
    }
}

// MARK: - ExerciseItem (local mock data)

struct ExerciseItem: Identifiable {
    let id = UUID()
    let title: String
    let emoji: String
    let durationMin: Int
    let phase: PODPhase
    let description: String

    enum PODPhase: String, CaseIterable {
        case early = "초기"
        case mid = "중기"
        case late = "후기"
    }

    static let mockData: [ExerciseItem] = [
        ExerciseItem(title: "발목 펌프 운동", emoji: "🦶", durationMin: 5, phase: .early,
                     description: "누운 자세에서 발목을 위아래로 천천히 움직여요. 혈액순환에 도움이 돼요."),
        ExerciseItem(title: "무릎 굴곡 스트레칭", emoji: "🧘", durationMin: 10, phase: .early,
                     description: "앉아서 천천히 무릎을 구부렸다 펴요. 통증 없는 범위에서만 해요."),
        ExerciseItem(title: "쿼드 세팅 (근육 조이기)", emoji: "💪", durationMin: 8, phase: .mid,
                     description: "누워서 넙다리근육을 수축시켜요. 5초 유지 후 이완, 10회 반복해요."),
        ExerciseItem(title: "직다리 들기 (SLR)", emoji: "🏋️", durationMin: 10, phase: .mid,
                     description: "무릎을 편 채로 다리를 45도까지 들어올려요. 근력 강화에 효과적이에요."),
        ExerciseItem(title: "미니 스쿼트", emoji: "🏃", durationMin: 12, phase: .late,
                     description: "벽에 기대어 30도 정도 무릎을 구부려요. 균형과 근력을 함께 키워요."),
        ExerciseItem(title: "계단 오르기 연습", emoji: "🪜", durationMin: 15, phase: .late,
                     description: "낮은 계단을 이용해 한 칸씩 올라요. 수술한 쪽 발을 먼저 올리세요."),
    ]
}
