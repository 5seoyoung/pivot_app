import Foundation
import Vision

// MARK: - Domain types

enum OperatedSide {
    case left
    case right
    case bilateral  // 양측 — 기본 우측으로 처리

    var resolved: OperatedSide { self == .bilateral ? .right : self }
}

extension String {
    /// PatientProfile.operatedSide ("우측" / "좌측" / "양측") → OperatedSide
    var asOperatedSide: OperatedSide {
        switch self {
        case "좌측": return .left
        case "양측": return .bilateral
        default:     return .right
        }
    }
}

// Protocol — Vision 프레임워크 → 향후 Core ML 모델로 교체 시 View 코드 변경 없음
protocol ROMServiceProtocol {
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> ROMResult?
}

struct ROMResult {
    let kneeFlexion: Double
    let kneeExtension: Double
    let confidence: Float
    // Normalized Vision coordinates (origin bottom-left, 0–1). nil when not detected.
    let hipPoint: CGPoint?
    let kneePoint: CGPoint?
    let anklePoint: CGPoint?
}

// MARK: - Apple Vision 구현 (데모)

final class VisionROMService: ROMServiceProtocol {
    let side: OperatedSide
    /// true = 앙와위(누운 자세) 촬영 → 90° 회전 보정 적용
    var isSupine: Bool

    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    init(side: OperatedSide = .right, isSupine: Bool = false) {
        self.side = side
        self.isSupine = isSupine
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer) -> ROMResult? {
        // 앙와위: 카메라가 환자 측면을 가로로 촬영 → Vision이 세워서 인식하도록 보정
        // Python: 좌측 CCW, 우측 CW 회전과 동일한 효과
        // .right = 이미지가 90° CW 캡처됨 → Vision이 CCW 정규화 (우측 수술)
        // .left  = 이미지가 90° CCW 캡처됨 → Vision이 CW 정규화 (좌측 수술)
        let orientation: CGImagePropertyOrientation
        if isSupine {
            orientation = side.resolved == .right ? .right : .left
        } else {
            orientation = .up
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([bodyPoseRequest])
        } catch {
            return nil
        }
        guard let observation = bodyPoseRequest.results?.first else { return nil }
        return calculateROM(from: observation)
    }

    private func calculateROM(from observation: VNHumanBodyPoseObservation) -> ROMResult? {
        let resolved = side.resolved
        let hipJoint:   VNHumanBodyPoseObservation.JointName = resolved == .right ? .rightHip   : .leftHip
        let kneeJoint:  VNHumanBodyPoseObservation.JointName = resolved == .right ? .rightKnee  : .leftKnee
        let ankleJoint: VNHumanBodyPoseObservation.JointName = resolved == .right ? .rightAnkle : .leftAnkle

        guard
            let hip   = try? observation.recognizedPoint(hipJoint),
            let knee  = try? observation.recognizedPoint(kneeJoint),
            let ankle = try? observation.recognizedPoint(ankleJoint),
            hip.confidence > 0.5, knee.confidence > 0.5, ankle.confidence > 0.5
        else { return nil }

        let hipPt   = CGPoint(x: hip.x,   y: hip.y)
        let kneePt  = CGPoint(x: knee.x,  y: knee.y)
        let anklePt = CGPoint(x: ankle.x, y: ankle.y)
        let flexion = angle(a: hipPt, b: kneePt, c: anklePt)

        return ROMResult(
            kneeFlexion:   flexion,
            kneeExtension: max(-10, 180 - flexion),
            confidence:    min(hip.confidence, knee.confidence, ankle.confidence),
            hipPoint:      hipPt,
            kneePoint:     kneePt,
            anklePoint:    anklePt
        )
    }

    private func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let ba = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let bc = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let dot = ba.x * bc.x + ba.y * bc.y
        let mag = sqrt(ba.x*ba.x + ba.y*ba.y) * sqrt(bc.x*bc.x + bc.y*bc.y)
        guard mag > 0 else { return 0 }
        return acos(max(-1, min(1, Double(dot / mag)))) * (180 / .pi)
    }
}
