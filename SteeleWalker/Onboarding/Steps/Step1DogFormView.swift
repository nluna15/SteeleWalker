import SwiftUI

struct Step1DogFormView: View {
    @Binding var dog: DogDraft
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if index > 0 {
                Text("Dog \(index + 1)")
                    .font(.headline)
            }

            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.subheadline.weight(.medium))
                TextField("e.g. Buddy", text: $dog.name)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            // Breed
            VStack(alignment: .leading, spacing: 6) {
                Text("Breed")
                    .font(.subheadline.weight(.medium))
                BreedSearchField(
                    label: "Search breeds…",
                    breedIds: $dog.breedIds,
                    displayNames: $dog.breedDisplayNames
                )
            }

            // Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Size")
                    .font(.subheadline.weight(.medium))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DogSize.allCases, id: \.self) { size in
                            Button {
                                dog.size = size
                            } label: {
                                VStack(spacing: 2) {
                                    Text(size.displayName)
                                        .font(.footnote.weight(.medium))
                                    Text(size.weightRange)
                                        .font(.caption2)
                                        .opacity(0.85)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(dog.size == size ? Color.accentColor : Color.secondary.opacity(0.15))
                                .foregroundStyle(dog.size == size ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Age range
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.subheadline.weight(.medium))
                Picker("Age", selection: $dog.ageRange) {
                    ForEach(DogAgeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Mobility
            VStack(alignment: .leading, spacing: 8) {
                Text("Mobility")
                    .font(.subheadline.weight(.medium))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(DogMobility.allCases, id: \.self) { option in
                        Button {
                            var updated = dog.mobilities
                            if option == .noRestrictions {
                                updated = updated.contains(.noRestrictions) ? [] : [.noRestrictions]
                            } else {
                                updated.remove(.noRestrictions)
                                if updated.contains(option) {
                                    updated.remove(option)
                                } else {
                                    updated.insert(option)
                                }
                            }
                            dog.mobilities = updated
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: dog.mobilities.contains(option) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(dog.mobilities.contains(option) ? Color.accentColor : Color.secondary)
                                Text(option.displayName)
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if dog.mobilities.contains(.other) {
                    TextField("Describe the condition…", text: $dog.mobilityNote)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
