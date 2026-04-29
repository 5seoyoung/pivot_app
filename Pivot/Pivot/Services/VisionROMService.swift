import Foundation
import Vision

// Protocol — Vision 프레임워크 → 향후 Core ML 모델로 교체 시 View 코드 변경 없음
protocol ROMServiceProtocol {
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> ROMResult?
}

struct ROMResult {
    let kneeFlexion: Double
    let kneeExtension: Double
    let confidence: Float
}

// MARK: - Apple Vision 구현 (데모)

final class VisionROMService: ROMServiceProtocol {
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

    func processFrame(_ pixelBuffer: CVPixelBuffer) -> ROMResult? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([bodyPoseRequest])
        } catch {
            return nil
        }
        guard let observation = bodyPoseRequest.results?.first else { return nil }
        return calculateROM(from: observation)
    }

    private func calculateROM(from observation: VNHumanBodyPoseObservation) -> ROMResult? {
        guard
            let hip   = try? observation.recognizedPoint(.rightHip),
            let knee  = try? observation.recognizedPoint(.rightKnee),
            let ankle = try? observation.recognizedPoint(.rightAnkle),
            hip.confidence > 0.5, knee.confidence > 0.5, ankle.confidence > 0.5
        else { return nil }

        let flexion = angle(
            a: CGPoint(x: hip.x, y: hip.y),
            b: CGPoint(x: knee.x, y: knee.y),
            c: CGPoint(x: ankle.x, y: ankle.y)
        )

        return ROMResult(
            kneeFlexion: flexion,
            kneeExtension: max(-10, 180 - flexion),
            confidence: min(hip.confidence, knee.confidence, ankle.confidence)
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
