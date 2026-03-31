import SwiftUI
import Charts

struct WindChartView: View {
    let hourly: [HourlyForecast]
    let metric: Bool
    let timezone: String?

    private var dataPoints: [(date: Date, speed: Double)] {
        Array(hourly.prefix(24)).compactMap { entry in
            guard let date = entry.date else { return nil }
            let speed = metric ? entry.windSpeedMph * 1.60934 : entry.windSpeedMph
            return (date, speed)
        }
    }

    private var minPoint: (date: Date, speed: Double)? {
        dataPoints.min(by: { $0.speed < $1.speed })
    }

    private var maxPoint: (date: Date, speed: Double)? {
        dataPoints.max(by: { $0.speed < $1.speed })
    }

    private var strongThreshold: Double {
        metric ? 32.0 : 20.0
    }

    private var tz: TimeZone {
        timezone.flatMap { TimeZone(identifier: $0) } ?? .current
    }

    var body: some View {
        WeatherChartCard(title: "Wind", systemImage: "wind") {
            Chart {
                // Area fill
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Speed", point.speed)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.teal.opacity(0.3), .teal.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Line
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Speed", point.speed)
                    )
                    .foregroundStyle(.teal)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // "Strong" threshold line
                RuleMark(y: .value("Strong", strongThreshold))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Strong")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                // Min annotation
                if let min = minPoint {
                    PointMark(
                        x: .value("Time", min.date),
                        y: .value("Speed", min.speed)
                    )
                    .foregroundStyle(.green)
                    .annotation(position: .bottom, spacing: 4) {
                        Text(formatSpeed(min.speed))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Max annotation
                if let max = maxPoint {
                    PointMark(
                        x: .value("Time", max.date),
                        y: .value("Speed", max.speed)
                    )
                    .foregroundStyle(.red)
                    .annotation(position: .top, spacing: 4) {
                        Text(formatSpeed(max.speed))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                        if let speed = value.as(Double.self) {
                            Text("\(Int(speed))")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private func formatSpeed(_ speed: Double) -> String {
        "\(Int(speed.rounded())) \(metric ? "km/h" : "mph")"
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
