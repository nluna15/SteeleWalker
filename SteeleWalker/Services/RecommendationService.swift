import Foundation
import FirebaseAuth

struct RecommendationService {
    #if DEBUG
    private static let baseURL = "http://localhost:5001/safepaws-e70a8/us-central1/walkRecommendation"
    #else
    private static let baseURL = "https://us-central1-safepaws-e70a8.cloudfunctions.net/walkRecommendation"
    #endif

    static func fetchRecommendation(
        dogIds: [String],
        weather: ForecastEnvelope
    ) async throws -> WalkRecommendation {
        guard let user = Auth.auth().currentUser else {
            throw RecommendationError.notAuthenticated
        }
        guard !dogIds.isEmpty else {
            throw RecommendationError.noDogs
        }

        let idToken = try await user.getIDToken()
        let url = URL(string: baseURL)!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let payload = RecommendationRequestBody(
            dogIds: dogIds,
            weather: ForecastPayload(
                current: weather.current,
                hourly: weather.hourly,
                timezone: weather.timezone
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)

        debugLog("POST \(baseURL) with \(dogIds.count) dogs")
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        debugLog("HTTP \(http?.statusCode ?? -1), body \(data.count) bytes")

        guard let http, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            debugLog("HTTP error body: \(body)")
            throw RecommendationError.httpError(body)
        }

        let decoder = JSONDecoder()
        do {
            let recommendation = try decoder.decode(WalkRecommendation.self, from: data)
            debugLog("decode OK - household level: \(recommendation.household.current.levelKey)")
            return recommendation
        } catch {
            debugLog("decode FAILED: \(error)")
            throw error
        }
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[Recommendation] \(message)")
        #endif
    }
}

// MARK: - Request Body

private struct RecommendationRequestBody: Encodable {
    let dogIds: [String]
    let weather: ForecastPayload
}

/// Re-encodes the client-side weather models into the shape the server expects.
struct ForecastPayload: Encodable {
    let current: WeatherSnapshot
    let hourly: [HourlyForecast]
    let timezone: String
}

enum RecommendationError: LocalizedError {
    case notAuthenticated
    case noDogs
    case httpError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:    return "Not signed in"
        case .noDogs:              return "No dogs found"
        case .httpError(let body): return "Recommendation error: \(body)"
        }
    }
}
