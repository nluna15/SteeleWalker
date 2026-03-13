import SwiftUI

struct DogEditView: View {
    @StateObject private var vm: DogEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    init(dog: Dog) {
        _vm = StateObject(wrappedValue: DogEditViewModel(dog: dog))
    }

    // Synthetic DogDraft binding that mirrors vm's published properties
    private var draftBinding: Binding<DogDraft> {
        Binding(
            get: {
                DogDraft(
                    id: UUID(),
                    name: vm.name,
                    breedIds: vm.breedIds,
                    breedDisplayNames: vm.breedDisplayNames,
                    size: vm.size,
                    ageText: vm.ageText,
                    isUnderOneYear: vm.isUnderOneYear,
                    mobilities: vm.mobilities,
                    mobilityNote: vm.mobilityNote,
                    sensitivities: vm.sensitivities
                )
            },
            set: { draft in
                vm.name = draft.name
                vm.breedIds = draft.breedIds
                vm.breedDisplayNames = draft.breedDisplayNames
                vm.size = draft.size
                vm.ageText = draft.ageText
                vm.isUnderOneYear = draft.isUnderOneYear
                vm.mobilities = draft.mobilities
                vm.mobilityNote = draft.mobilityNote
                vm.sensitivities = draft.sensitivities
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Step1DogFormView(dog: draftBinding, index: 0)

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
                            Text("Save Changes").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(vm.isSaving)
                .padding(.horizontal, 24)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Group {
                        if vm.isDeleting {
                            HStack {
                                ProgressView().tint(.red)
                                Text("Deleting…").font(.headline)
                            }
                        } else {
                            Label("Delete \(vm.dog.name)", systemImage: "trash")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(vm.isDeleting)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Edit \(vm.dog.name)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Could not save changes.")
        }
        .confirmationDialog(
            "Delete \(vm.dog.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await vm.delete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(vm.dog.name) from your profile. This action cannot be undone.")
        }
        .onChange(of: vm.didSave) { _, saved in
            if saved { dismiss() }
        }
        .onChange(of: vm.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
    }
}
