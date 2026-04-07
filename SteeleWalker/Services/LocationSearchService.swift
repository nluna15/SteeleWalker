import MapKit

/// Wraps `MKLocalSearchCompleter` for live, global city typeahead.
/// Shared by onboarding and profile edit location flows.
@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var isSearching = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    var queryFragment: String = "" {
        didSet {
            if queryFragment.isEmpty {
                results = []
                isSearching = false
            } else {
                isSearching = true
                completer.queryFragment = queryFragment
            }
        }
    }

    /// Resolve a selected completion to structured location fields.
    func resolveCompletion(_ completion: MKLocalSearchCompletion) async throws -> (city: String, region: String, country: String) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let placemark = response.mapItems.first?.placemark else {
            throw LocationSearchError.noResults
        }

        let city = placemark.locality ?? placemark.name ?? completion.title
        let region = placemark.administrativeArea ?? ""
        let country = placemark.countryCode ?? ""
        return (city, region, country)
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        nonisolated(unsafe) let results = completer.results
        Task { @MainActor in
            self.results = results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.isSearching = false
        }
    }
}

// MARK: - Error

enum LocationSearchError: LocalizedError {
    case noResults

    var errorDescription: String? {
        switch self {
        case .noResults: return "Could not resolve location details"
        }
    }
}
