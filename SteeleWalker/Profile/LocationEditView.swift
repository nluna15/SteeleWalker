import SwiftUI
import MapKit

// MARK: - Suggestion Model

private struct LocationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

// MARK: - MapKit Completer Wrapper

private class LocationCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [LocationSuggestion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        completer.queryFragment = query
    }

    func clear() { suggestions = [] }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(5).map {
            LocationSuggestion(title: $0.title, subtitle: $0.subtitle)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

// MARK: - View Model

@MainActor
private class LocationEditViewModel: ObservableObject {
    @Published var zipCode: String = ""
    @Published var neighborhood: String = ""
    @Published var city: String = ""

    @Published var isLoading = false
    @Published var currentLocationDisplay: String?
    @Published var isSaving = false
    @Published var didSave = false
    @Published var showError = false
    @Published var errorMessage: String?

    let userId: String

    init(userId: String) { self.userId = userId }

    func load() async {
        isLoading = true
        do {
            let user = try await UserService.fetchUser(uid: userId)
            if let loc = user.location {
                if loc.type == .gps {
                    currentLocationDisplay = "GPS location"
                } else {
                    if let zip = loc.zipCode, !zip.isEmpty {
                        zipCode = zip
                    }
                    if let cityStr = loc.city, !cityStr.isEmpty {
                        let parts = cityStr.components(separatedBy: ", ")
                        if parts.count >= 2 {
                            neighborhood = parts[0]
                            city = parts.dropFirst().joined(separator: ", ")
                        } else {
                            neighborhood = cityStr
                        }
                    }
                    var displayParts: [String] = []
                    if !zipCode.isEmpty { displayParts.append("ZIP \(zipCode)") }
                    if !neighborhood.isEmpty { displayParts.append(neighborhood) }
                    currentLocationDisplay = displayParts.isEmpty ? nil : displayParts.joined(separator: " · ")
                }
            }
        } catch {
            // Non-fatal — form starts empty
        }
        isLoading = false
    }

    var isZipValid: Bool {
        zipCode.range(of: #"^\d{5}$"#, options: .regularExpression) != nil
    }

    var isNeighborhoodValid: Bool {
        !neighborhood.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isValid: Bool { isZipValid || isNeighborhoodValid }

    func save() async {
        isSaving = true
        var locationDict: [String: Any] = ["type": "manual"]
        if isZipValid {
            locationDict["zip_code"] = zipCode
        }
        if isNeighborhoodValid {
            locationDict["city"] = "\(neighborhood.trimmingCharacters(in: .whitespaces)), \(city.trimmingCharacters(in: .whitespaces))"
        }
        do {
            try await UserService.updateUser(uid: userId, fields: ["location": locationDict])
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}

// MARK: - View

struct LocationEditView: View {
    @StateObject private var vm: LocationEditViewModel
    @StateObject private var neighborhoodCompleter = LocationCompleter()
    @StateObject private var cityCompleter = LocationCompleter()
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case zip, neighborhood, city }

    init(userId: String) {
        _vm = StateObject(wrappedValue: LocationEditViewModel(userId: userId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Current location banner
                if vm.isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading current location…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let current = vm.currentLocationDisplay {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Current: \(current)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // ZIP Code section
                VStack(alignment: .leading, spacing: 6) {
                    Text("ZIP Code")
                        .font(.headline)
                    TextField("e.g. 90210", text: $vm.zipCode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .zip)
                    if !vm.zipCode.isEmpty && !vm.isZipValid {
                        Text("Enter a valid 5-digit ZIP code")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                dividerLabel("or")

                // Neighborhood & City section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Neighborhood & City")
                        .font(.headline)

                    // Neighborhood field + typeahead
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Neighborhood")
                            .font(.subheadline.weight(.medium))
                        TextField("e.g. Wicker Park", text: $vm.neighborhood)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .neighborhood)
                            .onChange(of: vm.neighborhood) { _, newValue in neighborhoodCompleter.search(newValue) }

                        if focusedField == .neighborhood && !neighborhoodCompleter.suggestions.isEmpty {
                            suggestionsList(neighborhoodCompleter.suggestions) { suggestion in
                                vm.neighborhood = suggestion.title
                                neighborhoodCompleter.clear()
                                // Auto-fill city from subtitle if city is empty
                                if vm.city.isEmpty, let firstPart = suggestion.subtitle.components(separatedBy: ", ").first, !firstPart.isEmpty {
                                    vm.city = firstPart
                                }
                                focusedField = .city
                            }
                        }
                    }

                    // City field + typeahead
                    VStack(alignment: .leading, spacing: 4) {
                        Text("City")
                            .font(.subheadline.weight(.medium))
                        TextField("e.g. Chicago", text: $vm.city)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .city)
                            .onChange(of: vm.city) { _, newValue in cityCompleter.search(newValue) }

                        if focusedField == .city && !cityCompleter.suggestions.isEmpty {
                            suggestionsList(cityCompleter.suggestions) { suggestion in
                                vm.city = suggestion.title
                                cityCompleter.clear()
                                focusedField = nil
                            }
                        }
                    }
                }

                // Validation hint
                if !vm.isValid && (!vm.zipCode.isEmpty || !vm.neighborhood.isEmpty || !vm.city.isEmpty) {
                    Text("Fill in a valid ZIP code, or both neighborhood and city.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Save button
                Button {
                    focusedField = nil
                    Task { await vm.save() }
                } label: {
                    Group {
                        if vm.isSaving {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Saving…").font(.headline)
                            }
                        } else {
                            Text("Save Location").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isValid ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!vm.isValid || vm.isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("Edit Location")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Could not save location.")
        }
        .onChange(of: vm.didSave) { _, saved in
            if saved { dismiss() }
        }
    }

    // MARK: - Helpers

    private func dividerLabel(_ text: String) -> some View {
        HStack {
            Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.3))
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.3))
        }
    }

    private func suggestionsList(_ suggestions: [LocationSuggestion], onSelect: @escaping (LocationSuggestion) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if suggestion.id != suggestions.last?.id {
                    Divider().padding(.leading, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
