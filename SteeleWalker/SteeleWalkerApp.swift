import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct SteeleWalkerApp: App {
    @StateObject private var auth = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.currentUser == nil {
                WelcomeView()
            } else {
                ContentView()
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
