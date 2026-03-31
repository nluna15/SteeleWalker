import SwiftUI

struct HourlyChartsSection: View {
    let hourly: [HourlyForecast]
    let metric: Bool
    let recommendation: WalkRecommendation?
    let timezone: String?

    var body: some View {
        VStack(spacing: 16) {
            TemperatureChartView(
                hourly: hourly,
                metric: metric,
                hourlyRecommendations: recommendation?.household.hourly ?? [],
                timezone: timezone
            )

            UVIndexChartView(
                hourly: hourly,
                timezone: timezone
            )

            PrecipitationChartView(
                hourly: hourly,
                timezone: timezone
            )

            WindChartView(
                hourly: hourly,
                metric: metric,
                timezone: timezone
            )
        }
    }
}
