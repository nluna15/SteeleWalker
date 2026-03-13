import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @AppStorage("useMetricUnits") private var useMetric = false
    @State private var weatherVM: WeatherViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = weatherVM {
                    WeatherContentView(vm: vm, useMetric: useMetric)
                } else {
                    ProgressView("Loading weather…")
                }
            }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("CRUD Debug") {
                        CRUDDebugView()
                    }
                }
                #endif

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .task(id: auth.currentUser?.uid) {
                guard let uid = auth.currentUser?.uid else {
                    weatherVM?.stopAutoRefresh()
                    weatherVM = nil
                    return
                }

                weatherVM?.stopAutoRefresh()
                let vm = WeatherViewModel(userId: uid)
                weatherVM = vm
                await vm.loadForecast()
                vm.startAutoRefresh()
            }
            .onDisappear {
                weatherVM?.stopAutoRefresh()
            }
        }
    }
}

/// Extracted so that `@ObservedObject` subscribes to `WeatherViewModel`'s
/// `@Published` properties. Using `@State` with a class reference in the
/// parent only tracks the pointer, not internal state changes.
private struct WeatherContentView: View {
    @ObservedObject var vm: WeatherViewModel
    var useMetric: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let current = vm.current {
                    CurrentWeatherCard(snapshot: current, metric: useMetric)

                    if !vm.lastUpdatedText.isEmpty {
                        Text(vm.lastUpdatedText)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else if !vm.isLoading {
                    ContentUnavailableView(
                        "No Weather Data",
                        systemImage: "cloud.slash",
                        description: Text("Set your location in Profile to see weather.")
                    )
                }

                if !vm.hourly.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.hourly) { hour in
                            HourlyForecastRow(forecast: hour, metric: useMetric)
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                            Divider()
                        }
                    }
                }
            }
            .padding(.top)
        }
        .refreshable {
            await vm.loadForecast()
        }
        .alert("Weather Error", isPresented: Binding(
            get: { vm.showError },
            set: { vm.showError = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .overlay {
            if vm.isLoading && vm.current == nil {
                ProgressView()
            }
        }
    }
}
