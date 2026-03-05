import SwiftUI

struct DogEditView: View {
    @StateObject private var vm: DogEditViewModel
    @Environment(\.dismiss) private var dismiss

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
                    ageRange: vm.ageRange,
                    mobilities: vm.mobilities,
                    mobilityNote: vm.mobilityNote
                )
            },
            set: { draft in
                vm.name = draft.name
                vm.breedIds = draft.breedIds
                vm.breedDisplayNames = draft.breedDisplayNames
                vm.size = draft.size
                vm.ageRange = draft.ageRange
                vm.mobilities = draft.mobilities
                vm.mobilityNote = draft.mobilityNote
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
        .onChange(of: vm.didSave) { _, saved in
            if saved { dismiss() }
        }
    }
}
