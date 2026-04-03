import SwiftUI

struct SunriseSunsetCard: View {
    let sunrise: String
    let sunset: String

    var body: some View {
        WeatherChartCard(title: "Sunrise & Sunset", systemImage: "sun.horizon") {
            HStack(spacing: 0) {
                timeBlock(icon: "sunrise.fill", label: "Sunrise", time: sunrise, color: .orange)
                Spacer()
                timeBlock(icon: "sunset.fill", label: "Sunset", time: sunset, color: .indigo)
            }
        }
    }

    private func timeBlock(icon: String, label: String, time: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(time)
                    .font(.title3.weight(.medium))
            }
        }
    }
}
