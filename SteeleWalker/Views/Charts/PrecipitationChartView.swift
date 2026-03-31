import SwiftUI
import Charts

struct PrecipitationChartView: View {
    let hourly: [HourlyForecast]
    let timezone: String?

    private var dataPoints: [(date: Date, prob: Int, type: String?)] {
        Array(hourly.prefix(24)).compactMap { entry in
            guard let date = entry.date else { return nil }
            return (date, entry.precipProbability, entry.precipType)
        }
    }

    private var tz: TimeZone {
        timezone.flatMap { TimeZone(identifier: $0) } ?? .current
    }

    var body: some View {
        WeatherChartCard(title: "Precipitation", systemImage: "cloud.rain") {
            Chart {
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                    BarMark(
                        x: .value("Time", point.date, unit: .hour),
                        y: .value("Chance", point.prob)
                    )
                    .foregroundStyle(precipColor(for: point.type))
                }

                // "Likely" threshold line
                RuleMark(y: .value("Likely", 50))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Likely")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                    AxisValueLabel {
                        if let prob = value.as(Int.self) {
                            Text("\(prob)%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0 ... 100)
            .frame(height: 160)
        }
    }

    private func precipColor(for type: String?) -> Color {
        switch type?.lowercased() {
        case "snow":  return .cyan
        case "sleet": return .teal
        case "rain":  return .blue
        case .some:   return .blue
        case .none:   return .blue.opacity(0.4)
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
