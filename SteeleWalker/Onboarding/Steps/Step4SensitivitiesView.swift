import SwiftUI

struct Step4SensitivitiesView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weather Sensitivities")
                        .font(.title2.bold())
                    Text("Does your dog have any weather sensitivities we should know about?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    // "None" option
                    Button {
                        vm.selectedSensitivities.removeAll()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(vm.selectedSensitivities.isEmpty ? Color.accentColor : Color.secondary.opacity(0.3))
                            Text("None — my dog handles all weather fine")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()

                    ForEach(DogSensitivity.allCases, id: \.self) { sensitivity in
                        let isSelected = vm.selectedSensitivities.contains(sensitivity)
                        Button {
                            if isSelected {
                                vm.selectedSensitivities.remove(sensitivity)
                            } else {
                                vm.selectedSensitivities.insert(sensitivity)
                            }
                        } label: {
                            HStack {
                                Image(systemName: sensitivity.systemImage)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 28)
                                Text(sensitivity.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if sensitivity != DogSensitivity.allCases.last {
                            Divider()
                        }
                    }
                }
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

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
    }

    private var submitButton: some View {
        Button {
            guard !vm.isSubmitting else { return }
            Task {
                await vm.submit()
            }
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
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(vm.isSubmitting)
        .padding(.top, 8)
    }
}
