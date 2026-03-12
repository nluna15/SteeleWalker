import SwiftUI
import FirebaseFirestore

// MARK: - View Model

@MainActor
private class LocationEditViewModel: ObservableObject {
    @Published var locationText: String = ""
    @Published var useGPS: Bool = false

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
                    useGPS = true
                    currentLocationDisplay = "GPS location"
                } else {
                    if let zip = loc.zipCode, !zip.isEmpty {
                        currentLocationDisplay = "ZIP \(zip)"
                    } else if let city = loc.city, !city.isEmpty {
                        currentLocationDisplay = city
                    }
                }
            }
        } catch {
            // Non-fatal — form starts empty
        }
        isLoading = false
    }

    var isValid: Bool {
        useGPS || !locationText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save(locationManager: LocationManager) async {
        isSaving = true
        var locationDict: [String: Any]
        if useGPS, let coord = locationManager.lastLocation {
            locationDict = ["type": "gps", "lat": coord.latitude, "long": coord.longitude]
        } else {
            locationDict = ["type": "manual"]
            let trimmed = locationText.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: #"^\d{5}$"#, options: .regularExpression) != nil {
                locationDict["zip_code"] = trimmed
            } else {
                locationDict["city"] = trimmed
            }
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
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

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
                        Text("Loading current location...")
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

                // GPS toggle
                Toggle(isOn: $vm.useGPS) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Share My Location")
                            .font(.headline)
                    }
                }
                .onChange(of: vm.useGPS) { _, isOn in
                    if isOn {
                        Task { await locationManager.fetchCurrentLocation() }
                    }
                }

                if vm.useGPS {
                    if let place = locationManager.placeName {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(place)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = locationManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if !vm.useGPS {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(.headline)
                        TextField("ZIP code, city, or neighborhood", text: $vm.locationText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                }

                // Save button
                Button {
                    Task { await vm.save(locationManager: locationManager) }
                } label: {
                    Group {
                        if vm.isSaving {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Saving...").font(.headline)
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
}
