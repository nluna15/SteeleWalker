import SwiftUI

struct CitySearchField: View {
    let label: String
    @Binding var selectedCity: String
    @Binding var selectedState: String

    @State private var query: String = ""
    @State private var showDropdown: Bool = false

    private var matches: [CitySeed.Entry] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.lowercased()
        return CitySeed.all
            .filter { entry in
                entry.city.localizedCaseInsensitiveContains(query)
                    || entry.displayName.localizedCaseInsensitiveContains(query)
            }
            .sorted { a, b in
                let aLower = a.city.lowercased()
                let bLower = b.city.lowercased()
                let aStarts = aLower.hasPrefix(lowerQuery)
                let bStarts = bLower.hasPrefix(lowerQuery)
                if aStarts != bStarts { return aStarts }
                return aLower < bLower
            }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !selectedCity.isEmpty {
                HStack(spacing: 4) {
                    Text("\(selectedCity), \(selectedState)")
                        .font(.subheadline)
                    Button {
                        selectedCity = ""
                        selectedState = ""
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
                TextField(label, text: $query)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onChange(of: query) { _, newValue in
                        showDropdown = !newValue.isEmpty
                    }

                if showDropdown && !matches.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(matches) { entry in
                            Button {
                                selectedCity = entry.city
                                selectedState = entry.state
                                query = ""
                                showDropdown = false
                            } label: {
                                Text(entry.displayName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(Color.secondary.opacity(0.05))

                            if entry.id != matches.last?.id {
                                Divider()
                            }
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
}
