import { getFirestore } from "firebase-admin/firestore";

/**
 * Returns the initialized Admin Firestore instance (singleton via firebase-admin).
 * Used by generate and attach-weather endpoints.
 */
export function getDb(): FirebaseFirestore.Firestore {
  return getFirestore();
}
