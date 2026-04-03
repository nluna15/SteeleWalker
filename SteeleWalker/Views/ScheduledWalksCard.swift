import SwiftUI

struct ScheduledWalksCard: View {
    let walks: [ScheduledWalkRecommendation]
    let timezone: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Walks")
                .font(.headline)
                .padding(.bottom, 2)

            ForEach(walks) { walk in
                ScheduledWalkRow(walk: walk, timezone: timezone)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ScheduledWalkRow: View {
    let walk: ScheduledWalkRecommendation
    let timezone: String

    private var level: RecommendationLevel {
        walk.recommendation.recommendationLevel
    }

    private var displayTime: String {
        walk.recommendedTime ?? walk.preferredTime
    }

    private var showsAdjustedTimeNote: Bool {
        guard let recommendedTime = walk.recommendedTime else { return false }
        return recommendedTime != walk.preferredTime
    }

    private var adjustmentNote: String {
        "Best time in your \(windowLabel) window. Usually \(formatted(walk.preferredTime))."
    }

    private var windowLabel: String {
        let parts = walk.preferredTime.split(separator: ":")
        guard let hour = parts.first.flatMap({ Int($0) }) else {
            return "usual walk"
        }

        switch hour {
        case 7...9:
            return "morning"
        case 11...13:
            return "midday"
        case 14...17:
            return "afternoon"
        case 18...20:
            return "evening"
        default:
            return "usual walk"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(level.color)
                    .frame(width: 8, height: 8)

                Text(formattedTime)
                    .font(.subheadline.weight(.medium))

                Text("·")
                    .foregroundStyle(.secondary)
                Text(walk.dayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(walk.durationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if showsAdjustedTimeNote {
                Text(adjustmentNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(level.displayName + briefDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var formattedTime: String {
        formatted(displayTime)
    }

    private func formatted(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return time
        }
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        if minute == 0 {
            return "\(displayHour) \(period)"
        }
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
    }

    private var briefDescription: String {
        switch level {
        case .optimal, .normalWalk:
            return ""
        default:
            return " — \(level.description)"
        }
    }
}
