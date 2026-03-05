import SwiftUI

struct Step2WalkRoutineView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let durationOptions = [15, 30, 45, 60]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Walk Routine")
                        .font(.title2.bold())
                    Text("Set up your typical weekday walking schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Walks per day
                VStack(alignment: .leading, spacing: 10) {
                    Text("Walks per day")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 10) {
                        ForEach(1...4, id: \.self) { n in
                            Button {
                                vm.walksPerDay = n
                            } label: {
                                Text("\(n)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(vm.walksPerDay == n ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(vm.walksPerDay == n ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 10) {
                    Text("Duration per walk")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 10) {
                        ForEach(durationOptions, id: \.self) { mins in
                            Button {
                                vm.durationMinutes = mins
                            } label: {
                                Text("\(mins) min")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(vm.durationMinutes == mins ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(vm.durationMinutes == mins ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Time slots
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preferred times")
                        .font(.subheadline.weight(.medium))
                    Text("Select all that apply")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(WalkTime.allCases) { time in
                            let isSelected = vm.selectedTimes.contains(time)
                            Button {
                                if isSelected {
                                    vm.selectedTimes.remove(time)
                                } else {
                                    vm.selectedTimes.insert(time)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: time.systemImage)
                                    Text(time.displayName)
                                        .font(.subheadline.weight(.medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
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
            vm.currentStep = 3
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.isStep2Valid ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!vm.isStep2Valid)
        .padding(.top, 8)
    }
}
