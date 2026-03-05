import SwiftUI

struct Step1DogsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Dog(s)")
                        .font(.title2.bold())
                    Text("How many dogs will you be walking?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                DogCountSelector(count: $vm.dogCount)

                ForEach(vm.dogs.indices, id: \.self) { index in
                    Step1DogFormView(dog: $vm.dogs[index], index: index)
                }

                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private var continueButton: some View {
        Button {
            vm.currentStep = 2
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.isStep1Valid ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!vm.isStep1Valid)
        .padding(.top, 8)
    }
}
