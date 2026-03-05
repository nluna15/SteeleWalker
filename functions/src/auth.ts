import { getAuth } from "firebase-admin/auth";

/**
 * Verifies a Firebase ID token from an Authorization header.
 * Returns the decoded uid on success; throws an error object
 * with { status: 401, message } if the token is missing or invalid.
 */
export async function verifyToken(
  authHeader: string | undefined
): Promise<string> {
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw { status: 401, message: "Missing or malformed Authorization header" };
  }

  const token = authHeader.slice(7);

  try {
    const decoded = await getAuth().verifyIdToken(token);
    return decoded.uid;
  } catch {
    throw { status: 401, message: "Invalid or expired token" };
  }
}
