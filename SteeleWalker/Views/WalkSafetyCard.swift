import SwiftUI

struct WalkSafetyCard: View {
    let detail: RecommendationDetail

    @State private var showReasons = false

    private var level: RecommendationLevel {
        detail.recommendationLevel
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: level.systemImage)
                    .font(.title2)
                    .foregroundStyle(level.color)
                Text(level.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(level.color)
            }

            Text(level.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let max = detail.maxDurationMin, max > 0 {
                Label("Max duration: \(max) min", systemImage: "timer")
                    .font(.subheadline.weight(.medium))
            }

            if !detail.reasons.isEmpty {
                Button {
                    withAnimation { showReasons.toggle() }
                } label: {
                    HStack {
                        Text("Details")
                            .font(.caption.weight(.medium))
                        Image(systemName: showReasons ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if showReasons {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(detail.reasons, id: \.self) { reason in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\u{2022}")
                                Text(reason)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
