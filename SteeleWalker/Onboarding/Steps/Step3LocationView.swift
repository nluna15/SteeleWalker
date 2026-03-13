import SwiftUI

struct Step3LocationView: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Walk Area")
                        .font(.title2.bold())
                    Text("Help us tailor weather alerts to your location.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Option 1 — Share My Location
                Button {
                    Task {
                        await locationManager.fetchCurrentLocation()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if vm.useGPS, locationManager.lastLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share My Location")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if vm.useGPS, let place = locationManager.placeName {
                                Text(place)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(vm.useGPS ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                if let error = locationManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // "or" divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.3))
                    Text("or")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle().frame(height: 1).foregroundStyle(Color.secondary.opacity(0.3))
                }

                // Option 2 — Manual text field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add Location")
                        .font(.headline)
                    TextField("ZIP code, city, or neighborhood", text: $vm.locationText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onChange(of: vm.locationText) { _, newValue in
                            if !newValue.isEmpty {
                                vm.useGPS = false
                            }
                        }
                }

                submitButton

                #if DEBUG
                Button("Skip Setup (Debug)") {
                    vm.skipForDebug()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onChange(of: locationManager.lastLocation?.latitude) { _, _ in
            if let coord = locationManager.lastLocation {
                vm.useGPS = true
                vm.gpsLatitude = coord.latitude
                vm.gpsLongitude = coord.longitude
                vm.locationText = ""
            }
        }
    }

    private var submitButton: some View {
        Button {
            guard !vm.isSubmitting else { return }
            Task { await vm.submit() }
        } label: {
            Group {
                if vm.isSubmitting {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Saving…")
                            .font(.headline)
                    }
                } else {
                    Text("Finish Setup")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(vm.isStep3Valid ? Color.accentColor : Color.secondary.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!vm.isStep3Valid || vm.isSubmitting)
        .padding(.top, 8)
    }
}
