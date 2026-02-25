import SwiftUI

struct Step3LocationView: View {
    @ObservedObject var vm: OnboardingViewModel

    private var isZipValid: Bool {
        vm.zipCode.range(of: #"^\d{5}$"#, options: .regularExpression) != nil
    }

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

                // Toggle ZIP vs Neighborhood
                Picker("Location type", selection: $vm.useZipCode) {
                    Text("ZIP Code").tag(true)
                    Text("Neighborhood").tag(false)
                }
                .pickerStyle(.segmented)

                if vm.useZipCode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ZIP Code")
                            .font(.subheadline.weight(.medium))
                        TextField("e.g. 90210", text: $vm.zipCode)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .onChange(of: vm.zipCode) { _, newValue in
                                vm.zipCode = String(newValue.filter(\.isNumber).prefix(5))
                            }

                        if !vm.zipCode.isEmpty && !isZipValid {
                            Text("Enter a valid 5-digit ZIP code")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Neighborhood")
                                .font(.subheadline.weight(.medium))
                            TextField("e.g. Wicker Park", text: $vm.neighborhood)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("City")
                                .font(.subheadline.weight(.medium))
                            TextField("e.g. Chicago", text: $vm.city)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                    }
                }

                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private var continueButton: some View {
        Button {
            vm.currentStep = 4
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.isStep3Valid ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!vm.isStep3Valid)
        .padding(.top, 8)
    }
}
