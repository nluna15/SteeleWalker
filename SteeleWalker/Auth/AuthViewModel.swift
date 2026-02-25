import Foundation
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?

    nonisolated(unsafe) private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    func signInWithApple(credential: AuthCredential, rawNonce: String) async throws {
        let result = try await Auth.auth().signIn(with: credential)
        await createOrMergeUserDoc(firebaseUser: result.user, provider: "apple")
    }

    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        await createOrMergeUserDoc(firebaseUser: authResult.user, provider: "google")
    }

    private func createOrMergeUserDoc(firebaseUser: FirebaseAuth.User, provider: String) async {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(firebaseUser.uid)

        let docExists: Bool
        do {
            let snapshot = try await ref.getDocument()
            docExists = snapshot.exists
        } catch {
            docExists = false
        }

        var data: [String: Any] = [
            "id": firebaseUser.uid,
            "name": firebaseUser.displayName ?? "",
            "auth_provider": provider,
            "auth_provider_id": firebaseUser.uid,
            "updated_at": FieldValue.serverTimestamp()
        ]

        if !docExists {
            data["created_at"] = FieldValue.serverTimestamp()
            data["notifications_enabled"] = false
            if let email = firebaseUser.email {
                data["email"] = email
            }
        }

        do {
            try await ref.setData(data, merge: true)
        } catch {
            print("AuthViewModel: failed to write user doc — \(error)")
        }
    }
}

enum AuthError: Error {
    case missingToken
}
