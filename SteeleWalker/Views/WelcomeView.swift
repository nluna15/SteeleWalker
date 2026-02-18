import SwiftUI
import AuthenticationServices
import FirebaseAuth
import GoogleSignInSwift
import CryptoKit

struct WelcomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("SteeleWalker")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Smart walks, happy dogs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard
                        let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                        let tokenData = appleIDCredential.identityToken,
                        let tokenString = String(data: tokenData, encoding: .utf8),
                        let nonce = currentNonce
                    else {
                        errorMessage = "Apple Sign-In failed: missing credential."
                        return
                    }
                    let credential = OAuthProvider.appleCredential(
                        withIDToken: tokenString,
                        rawNonce: nonce,
                        fullName: appleIDCredential.fullName
                    )
                    Task {
                        do {
                            try await auth.signInWithApple(credential: credential, rawNonce: nonce)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)

            GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = scene.windows.first?.rootViewController else {
                    errorMessage = "Google Sign-In failed: no root view controller."
                    return
                }
                Task {
                    do {
                        try await auth.signInWithGoogle(presenting: rootVC)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .frame(height: 50)
            .padding(.horizontal)

            if let message = errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
