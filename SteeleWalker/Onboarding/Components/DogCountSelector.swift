import SwiftUI

struct DogCountSelector: View {
    @Binding var count: Int

    private let options: [(count: Int, label: String)] = [
        (1, "1 - Solo act"),
        (2, "2 - Dynamic duo"),
        (3, "3 - Squad"),
        (4, "4 - Wolf pack")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.count) { option in
                Button {
                    count = option.count
                } label: {
                    Text(option.label)
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(count == option.count ? Color.accentColor : Color.secondary.opacity(0.15))
                        .foregroundStyle(count == option.count ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
