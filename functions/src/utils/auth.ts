/**
 * Authentication and authorization utilities
 */

import { HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import * as logger from "firebase-functions/logger";

/**
 * Verifies that the user is authenticated
 */
export async function verifyAuth(uid: string | undefined): Promise<string> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  return uid;
}

/**
 * Verifies that the user is an admin
 * Checks both customClaims and Firestore user document (status field)
 */
export async function verifyAdmin(uid: string | undefined): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Get Firestore instance
  const { getFirestore } = require("firebase-admin/firestore");
  const db = getFirestore();

  // First check customClaims (if set)
  const auth = getAuth();
  const user = await auth.getUser(uid);
  const customClaims = user.customClaims || {};

  // Check customClaims first
  if (customClaims.role === "admin" || customClaims.userStatus === "admin") {
    logger.info("verifyAdmin: User is admin (customClaims)", { uid });
    return;
  }

  // If not in customClaims, check Firestore user document
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      const status = userData?.status || userData?.userStatus;
      
      logger.info("verifyAdmin: Checking Firestore", {
        uid,
        status,
        userData: userData ? Object.keys(userData) : null,
      });

      if (status === "admin") {
        logger.info("verifyAdmin: User is admin (Firestore)", { uid });
        return;
      }
    } else {
      logger.warn("verifyAdmin: User document not found", { uid });
    }
  } catch (error) {
    logger.error("verifyAdmin: Error checking Firestore", { uid, error });
  }

  // User is not admin
  logger.warn("verifyAdmin: User is not admin", {
    uid,
    customClaims,
  });
  
  throw new HttpsError(
    "permission-denied",
    "Only admins can perform this action"
  );
}

/**
 * Verifies that the user owns the store or is an admin
 */
export async function verifyStoreOwner(
  uid: string | undefined,
  storeOwnerUid: string
): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Allow if user is admin
  try {
    await verifyAdmin(uid);
    return;
  } catch {
    // Not admin, check if owner
  }

  if (uid !== storeOwnerUid) {
    throw new HttpsError(
      "permission-denied",
      "User does not own this store"
    );
  }
}

