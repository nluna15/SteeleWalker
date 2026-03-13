import SwiftUI

struct CurrentWeatherCard: View {
    let snapshot: WeatherSnapshot
    let metric: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(WeatherViewModel.displayTemp(snapshot.temperatureF, metric: metric))
                .font(.system(size: 64, weight: .thin))

            Text(snapshot.conditionText)
                .font(.title3)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
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
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
