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
            debugLog("resolveCoordinates - using GPS coords (\(lat), \(lon))")
            return (lat, lon)
        }

        let query: String
        if let zip = location.zipCode, !zip.isEmpty {
            query = zip
        } else if let city = location.city, !city.isEmpty {
            query = city
        } else {
            debugLog("resolveCoordinates - no GPS, zip, or city")
            throw WeatherError.unresolvableLocation
        }

        debugLog("resolveCoordinates - geocoding \"\(query)\"")
        guard let request = MKGeocodingRequest(addressString: query) else {
            throw WeatherError.geocodingFailed(query)
        }
        let mapItems = try await request.mapItems
        guard let location = mapItems.first?.location else {
            throw WeatherError.geocodingFailed(query)
        }
        debugLog("resolveCoordinates - geocoded to (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        return (location.coordinate.latitude, location.coordinate.longitude)
    }

    static func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherSnapshot {
        let envelope = try await fetchForecast(lat: lat, lon: lon)
        return envelope.current
    }

    /// Fetch the full forecast envelope (current + hourly + timezone).
    static func fetchForecast(for location: Location) async throws -> ForecastEnvelope {
        let (lat, lon) = try await resolveCoordinates(for: location)
        return try await fetchForecast(lat: lat, lon: lon)
    }

    /// Fetch the full forecast envelope by coordinates.
    static func fetchForecast(lat: Double, lon: Double) async throws -> ForecastEnvelope {
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
        request.timeoutInterval = 15
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        debugLog("HTTP GET \(components.url?.absoluteString ?? "nil")")
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        debugLog("HTTP \(http?.statusCode ?? -1), body \(data.count) bytes")

        guard let http, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            debugLog("HTTP error body: \(body)")
            throw WeatherError.httpError(body)
        }

        #if DEBUG
        if let raw = String(data: data, encoding: .utf8) {
            debugLog("raw JSON (first 500 chars): \(String(raw.prefix(500)))")
        }
        #endif

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: string) { return date }

            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(string)"
            )
        }

        do {
            let envelope = try decoder.decode(ForecastEnvelope.self, from: data)
            debugLog("decode OK - current temp: \(envelope.current.temperatureF), hourly: \(envelope.hourly.count)")
            return envelope
        } catch {
            debugLog("decode FAILED: \(error)")
            throw error
        }
    }

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[Weather] \(message)")
        #endif
    }
}

/// Full response shape from the Cloud Function.
struct ForecastEnvelope: Decodable {
    let current: WeatherSnapshot
    let hourly: [HourlyForecast]
    let timezone: String
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
