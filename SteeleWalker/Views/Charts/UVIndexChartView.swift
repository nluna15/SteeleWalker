import SwiftUI
import Charts

struct UVIndexChartView: View {
    let hourly: [HourlyForecast]
    let timezone: String?

    private var dataPoints: [(date: Date, uv: Int)] {
        Array(hourly.prefix(24)).compactMap { entry in
            guard let date = entry.date else { return nil }
            return (date, entry.uvIndex)
        }
    }

    private var tz: TimeZone {
        timezone.flatMap { TimeZone(identifier: $0) } ?? .current
    }

    var body: some View {
        WeatherChartCard(title: "UV Index", systemImage: "sun.max") {
            Chart {
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                    BarMark(
                        x: .value("Time", point.date, unit: .hour),
                        y: .value("UV", point.uv)
                    )
                    .foregroundStyle(uvColor(for: point.uv))
                }

            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatHour(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: 0 ... max(11, dataPoints.map(\.uv).max() ?? 11))
            .frame(height: 160)
        }
    }

    private func uvColor(for index: Int) -> Color {
        switch index {
        case 0...2:  return .green
        case 3...5:  return .yellow
        case 6...7:  return .orange
        case 8...10: return .red
        default:     return .purple
        }
    }

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f
    }()

    private func formatHour(_ date: Date) -> String {
        Self.hourFormatter.timeZone = tz
        return Self.hourFormatter.string(from: date)
    }
}
