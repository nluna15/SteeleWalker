import SwiftUI

struct Step1DogFormView: View {
    @Binding var dog: DogDraft
    let index: Int
    @State private var showAgeConflict: Bool = false

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

            // Age
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.subheadline.weight(.medium))
                TextField("Age in years", text: $dog.ageText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .disabled(dog.isUnderOneYear)
                    .opacity(dog.isUnderOneYear ? 0.5 : 1)
                    .onChange(of: dog.ageText) { _, _ in
                        dog.isUnderOneYear = false
                        showAgeConflict = false
                    }
                Button {
                    if dog.ageText.isEmpty {
                        dog.isUnderOneYear.toggle()
                        showAgeConflict = false
                    } else {
                        if !dog.isUnderOneYear {
                            showAgeConflict = true
                        } else {
                            dog.isUnderOneYear = false
                        }
                    }
                } label: {
                    Text("Less than 1 year")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(dog.isUnderOneYear ? Color.accentColor : Color.secondary.opacity(0.15))
                        .foregroundStyle(dog.isUnderOneYear ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                if showAgeConflict {
                    Text("Clear the age field first")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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

            // Weather Sensitivities
            VStack(alignment: .leading, spacing: 8) {
                Text("Weather Sensitivities")
                    .font(.subheadline.weight(.medium))
                Text("Any weather your dog is sensitive to?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    // "None" option
                    Button {
                        dog.sensitivities.removeAll()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: dog.sensitivities.isEmpty ? "checkmark.square.fill" : "square")
                                .foregroundStyle(dog.sensitivities.isEmpty ? Color.accentColor : Color.secondary)
                            Text("None")
                                .foregroundStyle(.primary)
                                .font(.subheadline)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    ForEach(DogSensitivity.allCases, id: \.self) { sensitivity in
                        Button {
                            if dog.sensitivities.contains(sensitivity) {
                                dog.sensitivities.remove(sensitivity)
                            } else {
                                dog.sensitivities.insert(sensitivity)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: dog.sensitivities.contains(sensitivity) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(dog.sensitivities.contains(sensitivity) ? Color.accentColor : Color.secondary)
                                Image(systemName: sensitivity.systemImage)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 20)
                                Text(sensitivity.displayName)
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
