import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var placeName: String?
    @Published var error: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocation() async {
        error = nil
        placeName = nil
        lastLocation = nil

        let status = manager.authorizationStatus
        if status != .authorizedWhenInUse && status != .authorizedAlways {
            // Set up continuation BEFORE requesting permission to avoid race
            // where delegate fires synchronously before continuation is stored
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                authorizationContinuation = cont
                requestPermission()
            }
            let updated = manager.authorizationStatus
            guard updated == .authorizedWhenInUse || updated == .authorizedAlways else {
                error = "Location access denied. Please enter your location manually."
                return
            }
        }

        // Use CLLocationUpdate.liveUpdates() with a timeout to avoid hanging
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for try await update in CLLocationUpdate.liveUpdates() {
                        guard let location = update.location else { continue }
                        await MainActor.run {
                            self.lastLocation = location.coordinate
                        }
                        await self.reverseGeocode(location)
                        return // Only need one location
                    }
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(15))
                    throw CancellationError()
                }
                // Wait for whichever finishes first, then cancel the other
                try await group.next()
                group.cancelAll()
            }
        } catch {
            if lastLocation == nil {
                self.error = "Could not determine location. Please enter it manually."
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async {
        let name = await Self.geocodePlaceName(for: location)
        placeName = name
    }

    private nonisolated static func geocodePlaceName(for location: CLLocation) async -> String {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return "Current Location"
        }
        do {
            let mapItems = try await request.mapItems
            guard let item = mapItems.first else {
                return "Current Location"
            }
            if let cityContext = item.addressRepresentations?.cityWithContext(.full) {
                return cityContext
            }
            return item.address?.shortAddress ?? "Current Location"
        } catch {
            return "Current Location"
        }
    }

    private var authorizationContinuation: CheckedContinuation<Void, Never>?
}

// MARK: - CLLocationManagerDelegate (authorization only)

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }
}
