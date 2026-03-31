import { getBreedTraits } from "../breedTraits";
import { buildRiskProfile } from "../riskProfile";
import type { FirestoreDog } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function baseDog(overrides: Partial<FirestoreDog> = {}): FirestoreDog {
  return {
    id: "dog-1",
    user_id: "user-1",
    name: "Buddy",
    breed_ids: [],
    birth_year: 2020,
    birth_month: 6,
    size: "medium",
    health_conditions: [],
    sensitivities: [],
    is_active: true,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// Breed trait merging
// ---------------------------------------------------------------------------
describe("getBreedTraits", () => {
  it("returns defaults for unknown breed", () => {
    const traits = getBreedTraits(["unknown-breed"]);
    expect(traits.isBrachycephalic).toBe(false);
    expect(traits.coatCategory).toBe("medium");
    expect(traits.isHerding).toBe(false);
  });

  it("returns defaults for empty breed list", () => {
    const traits = getBreedTraits([]);
    expect(traits.coatCategory).toBe("medium");
  });

  it("identifies brachycephalic breed", () => {
    const traits = getBreedTraits(["french-bulldog"]);
    expect(traits.isBrachycephalic).toBe(true);
    expect(traits.coatCategory).toBe("short");
  });

  it("identifies double-coated breed", () => {
    const traits = getBreedTraits(["siberian-husky"]);
    expect(traits.isBrachycephalic).toBe(false);
    expect(traits.coatCategory).toBe("double");
  });

  it("identifies hairless breed", () => {
    const traits = getBreedTraits(["xoloitzcuintli"]);
    expect(traits.coatCategory).toBe("hairless");
  });

  describe("mixed-breed merging", () => {
    it("isBrachycephalic = true if any breed is brachycephalic", () => {
      const traits = getBreedTraits(["french-bulldog", "golden-retriever"]);
      expect(traits.isBrachycephalic).toBe(true);
    });

    it("takes thickest coat across breeds", () => {
      // chihuahua (short) + golden-retriever (double) → double
      const traits = getBreedTraits(["chihuahua", "golden-retriever"]);
      expect(traits.coatCategory).toBe("double");
    });

    it("isHerding = true if any breed is herding", () => {
      const traits = getBreedTraits(["beagle", "border-collie"]);
      expect(traits.isHerding).toBe(true);
    });

    it("hairless + double → double (thickest wins)", () => {
      const traits = getBreedTraits(["chinese-crested", "samoyed"]);
      expect(traits.coatCategory).toBe("double");
    });

    it("unknown + known → known traits", () => {
      const traits = getBreedTraits(["mixed-unknown", "pug"]);
      expect(traits.isBrachycephalic).toBe(true);
    });
  });
});

// ---------------------------------------------------------------------------
// Risk profile — age band derivation
// ---------------------------------------------------------------------------
describe("buildRiskProfile age bands", () => {
  const currentYear = new Date().getFullYear();

  it("classifies puppy when age < 2", () => {
    const profile = buildRiskProfile(baseDog({ birth_year: currentYear - 1 }));
    expect(profile.ageBand).toBe("puppy");
  });

  it("classifies adult for typical age", () => {
    const profile = buildRiskProfile(baseDog({ birth_year: currentYear - 4 }));
    expect(profile.ageBand).toBe("adult");
  });

  it("classifies senior at age 7 for medium dog", () => {
    const profile = buildRiskProfile(baseDog({ birth_year: currentYear - 7 }));
    expect(profile.ageBand).toBe("senior");
  });

  it("classifies senior at age 5 for large dog", () => {
    const profile = buildRiskProfile(
      baseDog({ birth_year: currentYear - 5, size: "large" })
    );
    expect(profile.ageBand).toBe("senior");
  });

  it("classifies senior at age 5 for extra_large dog", () => {
    const profile = buildRiskProfile(
      baseDog({ birth_year: currentYear - 5, size: "extra_large" })
    );
    expect(profile.ageBand).toBe("senior");
  });

  it("classifies adult at age 6 for medium dog (not senior yet)", () => {
    const profile = buildRiskProfile(
      baseDog({ birth_year: currentYear - 6, size: "medium" })
    );
    expect(profile.ageBand).toBe("adult");
  });

  it("defaults to adult when birth_year is null", () => {
    const profile = buildRiskProfile(baseDog({ birth_year: null }));
    expect(profile.ageBand).toBe("adult");
  });
});

// ---------------------------------------------------------------------------
// Risk profile — boolean flags
// ---------------------------------------------------------------------------
describe("buildRiskProfile boolean flags", () => {
  it("sets hasMobilityIssue for arthritis", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["arthritis"] })
    );
    expect(profile.hasMobilityIssue).toBe(true);
  });

  it("sets hasMobilityIssue for hip_issues", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["hip_issues"] })
    );
    expect(profile.hasMobilityIssue).toBe(true);
  });

  it("sets hasMobilityIssue for senior_mobility", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["senior_mobility"] })
    );
    expect(profile.hasMobilityIssue).toBe(true);
  });

  it("sets hasMobilityIssue for recent_surgery", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["recent_surgery"] })
    );
    expect(profile.hasMobilityIssue).toBe(true);
  });

  it("does not set hasMobilityIssue for unrelated conditions", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["heart_condition", "breathing_difficulty"] })
    );
    expect(profile.hasMobilityIssue).toBe(false);
  });

  it("sets hasBreathingIssue for breathing_difficulty", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["breathing_difficulty"] })
    );
    expect(profile.hasBreathingIssue).toBe(true);
  });

  it("sets hasBreathingIssue for brachycephalic breed even without condition", () => {
    const profile = buildRiskProfile(
      baseDog({ breed_ids: ["pug"], health_conditions: [] })
    );
    expect(profile.hasBreathingIssue).toBe(true);
    expect(profile.isBrachycephalic).toBe(true);
  });

  it("sets hasHeartCondition for heart_condition", () => {
    const profile = buildRiskProfile(
      baseDog({ health_conditions: ["heart_condition"] })
    );
    expect(profile.hasHeartCondition).toBe(true);
  });

  it("all flags false for healthy dog with no conditions", () => {
    const profile = buildRiskProfile(baseDog());
    expect(profile.hasMobilityIssue).toBe(false);
    expect(profile.hasBreathingIssue).toBe(false);
    expect(profile.hasHeartCondition).toBe(false);
  });
});
