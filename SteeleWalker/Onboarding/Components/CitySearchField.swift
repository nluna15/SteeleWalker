import SwiftUI
import MapKit

struct CitySearchField: View {
    let label: String
    @Binding var selectedCity: String
    @Binding var selectedRegion: String
    @Binding var selectedCountry: String

    @StateObject private var searchService = LocationSearchService()
    @State private var query: String = ""
    @State private var showDropdown: Bool = false
    @State private var isResolving: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !selectedCity.isEmpty {
                HStack(spacing: 4) {
                    Text(displayName)
                        .font(.subheadline)
                    Button {
                        selectedCity = ""
                        selectedRegion = ""
                        selectedCountry = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
            }

            if selectedCity.isEmpty {
                HStack {
                    TextField(label, text: $query)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: query) { _, newValue in
                            searchService.queryFragment = newValue
                            showDropdown = !newValue.isEmpty
                        }
                    if searchService.isSearching || isResolving {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if showDropdown && !searchService.results.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchService.results.prefix(8), id: \.self) { completion in
                            Button {
                                selectCompletion(completion)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(Color.secondary.opacity(0.05))
                        }
                    }
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    .zIndex(1)
                }
            }
        }
    }

    private var displayName: String {
        if !selectedRegion.isEmpty {
            return "\(selectedCity), \(selectedRegion)"
        } else if !selectedCountry.isEmpty {
            return "\(selectedCity), \(selectedCountry)"
        }
        return selectedCity
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        Task {
            do {
                let result = try await searchService.resolveCompletion(completion)
                selectedCity = result.city
                selectedRegion = result.region
                selectedCountry = result.country
            } catch {
                // Fall back to using the completion title as city name
                selectedCity = completion.title
                selectedRegion = ""
                selectedCountry = ""
            }
            query = ""
            showDropdown = false
            isResolving = false
        }
    }
}
