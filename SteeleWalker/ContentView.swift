import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            Text("SteeleWalker")
                .font(.largeTitle)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign Out") {
                            auth.signOut()
                        }
                    }
                }
        }
    }
}
