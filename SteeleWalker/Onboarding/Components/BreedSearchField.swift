import SwiftUI

struct BreedSearchField: View {
    let label: String
    @Binding var breedIds: [String]
    @Binding var displayNames: [String]

    @State private var query: String = ""
    @State private var showDropdown: Bool = false

    private var matches: [BreedSeed.Entry] {
        guard !query.isEmpty else { return [] }
        let lowerQuery = query.lowercased()
        return BreedSeed.all
            .filter { entry in
                entry.name.localizedCaseInsensitiveContains(query)
                    && !breedIds.contains(entry.id)
            }
            .sorted { a, b in
                let aLower = a.name.lowercased()
                let bLower = b.name.lowercased()
                let aStarts = aLower.hasPrefix(lowerQuery)
                let bStarts = bLower.hasPrefix(lowerQuery)
                // 1) Prefix matches first
                if aStarts != bStarts { return aStarts }
                // 2) Among non-prefix, word-boundary matches before mid-word
                let aWordStart = aLower.contains(" \(lowerQuery)")
                let bWordStart = bLower.contains(" \(lowerQuery)")
                if aWordStart != bWordStart { return aWordStart }
                // 3) Alphabetical tie-break
                return aLower < bLower
            }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected breed chips
            if !displayNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(displayNames.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 4) {
                                Text(name)
                                    .font(.subheadline)
                                Button {
                                    breedIds.remove(at: index)
                                    displayNames.remove(at: index)
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
                    }
                }
            }

            // Search field to add more breeds
            TextField(label, text: $query)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .onChange(of: query) { _, newValue in
                    showDropdown = !newValue.isEmpty
                }

            if showDropdown && !matches.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(matches, id: \.id) { entry in
                        Button {
                            breedIds.append(entry.id)
                            displayNames.append(entry.name)
                            query = ""
                            showDropdown = false
                        } label: {
                            Text(entry.name)
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
