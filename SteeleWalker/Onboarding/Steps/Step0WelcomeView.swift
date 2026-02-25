import SwiftUI

struct Step0WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 12) {
                    Text("Welcome to SteeleWalker")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Let's get your dog's profile set up so we can tailor walk recommendations to your routine.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "dog.fill", text: "Add your dog(s) with breed and health info")
                    FeatureRow(icon: "clock.fill", text: "Set your preferred walk schedule")
                    FeatureRow(icon: "location.fill", text: "Tell us where you walk")
                    FeatureRow(icon: "cloud.sun.fill", text: "Customize weather sensitivities")
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 20)

                Button {
                    onGetStarted()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
