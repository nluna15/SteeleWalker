import SwiftUI
import Charts

struct TemperatureChartView: View {
    let hourly: [HourlyForecast]
    let metric: Bool
    let hourlyRecommendations: [HourlyRecommendationDetail]
    let timezone: String?

    private var dataPoints: [(date: Date, temp: Double)] {
        Array(hourly.prefix(24)).compactMap { entry in
            guard let date = entry.date else { return nil }
            let temp = metric ? (entry.temperatureF - 32) * 5 / 9 : entry.temperatureF
            return (date, temp)
        }
    }

    private var minPoint: (date: Date, temp: Double)? {
        dataPoints.min(by: { $0.temp < $1.temp })
    }

    private var maxPoint: (date: Date, temp: Double)? {
        dataPoints.max(by: { $0.temp < $1.temp })
    }

    private var tz: TimeZone {
        timezone.flatMap { TimeZone(identifier: $0) } ?? .current
    }

    var body: some View {
        WeatherChartCard(title: "Temperature", systemImage: "thermometer.medium") {
            Chart {
                // Recommendation background bands
                ForEach(hourlyRecommendations.prefix(24)) { rec in
                    if let start = rec.date {
                        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
                        RectangleMark(
                            xStart: .value("Start", start),
                            xEnd: .value("End", end)
                        )
                        .foregroundStyle(rec.recommendationLevel.color.opacity(0.15))
                    }
                }

                // Area fill
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Temp", point.temp)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.orange.opacity(0.3), .orange.opacity(0.0)],
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
                        y: .value("Temp", point.temp)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Min annotation
                if let min = minPoint {
                    PointMark(
                        x: .value("Time", min.date),
                        y: .value("Temp", min.temp)
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .bottom, spacing: 4) {
                        Text(formatTemp(min.temp))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Max annotation
                if let max = maxPoint {
                    PointMark(
                        x: .value("Time", max.date),
                        y: .value("Temp", max.temp)
                    )
                    .foregroundStyle(.red)
                    .annotation(position: .top, spacing: 4) {
                        Text(formatTemp(max.temp))
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
                        if let temp = value.as(Double.self) {
                            Text("\(Int(temp))\(metric ? "C" : "F")")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private func formatTemp(_ temp: Double) -> String {
        "\(Int(temp.rounded()))°"
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
