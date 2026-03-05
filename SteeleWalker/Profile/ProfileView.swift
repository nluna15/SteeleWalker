import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var dogs: [Dog] = []
    @State private var isLoadingDogs: Bool = false
    @State private var loadError: String?

    private var userId: String { auth.currentUser?.uid ?? "" }

    var body: some View {
        List {
            // MARK: My Dogs
            Section("My Dogs") {
                if isLoadingDogs {
                    ProgressView("Loading…")
                } else {
                    ForEach(dogs) { dog in
                        NavigationLink(dog.name) {
                            DogEditView(dog: dog)
                        }
                    }
                    .onDelete(perform: deleteDogs)
                }

                NavigationLink {
                    AddDogView(userId: userId, onAdded: { loadDogs() })
                } label: {
                    Label("Add Dog", systemImage: "plus.circle")
                }
            }

            // MARK: Walk Preferences
            Section("Walk Preferences") {
                NavigationLink("Weekday Schedule") {
                    WalkingPreferencesView(userId: userId)
                }
            }

            // MARK: Location
            Section("Location") {
                NavigationLink("Edit Location") {
                    LocationEditView(userId: userId)
                }
            }

            // MARK: Account
            Section {
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .task { loadDogs() }
        .refreshable { loadDogs() }
        .alert("Failed to load dogs", isPresented: Binding(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    private func loadDogs() {
        isLoadingDogs = true
        Task {
            do {
                dogs = try await DogService.fetchDogs(userId: userId)
            } catch {
                loadError = error.localizedDescription
            }
            isLoadingDogs = false
        }
    }

    private func deleteDogs(at offsets: IndexSet) {
        let toDelete = offsets.map { dogs[$0] }
        dogs.remove(atOffsets: offsets)
        Task {
            for dog in toDelete {
                try? await DogService.softDeleteDog(id: dog.id)
            }
        }
    }
}
