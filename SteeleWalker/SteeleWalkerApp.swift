import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

@main
struct SteeleWalkerApp: App {
    @StateObject private var auth = AuthViewModel()

    init() {
        FirebaseApp.configure()

        #if DEBUG
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        #endif
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
