import type { WeatherEntry, HourlyEntry, ForecastResponse } from "../weather/types";

// Re-export weather types for convenience within this module.
export type { WeatherEntry, HourlyEntry, ForecastResponse };

/** Walk safety tier — higher is more restrictive. */
export enum RecommendationLevel {
  optimal = 0,
  normal_walk = 1,
  short_walk = 2,
  very_short_walk = 3,
  bathroom_only = 4,
  do_not_walk = 5,
}

/** Human-readable key for each level. */
export function levelToKey(level: RecommendationLevel): string {
  return RecommendationLevel[level];
}

/** Suggested max walk duration in minutes for each level. null = no limit or zero. */
export function levelToMaxDuration(level: RecommendationLevel): number | null {
  switch (level) {
    case RecommendationLevel.optimal:
      return null;
    case RecommendationLevel.normal_walk:
      return null;
    case RecommendationLevel.short_walk:
      return 20;
    case RecommendationLevel.very_short_walk:
      return 10;
    case RecommendationLevel.bathroom_only:
      return 5;
    case RecommendationLevel.do_not_walk:
      return 0;
  }
}

/** Dog risk profile derived from Firestore doc + breed traits. */
export interface DogRiskProfile {
  ageBand: "puppy" | "adult" | "senior";
  size: string;
  healthConditions: string[];
  sensitivities: string[];
  isBrachycephalic: boolean;
  coatCategory: "hairless" | "short" | "medium" | "double";
  hasMobilityIssue: boolean;
  hasBreathingIssue: boolean;
  hasHeartCondition: boolean;
}

/** Result from a single hard-stop evaluator. */
export interface HardStopResult {
  ceiling: RecommendationLevel | null;
  reason: string;
  evaluator: string;
  humidityApplied: boolean;
}

/** Result from a modifier group. */
export interface ModifierResult {
  escalatedTo: RecommendationLevel;
  reason: string;
}

/** Recommendation for a single dog at a single point in time. */
export interface DogRecommendation {
  dogId: string;
  dogName: string;
  level: number;
  levelKey: string;
  maxDurationMin: number | null;
  reasons: string[];
  hardStopReasons: string[];
  modifierReasons: string[];
}

/** Hourly recommendation (simplified — no per-dog breakdown). */
export interface HourlyRecommendation {
  local_timestamp: string;
  level: number;
  levelKey: string;
  reasons: string[];
}

/** Per-dog entry in the response. */
export interface DogRecommendationEntry {
  dogId: string;
  dogName: string;
  current: DogRecommendation;
  hourly: HourlyRecommendation[];
}

/** Household-level recommendation (most restrictive across dogs). */
export interface HouseholdRecommendation {
  current: DogRecommendation;
  hourly: HourlyRecommendation[];
}

/** A walk slot from the user's walking schedule. */
export interface WalkSlot {
  preferred_time: string;      // "HH:mm"
  duration_minutes: number;
  walk_order: number;
}

/** Firestore walking_schedules document shape. */
export interface FirestoreWalkingSchedule {
  id: string;
  user_id: string;
  schedule_type: "weekday" | "weekend";
  walks_per_day: number;
  slots: WalkSlot[];
}

/** A scheduled walk recommendation in the response. */
export interface ScheduledWalkRecommendation {
  preferred_time: string;       // original "HH:mm"
  local_timestamp: string;      // full ISO 8601 with offset for the actual date+time
  day_label: string;            // "Today", "Tomorrow", or weekday name
  schedule_type: string;        // "weekday" or "weekend"
  duration_minutes: number;
  recommendation: DogRecommendation;  // household-level (most restrictive across dogs)
}

/** Full response from POST /walkRecommendation. */
export interface RecommendationResponse {
  dogs: DogRecommendationEntry[];
  household: HouseholdRecommendation;
  scheduled_walks: ScheduledWalkRecommendation[];
  generated_at: string;
}

/** Server-side Firestore dog document shape (snake_case keys). */
export interface FirestoreDog {
  id: string;
  user_id: string;
  name: string;
  breed_ids: string[];
  birth_year: number | null;
  birth_month: number | null;
  size: string;
  health_conditions: string[];
  sensitivities: string[];
  is_active: boolean;
}
