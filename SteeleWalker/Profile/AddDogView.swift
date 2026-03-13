import SwiftUI

struct AddDogView: View {
    let userId: String
    let onAdded: () -> Void

    @State private var draft = DogDraft()
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private var isValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && !draft.breedIds.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Step1DogFormView(dog: $draft, index: 0)

                Button {
                    Task { await save() }
                } label: {
                    Group {
                        if isSaving {
                            HStack {
                                ProgressView().tint(.white)
                                Text("Saving…").font(.headline)
                            }
                        } else {
                            Text("Add Dog").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!isValid || isSaving)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Add Dog")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Could not add dog.")
        }
    }

    private func save() async {
        isSaving = true
        do {
            _ = try await DogService.addDog(
                userId: userId,
                name: draft.name,
                breedIds: draft.breedIds,
                size: draft.size.rawValue,
                healthConditions: draft.mobilities.flatMap(\.healthConditionKeys),
                sensitivities: draft.sensitivities.map(\.rawValue),
                birthYear: draft.computedBirthYear ?? Calendar.current.component(.year, from: Date()),
                healthNotes: draft.mobilities.contains(.other) && !draft.mobilityNote.isEmpty ? draft.mobilityNote : nil
            )
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}

