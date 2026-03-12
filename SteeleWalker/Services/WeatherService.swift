import Foundation
import MapKit
import FirebaseAuth

struct WeatherService {
    #if DEBUG
    private static let baseURL = "http://localhost:5001/safepaws-e70a8/us-central1/weatherForecastHourly"
    #else
    private static let baseURL = "https://us-central1-safepaws-e70a8.cloudfunctions.net/weatherForecastHourly"
    #endif

    /// Fetch weather using the highest-precision location available.
    /// Priority: GPS lat/lon → zip code → city name.
    static func fetchCurrentWeather(for location: Location) async throws -> WeatherSnapshot {
        let (lat, lon) = try await resolveCoordinates(for: location)
        return try await fetchCurrentWeather(lat: lat, lon: lon)
    }

    /// Resolve a `Location` to a (lat, lon) pair.
    /// - GPS: uses stored coordinates directly.
    /// - Manual zip code: geocodes the zip.
    /// - Manual city: geocodes the city string.
    static func resolveCoordinates(for location: Location) async throws -> (Double, Double) {
        if location.type == .gps,
           let lat = location.latitude,
           let lon = location.longitude {
            return (lat, lon)
        }

        let query: String
        if let zip = location.zipCode, !zip.isEmpty {
            query = zip
        } else if let city = location.city, !city.isEmpty {
            query = city
        } else {
            throw WeatherError.unresolvableLocation
        }

        guard let request = MKGeocodingRequest(addressString: query) else {
            throw WeatherError.geocodingFailed(query)
        }
        let mapItems = try await request.mapItems
        guard let location = mapItems.first?.location else {
            throw WeatherError.geocodingFailed(query)
        }
        return (location.coordinate.latitude, location.coordinate.longitude)
    }

    static func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherSnapshot {
        guard let user = Auth.auth().currentUser else {
            throw WeatherError.notAuthenticated
        }
        let idToken = try await user.getIDToken()

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            throw WeatherError.httpError(body)
        }

        // Response shape: { current: { ... }, hourly: [...], timezone: "..." }
        // Decode only the `current` field into WeatherSnapshot
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(ForecastEnvelope.self, from: data)
        return envelope.current
    }
}

enum WeatherError: LocalizedError {
    case notAuthenticated
    case httpError(String)
    case unresolvableLocation
    case geocodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:         return "Not signed in"
        case .httpError(let body):      return "HTTP error: \(body)"
        case .unresolvableLocation:     return "No usable location (no GPS, zip, or city)"
        case .geocodingFailed(let q):   return "Could not geocode \"\(q)\""
        }
    }
}

private struct ForecastEnvelope: Decodable {
    let current: WeatherSnapshot
}
