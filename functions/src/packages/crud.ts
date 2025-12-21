/**
 * Package Management Functions (Admin Only)
 * 
 * CRUD operations for subscription packages:
 * - createPackage: Create a new package
 * - updatePackage: Update an existing package
 * - deletePackage: Delete a package
 */

import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { verifyAdmin } from "../utils/auth";
import { Package } from "../types";

// Ensure Admin SDK is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Creates a new subscription package
 * 
 * Request data:
 * {
 *   name: string
 *   days: number
 *   price: number
 *   features: string[]
 *   orderIndex: number (optional, defaults to 0)
 * }
 */
export async function createPackage(
  request: CallableRequest
): Promise<{ packageId: string; message: string }> {
  try {
    // Log authentication info for debugging
    logger.info("createPackage: Request received", {
      uid: request.auth?.uid,
      hasAuth: !!request.auth,
    });

    // Verify admin access
    await verifyAdmin(request.auth?.uid);

    const { name, days, price, features, orderIndex } = request.data;

    // Validate input
    if (!name || typeof name !== "string" || name.trim().length === 0) {
      throw new HttpsError("invalid-argument", "name is required and must be a non-empty string");
    }

    if (!days || typeof days !== "number" || days <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "days is required and must be a positive number"
      );
    }

    if (!price || typeof price !== "number" || price < 0) {
      throw new HttpsError(
        "invalid-argument",
        "price is required and must be a non-negative number"
      );
    }

    if (!Array.isArray(features) || features.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "features is required and must be a non-empty array"
      );
    }

    // Validate features array contains only strings
    if (!features.every((f) => typeof f === "string" && f.trim().length > 0)) {
      throw new HttpsError(
        "invalid-argument",
        "All features must be non-empty strings"
      );
    }

    const packageData: Omit<Package, "createdAt"> & { createdAt: Timestamp } = {
      name: name.trim(),
      days: Math.floor(days),
      price: Math.max(0, price),
      features: features.map((f: string) => f.trim()).filter((f: string) => f.length > 0),
      orderIndex: typeof orderIndex === "number" ? Math.floor(orderIndex) : 0,
      createdAt: Timestamp.now(),
    };

    // Create package document
    const packageRef = await db.collection("packages").add(packageData);

    logger.info("createPackage: Package created", {
      packageId: packageRef.id,
      name: packageData.name,
    });

    return {
      packageId: packageRef.id,
      message: "Package created successfully",
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("createPackage: Unexpected error", { error });
    throw new HttpsError("internal", "Failed to create package");
  }
}

/**
 * Updates an existing subscription package
 * 
 * Request data:
 * {
 *   packageId: string
 *   name?: string
 *   days?: number
 *   price?: number
 *   features?: string[]
 *   orderIndex?: number
 * }
 */
export async function updatePackage(
  request: CallableRequest
): Promise<{ message: string }> {
  try {
    // Verify admin access
    await verifyAdmin(request.auth?.uid);

    const { packageId, name, days, price, features, orderIndex } = request.data;

    if (!packageId || typeof packageId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "packageId is required and must be a string"
      );
    }

    // Check if package exists
    const packageRef = db.collection("packages").doc(packageId);
    const packageDoc = await packageRef.get();

    if (!packageDoc.exists) {
      throw new HttpsError("not-found", "Package not found");
    }

    // Build update object
    const updateData: Partial<Package> = {};

    if (name !== undefined) {
      if (typeof name !== "string" || name.trim().length === 0) {
        throw new HttpsError(
          "invalid-argument",
          "name must be a non-empty string"
        );
      }
      updateData.name = name.trim();
    }

    if (days !== undefined) {
      if (typeof days !== "number" || days <= 0) {
        throw new HttpsError(
          "invalid-argument",
          "days must be a positive number"
        );
      }
      updateData.days = Math.floor(days);
    }

    if (price !== undefined) {
      if (typeof price !== "number" || price < 0) {
        throw new HttpsError(
          "invalid-argument",
          "price must be a non-negative number"
        );
      }
      updateData.price = Math.max(0, price);
    }

    if (features !== undefined) {
      if (!Array.isArray(features) || features.length === 0) {
        throw new HttpsError(
          "invalid-argument",
          "features must be a non-empty array"
        );
      }
      if (!features.every((f) => typeof f === "string" && f.trim().length > 0)) {
        throw new HttpsError(
          "invalid-argument",
          "All features must be non-empty strings"
        );
      }
      updateData.features = features.map((f: string) => f.trim()).filter((f: string) => f.length > 0);
    }

    if (orderIndex !== undefined) {
      if (typeof orderIndex !== "number") {
        throw new HttpsError(
          "invalid-argument",
          "orderIndex must be a number"
        );
      }
      updateData.orderIndex = Math.floor(orderIndex);
    }

    // Update package
    await packageRef.update(updateData);

    logger.info("updatePackage: Package updated", {
      packageId,
      updatedFields: Object.keys(updateData),
    });

    return { message: "Package updated successfully" };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("updatePackage: Unexpected error", { error });
    throw new HttpsError("internal", "Failed to update package");
  }
}

/**
 * Deletes a subscription package
 * 
 * Request data:
 * {
 *   packageId: string
 * }
 */
export async function deletePackage(
  request: CallableRequest
): Promise<{ message: string }> {
  try {
    // Verify admin access
    await verifyAdmin(request.auth?.uid);

    const { packageId } = request.data;

    if (!packageId || typeof packageId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "packageId is required and must be a string"
      );
    }

    // Check if package exists
    const packageRef = db.collection("packages").doc(packageId);
    const packageDoc = await packageRef.get();

    if (!packageDoc.exists) {
      throw new HttpsError("not-found", "Package not found");
    }

    // Delete package
    await packageRef.delete();

    logger.info("deletePackage: Package deleted", { packageId });

    return { message: "Package deleted successfully" };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("deletePackage: Unexpected error", { error });
    throw new HttpsError("internal", "Failed to delete package");
  }
}

