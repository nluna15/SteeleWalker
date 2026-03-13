import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 3   // steps 1-3 (step 0 = welcome, not counted)

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        // Divide by totalSteps + 1 so arriving at the last step shows (n-1)/n progress,
        // not 100%. The bar only reaches 100% after the submit action advances past totalSteps.
        return CGFloat(max(currentStep, 0)) / CGFloat(totalSteps + 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 6)
    }
}
