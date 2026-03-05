import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            Text("SteeleWalker")
                .font(.largeTitle)
                .toolbar {
                    #if DEBUG
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink("CRUD Debug") {
                            CRUDDebugView()
                        }
                    }
                    #endif

                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
        }
    }
}
