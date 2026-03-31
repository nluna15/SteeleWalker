import SwiftUI

struct CurrentWeatherCard: View {
    let snapshot: WeatherSnapshot
    let metric: Bool
    let recommendationDetail: RecommendationDetail?

    private var level: RecommendationLevel? {
        recommendationDetail?.recommendationLevel
    }

    @State private var showReasons = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // MARK: - Left: Walk Recommendation
            if let level, let detail = recommendationDetail {
                VStack(spacing: 8) {
                    Image(systemName: level.systemImage)
                        .font(.title)
                        .foregroundStyle(level.color)

                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(level.color)

                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let max = detail.maxDurationMin, max > 0 {
                        Label("\(max) min max", systemImage: "timer")
                            .font(.caption2.weight(.medium))
                    }

                    if !detail.reasons.isEmpty {
                        Button {
                            withAnimation { showReasons.toggle() }
                        } label: {
                            HStack(spacing: 2) {
                                Text("Details")
                                Image(systemName: showReasons ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        }

                        if showReasons {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(detail.reasons, id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("\u{2022}")
                                        Text(reason)
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()

                Divider()
                    .padding(.vertical, 12)
            }

            // MARK: - Right: Weather Conditions
            VStack(spacing: 8) {
                Text(WeatherViewModel.displayTemp(snapshot.temperatureF, metric: metric))
                    .font(.system(size: 48, weight: .thin))

                Text(snapshot.conditionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow {
                        Label(
                            "\(WeatherViewModel.displayWindSpeed(snapshot.windSpeedMph, metric: metric)) \(snapshot.windCardinal)",
                            systemImage: "wind"
                        )
                        Label("\(snapshot.humidity)%", systemImage: "humidity")
                    }
                    GridRow {
                        Label("UV \(snapshot.uvIndex)", systemImage: "sun.max")
                        Label(
                            "Feels \(WeatherViewModel.displayTemp(snapshot.feelsLikeF, metric: metric))",
                            systemImage: "thermometer.medium"
                        )
                    }
                    if let aqi = snapshot.aqi {
                        GridRow {
                            Label("AQI \(aqi)", systemImage: "aqi.medium")
                                .gridCellColumns(2)
                        }
                    }
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
