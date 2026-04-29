import Foundation

@MainActor
final class APIService {
    static let shared = APIService()
    private let baseURL = URL(string: "http://localhost:8000")!
    private let session = URLSession.shared
    private init() {}

    // MARK: - ROM

    func postROMResult(patientID: String, kneeFlexion: Double, kneeExtension: Double) async throws {
        var request = makeRequest(path: "/rom/measure", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "patient_id": patientID,
            "knee_flexion": kneeFlexion,
            "knee_extension": kneeExtension,
            "timestamp": ISO8601DateFormatter().string(from: .now),
        ])
        try await send(request)
    }

    // MARK: - Pain

    func postPainRecord(patientID: String, record: PainRecord) async throws {
        var request = makeRequest(path: "/pain/record", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "patient_id": patientID,
            "nrs": record.nrsScore,
            "pain_types": record.painTypes,
            "flags": [
                "redness": record.redness,
                "swelling": record.swelling,
                "can_walk": record.canWalk,
                "fever": record.fever,
            ],
            "timestamp": ISO8601DateFormatter().string(from: record.date),
        ])
        try await send(request)
    }

    // MARK: - Exercise

    func fetchExercises(podWeek: Int, flexion: Double, painLevel: Int) async throws -> [ExerciseItem] {
        var components = URLComponents(url: baseURL.appending(path: "/exercise/recommend"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "pod_week", value: "\(podWeek)"),
            URLQueryItem(name: "flexion", value: "\(flexion)"),
            URLQueryItem(name: "pain", value: "\(painLevel)"),
        ]
        let request = URLRequest(url: components.url!)
        _ = try await session.data(for: request)
        // TODO: Decode server response into ExerciseItem
        return ExerciseItem.mockData
    }

    // MARK: - Helpers

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send(_ request: URLRequest) async throws {
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
    }

    enum APIError: LocalizedError {
        case serverError
        var errorDescription: String? { "서버 연결에 실패했어요. 잠시 후 다시 시도해 주세요." }
    }
}
