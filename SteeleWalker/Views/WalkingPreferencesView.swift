import SwiftUI

struct WalkingPreferencesView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: WalkingPreferencesViewModel
    @Environment(\.dismiss) private var dismiss

    init(userId: String) {
        _vm = StateObject(wrappedValue: WalkingPreferencesViewModel(userId: userId))
    }

    private let durationOptions = [15, 30, 45, 60]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if vm.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.top, 40)
                } else {
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

                    // Save button
                    Button {
                        Task { await vm.save() }
                    } label: {
                        Group {
                            if vm.isSaving {
                                HStack {
                                    ProgressView().tint(.white)
                                    Text("Saving…").font(.headline)
                                }
                            } else {
                                Text("Save Schedule").font(.headline)
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
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("Walk Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Could not save schedule.")
        }
        .onChange(of: vm.didSave) { _, saved in
            if saved { dismiss() }
        }
    }
}
