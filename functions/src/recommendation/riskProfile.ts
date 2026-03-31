import type { DogRiskProfile, FirestoreDog } from "./types";
import { getBreedTraits } from "./breedTraits";

const MOBILITY_CONDITIONS = new Set([
  "arthritis",
  "hip_issues",
  "senior_mobility",
  "recent_surgery",
]);

/**
 * Builds a DogRiskProfile from a Firestore dog document.
 * Pure function — no I/O.
 */
export function buildRiskProfile(dog: FirestoreDog): DogRiskProfile {
  const traits = getBreedTraits(dog.breed_ids);

  // Age band
  const currentYear = new Date().getFullYear();
  let ageBand: DogRiskProfile["ageBand"] = "adult";
  if (dog.birth_year != null) {
    const age = currentYear - dog.birth_year;
    if (age < 2) {
      ageBand = "puppy";
    } else {
      const isLargeOrXL = dog.size === "large" || dog.size === "extra_large";
      if (age >= (isLargeOrXL ? 5 : 7)) {
        ageBand = "senior";
      }
    }
  }

  // Boolean flags from health conditions
  const conditions = new Set(dog.health_conditions);
  const hasMobilityIssue = dog.health_conditions.some((c) =>
    MOBILITY_CONDITIONS.has(c)
  );
  const hasBreathingIssue =
    conditions.has("breathing_difficulty") || traits.isBrachycephalic;
  const hasHeartCondition = conditions.has("heart_condition");

  return {
    ageBand,
    size: dog.size,
    healthConditions: dog.health_conditions,
    sensitivities: dog.sensitivities,
    isBrachycephalic: traits.isBrachycephalic,
    coatCategory: traits.coatCategory,
    hasMobilityIssue,
    hasBreathingIssue,
    hasHeartCondition,
  };
}
