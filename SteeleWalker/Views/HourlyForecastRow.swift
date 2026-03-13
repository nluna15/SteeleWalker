import SwiftUI

struct HourlyForecastRow: View {
    let forecast: HourlyForecast
    let metric: Bool

    var body: some View {
        HStack {
            Text(timeLabel)
                .font(.subheadline.monospacedDigit())
                .frame(width: 55, alignment: .leading)

            Text(WeatherViewModel.displayTemp(forecast.temperatureF, metric: metric))
                .font(.subheadline.weight(.medium))
                .frame(width: 45, alignment: .trailing)

            Label(
                WeatherViewModel.displayWindSpeed(forecast.windSpeedMph, metric: metric),
                systemImage: "wind"
            )
            .font(.caption)
            .frame(width: 80, alignment: .leading)

            Label("\(forecast.humidity)%", systemImage: "humidity")
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            Spacer()

            Text("UV \(forecast.uvIndex)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let aqi = forecast.aqi {
                Text("AQI \(aqi)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timeLabel: String {
        guard let date = forecast.date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}
