import SwiftUI

struct DogSelectorView: View {
    let dogs: [Dog]
    let selectedDogIds: Set<String>
    let onToggle: (String) -> Void
    let onSelectAll: () -> Void

    private var allSelected: Bool {
        selectedDogIds.count == dogs.count
    }

    var body: some View {
        if dogs.count >= 2 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(label: "All", selected: allSelected) {
                        onSelectAll()
                    }

                    ForEach(dogs) { dog in
                        let isSelected = selectedDogIds.contains(dog.id)
                        chip(label: dog.name, selected: isSelected) {
                            onToggle(dog.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func chip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "pawprint.fill")
                    .font(.caption2)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
