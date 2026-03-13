import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject var auth: AuthViewModel

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch vm.currentStep {
                case 0:
                    Step0WelcomeView {
                        withAnimation { vm.currentStep = 1 }
                    }
                case 1:
                    Step1DogsView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case 2:
                    Step2WalkRoutineView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case 3:
                    Step3LocationView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                default:
                    // currentStep is out of range — reset defensively rather than show blank
                    Color.clear.onAppear { vm.currentStep = 0 }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.currentStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.currentStep > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { vm.currentStep = max(0, vm.currentStep - 1) }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(vm.isSubmitting)
                    }
                }

                if vm.currentStep >= 1 {
                    ToolbarItem(placement: .principal) {
                        OnboardingProgressBar(currentStep: vm.currentStep)
                            .frame(width: 200)
                    }
                }
            }
        }
        .alert("Something went wrong", isPresented: $vm.submissionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Please try again.")
        }
        .onAppear { vm.onComplete = onComplete }
        .onChange(of: vm.isOnboardingComplete) { _, newValue in
            if newValue { onComplete() }
        }
    }
}
