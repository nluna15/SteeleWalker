/** Breed-specific traits that affect weather sensitivity. */
export interface BreedTraits {
  isBrachycephalic: boolean;
  coatCategory: "hairless" | "short" | "medium" | "double";
  isHerding: boolean;
}

const DEFAULT_TRAITS: BreedTraits = {
  isBrachycephalic: false,
  coatCategory: "medium",
  isHerding: false,
};

/**
 * Sparse dictionary — only breeds that deviate from defaults.
 * Keys match slug IDs from BreedSeed.swift (e.g. "french-bulldog").
 */
const BREED_OVERRIDES: Record<string, Partial<BreedTraits>> = {
  // Brachycephalic breeds
  "bulldog": { isBrachycephalic: true, coatCategory: "short" },
  "french-bulldog": { isBrachycephalic: true, coatCategory: "short" },
  "pug": { isBrachycephalic: true, coatCategory: "short" },
  "boston-terrier": { isBrachycephalic: true, coatCategory: "short" },
  "boxer": { isBrachycephalic: true, coatCategory: "short" },
  "shih-tzu": { isBrachycephalic: true, coatCategory: "double" },
  "pekingese": { isBrachycephalic: true, coatCategory: "double" },
  "cavalier-king-charles": { isBrachycephalic: true, coatCategory: "medium" },
  "lhasa-apso": { isBrachycephalic: true, coatCategory: "double" },
  "affenpinscher": { isBrachycephalic: true, coatCategory: "medium" },
  "brussels-griffon": { isBrachycephalic: true, coatCategory: "medium" },
  "japanese-chin": { isBrachycephalic: true, coatCategory: "medium" },
  "english-toy-spaniel": { isBrachycephalic: true, coatCategory: "medium" },
  "bullmastiff": { isBrachycephalic: true, coatCategory: "short" },
  "dogue-de-bordeaux": { isBrachycephalic: true, coatCategory: "short" },

  // Double-coated breeds
  "siberian-husky": { coatCategory: "double" },
  "alaskan-malamute": { coatCategory: "double" },
  "samoyed": { coatCategory: "double" },
  "golden-retriever": { coatCategory: "double" },
  "labrador-retriever": { coatCategory: "double" },
  "german-shepherd": { coatCategory: "double", isHerding: true },
  "australian-shepherd": { coatCategory: "double", isHerding: true },
  "border-collie": { coatCategory: "double", isHerding: true },
  "shetland-sheepdog": { coatCategory: "double", isHerding: true },
  "bernese-mountain-dog": { coatCategory: "double" },
  "great-pyrenees": { coatCategory: "double" },
  "newfoundland": { coatCategory: "double" },
  "saint-bernard": { coatCategory: "double" },
  "akita": { coatCategory: "double" },
  "chow-chow": { coatCategory: "double" },
  "pomeranian": { coatCategory: "double" },
  "corgi": { coatCategory: "double", isHerding: true },
  "keeshond": { coatCategory: "double" },

  // Short-coated breeds
  "greyhound": { coatCategory: "short" },
  "whippet": { coatCategory: "short" },
  "italian-greyhound": { coatCategory: "short" },
  "doberman-pinscher": { coatCategory: "short" },
  "vizsla": { coatCategory: "short" },
  "weimaraner": { coatCategory: "short" },
  "great-dane": { coatCategory: "short" },
  "dalmatian": { coatCategory: "short" },
  "basenji": { coatCategory: "short" },
  "miniature-pinscher": { coatCategory: "short" },
  "rhodesian-ridgeback": { coatCategory: "short" },
  "pit-bull": { coatCategory: "short" },
  "staffordshire-bull-terrier": { coatCategory: "short" },
  "american-staffordshire": { coatCategory: "short" },
  "chihuahua": { coatCategory: "short" },
  "dachshund": { coatCategory: "short" },
  "beagle": { coatCategory: "short" },

  // Hairless breeds
  "xoloitzcuintli": { coatCategory: "hairless" },
  "chinese-crested": { coatCategory: "hairless" },
  "american-hairless-terrier": { coatCategory: "hairless" },

  // Herding breeds (not already listed)
  "belgian-malinois": { isHerding: true },
  "rough-collie": { coatCategory: "double", isHerding: true },
  "old-english-sheepdog": { coatCategory: "double", isHerding: true },
};

const COAT_RANK: Record<string, number> = {
  hairless: 0,
  short: 1,
  medium: 2,
  double: 3,
};

/**
 * Merge breed traits for a dog with multiple breed IDs.
 * - isBrachycephalic: true if ANY breed is brachycephalic
 * - coatCategory: thickest coat wins
 * - isHerding: true if ANY breed is herding
 */
export function getBreedTraits(breedIds: string[]): BreedTraits {
  if (!breedIds.length) return { ...DEFAULT_TRAITS };

  let isBrachycephalic = false;
  let coatCategory: BreedTraits["coatCategory"] | null = null;
  let isHerding = false;

  for (const id of breedIds) {
    const overrides = BREED_OVERRIDES[id];
    if (!overrides) continue;

    if (overrides.isBrachycephalic) isBrachycephalic = true;
    if (overrides.isHerding) isHerding = true;
    if (overrides.coatCategory) {
      if (coatCategory === null || COAT_RANK[overrides.coatCategory] > COAT_RANK[coatCategory]) {
        coatCategory = overrides.coatCategory;
      }
    }
  }

  // Fall back to default if no breed had a coat override
  if (coatCategory === null) coatCategory = DEFAULT_TRAITS.coatCategory;

  return { isBrachycephalic, coatCategory, isHerding };
}
