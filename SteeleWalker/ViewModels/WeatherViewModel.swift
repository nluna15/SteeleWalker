import Foundation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var current: WeatherSnapshot?
    @Published var hourly: [HourlyForecast] = []
    @Published var timezone: String?
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var recommendation: WalkRecommendation?
    @Published var isLoadingRecommendation: Bool = false
    @Published var dogs: [Dog] = []
    @Published var selectedDogIds: Set<String> = []
    @Published var sunrise: String?
    @Published var sunset: String?
    @Published var locationDisplay: String?

    private let userId: String
    private var refreshTimer: Timer?

    init(userId: String) {
        self.userId = userId
    }

    func loadForecast() async {
        showError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let t0 = CFAbsoluteTimeGetCurrent()
        debugLog("loadForecast START")

        do {
            debugLog("fetchUser START")
            let user = try await UserService.fetchUser(uid: userId)
            debugLog("fetchUser DONE (\(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - t0))s)")

            guard let location = user.location else {
                debugLog("ABORT - user has no location")
                errorMessage = "No location set. Update your location in Profile."
                showError = true
                return
            }

            debugLog("fetchForecast START (location: \(location))")
            let envelope = try await WeatherService.fetchForecast(for: location)
            debugLog("fetchForecast DONE (\(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - t0))s) - current: \(envelope.current.conditionText), hourly count: \(envelope.hourly.count)")

            current = envelope.current
            hourly = envelope.hourly
            timezone = envelope.timezone
            sunrise = envelope.sunrise
            sunset = envelope.sunset
            lastUpdated = Date()

            // Build location display: "ZIP · City" or just "City"
            let city = envelope.locationName ?? location.city
            if let zip = location.zipCode, !zip.isEmpty {
                locationDisplay = city.map { "\(zip) · \($0)" } ?? zip
            } else {
                locationDisplay = city
            }

            await fetchRecommendation(envelope: envelope)
        } catch {
            debugLog("loadForecast FAILED (\(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - t0))s) - \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        debugLog("loadForecast END (\(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - t0))s)")
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.loadForecast()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    var lastUpdatedText: String {
        guard let lastUpdated else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }

    func invalidateDogCache() {
        dogs = []
    }

    // MARK: - Dog Selection

    var allDogsSelected: Bool {
        selectedDogIds.count == dogs.count
    }

    /// Current recommendation detail for the selected dog(s).
    var activeCurrentDetail: RecommendationDetail? {
        guard let rec = recommendation else { return nil }
        if allDogsSelected { return rec.household.current }
        let selected = rec.dogs.filter { selectedDogIds.contains($0.dogId) }
        guard !selected.isEmpty else { return rec.household.current }
        return selected.map(\.current).max(by: { $0.level < $1.level })
    }

    /// Hourly recommendations for the selected dog(s).
    var activeHourlyRecommendations: [HourlyRecommendationDetail] {
        guard let rec = recommendation else { return [] }
        if allDogsSelected { return rec.household.hourly }
        let selected = rec.dogs.filter { selectedDogIds.contains($0.dogId) }
        guard !selected.isEmpty else { return rec.household.hourly }
        if selected.count == 1 { return selected[0].hourly }

        // Merge: for each timestamp, take the most restrictive level
        let first = selected[0].hourly
        return first.enumerated().map { index, entry in
            selected.compactMap { $0.hourly[safe: index] }.max(by: { $0.level < $1.level }) ?? entry
        }
    }

    func toggleDog(_ id: String) {
        if selectedDogIds.contains(id) {
            guard selectedDogIds.count > 1 else { return }
            selectedDogIds.remove(id)
        } else {
            selectedDogIds.insert(id)
        }
    }

    func selectAll() {
        selectedDogIds = Set(dogs.map(\.id))
    }

    // MARK: - Recommendation

    private func fetchRecommendation(envelope: ForecastEnvelope) async {
        isLoadingRecommendation = true
        defer { isLoadingRecommendation = false }

        do {
            if dogs.isEmpty {
                debugLog("fetchDogs START")
                dogs = try await DogService.fetchDogs(userId: userId)
                debugLog("fetchDogs DONE - \(dogs.count) dogs")
            }

            if selectedDogIds.isEmpty {
                selectedDogIds = Set(dogs.map(\.id))
            }

            guard !dogs.isEmpty else {
                debugLog("no dogs — skipping recommendation")
                recommendation = nil
                return
            }

            let dogIds = dogs.map(\.id)
            debugLog("fetchRecommendation START (\(dogIds.count) dogs)")
            recommendation = try await RecommendationService.fetchRecommendation(
                dogIds: dogIds,
                weather: envelope
            )
            debugLog("fetchRecommendation DONE - household level: \(recommendation?.household.current.levelKey ?? "nil")")
        } catch {
            debugLog("fetchRecommendation FAILED: \(error)")
            recommendation = nil
        }
    }

    // MARK: - Unit Helpers

    static func displayTemp(_ fahrenheit: Double, metric: Bool) -> String {
        if metric {
            let celsius = (fahrenheit - 32) * 5 / 9
            return "\(Int(celsius.rounded()))°C"
        }
        return "\(Int(fahrenheit.rounded()))°F"
    }

    static func displayWindSpeed(_ mph: Double, metric: Bool) -> String {
        if metric {
            let kmh = mph * 1.60934
            return "\(Int(kmh.rounded())) km/h"
        }
        return "\(Int(mph.rounded())) mph"
    }

    static func displayWindDirection(_ degrees: Int) -> String {
        WeatherSnapshot.cardinal(from: degrees)
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[Weather] \(message)")
        #endif
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
