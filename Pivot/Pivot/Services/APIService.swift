import Foundation

@MainActor
final class APIService {
    static let shared = APIService()

    // 서버 IP 변경 시 여기만 수정
    private let baseURL = URL(string: "http://172.30.1.2:8000")!
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Patient

    /// 온보딩 완료 시 1회 호출. 서버 patient UUID 반환.
    func registerPatient(_ profile: PatientProfile) async throws -> String {
        var req = makeRequest(path: "/patient", method: "POST")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let body: [String: Any] = [
            "surgery_date_primary":   formatter.string(from: profile.surgeryDate),
            "surgery_date_secondary": NSNull(),
            "surgery_side":           mapSide(profile.operatedSide),
            "height_cm":              profile.heightCm,
            "weight_kg":              profile.weightKg,
            "age":                    profile.age,
            "pre_surgery_activity":   mapActivity(profile.preSurgeryActivity),
            "non_surgical_leg":       mapLeg(profile.contralateralLegStatus),
            "fall_history_count":     0,
            "assistive_device":       mapAid(profile.currentAid),
            "living_env_bed":         "floor",
            "living_env_toilet_raised": false,
            "living_env_has_stairs":  false,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let id = json?["id"] as? String else { throw APIError.invalidResponse }
        return id
    }

    // MARK: - Session

    /// 운동 탭 진입 시 세션 생성. session UUID 반환.
    func createSession(patientId: String, stsScore: Int) async throws -> String {
        var req = makeRequest(path: "/session", method: "POST")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "patient_id":    patientId,
            "sts_functional": stsScore == 1,
        ])
        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 422 {
            throw APIError.acutePhaseBlocked
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let id = json?["id"] as? String else { throw APIError.invalidResponse }
        return id
    }

    // MARK: - Red Flag

    struct RedFlagResult {
        let isBlocked: Bool
        let blockReason: String?
    }

    func submitRedFlag(sessionId: String, record: PainRecord, wbLevel: String) async throws -> RedFlagResult {
        var req = makeRequest(path: "/session/\(sessionId)/red-flag", method: "POST")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "wound_discharge":  record.hasWoundDischarge,
            "redness_with_heat": record.redness,
            "swelling":         record.swelling,
            "fever":            record.fever,
            "fall_occurred":    record.hasFallInjury,
            "nrs_pre":          record.nrsScore,
            "nrs_post":         NSNull(),
            "wb_level":         wbLevel,
        ])
        let (data, _) = try await session.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return RedFlagResult(
            isBlocked:   json?["is_blocked"]   as? Bool   ?? false,
            blockReason: json?["block_reason"] as? String
        )
    }

    // MARK: - ROM

    func submitROM(sessionId: String, flexion: Double, extension ext: Double, source: String = "camera") async throws {
        var req = makeRequest(path: "/session/\(sessionId)/rom", method: "POST")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "flexion_deg":   flexion,
            "extension_deg": ext,
            "source":        source,
        ])
        try await send(req)
    }

    // MARK: - Recommendations

    struct VideoResult: Identifiable {
        let id: String
        let title: String
        let url: String?
        let stageBucket: String
    }

    func getRecommendations(sessionId: String) async throws -> [VideoResult] {
        let req = makeRequest(path: "/session/\(sessionId)/recommend", method: "GET")
        let (data, _) = try await session.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let results = json?["results"] as? [[String: Any]] ?? []
        return results.compactMap { dict in
            guard let id    = dict["video_id"] as? String,
                  let title = dict["title"]    as? String else { return nil }
            return VideoResult(
                id:          id,
                title:       title,
                url:         dict["url"] as? String,
                stageBucket: dict["stage_bucket"] as? String ?? ""
            )
        }
    }

    // MARK: - Helpers

    private func makeRequest(path: String, method: String) -> URLRequest {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func send(_ req: URLRequest) async throws {
        let (_, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
    }

    // MARK: - Mappings

    private func mapSide(_ s: String) -> String {
        switch s {
        case "좌측": return "left"
        case "양측": return "bilateral"
        default:    return "right"
        }
    }

    private func mapActivity(_ s: String) -> String {
        switch s {
        case "정기적 운동":    return "active"
        case "거의 누워·앉아": return "inactive"
        default:             return "normal"
        }
    }

    private func mapLeg(_ s: String) -> String { s == "괜찮아요" ? "normal" : "impaired" }

    private func mapAid(_ s: String) -> String {
        switch s {
        case "워커":         return "walker"
        case "목발", "지팡이": return "cane"
        default:            return "none"
        }
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case serverError, invalidResponse, acutePhaseBlocked
        var errorDescription: String? {
            switch self {
            case .serverError:       return "서버 연결에 실패했어요."
            case .invalidResponse:   return "서버 응답을 처리할 수 없어요."
            case .acutePhaseBlocked: return "수술 후 6일 이내에는 운동이 제한됩니다."
            }
        }
    }
}
