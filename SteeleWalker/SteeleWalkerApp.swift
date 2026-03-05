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
    @State private var localOnboardingDone: Bool = false

    private var hasCompletedOnboarding: Bool {
        guard let uid = auth.currentUser?.uid else { return false }
        return localOnboardingDone || UserDefaults.standard.bool(forKey: "onboardingComplete_\(uid)")
    }

    var body: some View {
        Group {
            if auth.currentUser == nil {
                WelcomeView()
            } else if !hasCompletedOnboarding {
                OnboardingContainerView {
                    localOnboardingDone = true
                }
            } else {
                ContentView()
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
