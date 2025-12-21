"use strict";
/**
 * Package Management Functions (Admin Only)
 *
 * CRUD operations for subscription packages:
 * - createPackage: Create a new package
 * - updatePackage: Update an existing package
 * - deletePackage: Delete a package
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPackage = createPackage;
exports.updatePackage = updatePackage;
exports.deletePackage = deletePackage;
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("../utils/auth");
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
async function createPackage(request) {
    try {
        // Log authentication info for debugging
        logger.info("createPackage: Request received", {
            uid: request.auth?.uid,
            hasAuth: !!request.auth,
        });
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { name, days, price, features, orderIndex } = request.data;
        // Validate input
        if (!name || typeof name !== "string" || name.trim().length === 0) {
            throw new https_1.HttpsError("invalid-argument", "name is required and must be a non-empty string");
        }
        if (!days || typeof days !== "number" || days <= 0) {
            throw new https_1.HttpsError("invalid-argument", "days is required and must be a positive number");
        }
        if (!price || typeof price !== "number" || price < 0) {
            throw new https_1.HttpsError("invalid-argument", "price is required and must be a non-negative number");
        }
        if (!Array.isArray(features) || features.length === 0) {
            throw new https_1.HttpsError("invalid-argument", "features is required and must be a non-empty array");
        }
        // Validate features array contains only strings
        if (!features.every((f) => typeof f === "string" && f.trim().length > 0)) {
            throw new https_1.HttpsError("invalid-argument", "All features must be non-empty strings");
        }
        const packageData = {
            name: name.trim(),
            days: Math.floor(days),
            price: Math.max(0, price),
            features: features.map((f) => f.trim()).filter((f) => f.length > 0),
            orderIndex: typeof orderIndex === "number" ? Math.floor(orderIndex) : 0,
            createdAt: firestore_1.Timestamp.now(),
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("createPackage: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to create package");
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
async function updatePackage(request) {
    try {
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { packageId, name, days, price, features, orderIndex } = request.data;
        if (!packageId || typeof packageId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "packageId is required and must be a string");
        }
        // Check if package exists
        const packageRef = db.collection("packages").doc(packageId);
        const packageDoc = await packageRef.get();
        if (!packageDoc.exists) {
            throw new https_1.HttpsError("not-found", "Package not found");
        }
        // Build update object
        const updateData = {};
        if (name !== undefined) {
            if (typeof name !== "string" || name.trim().length === 0) {
                throw new https_1.HttpsError("invalid-argument", "name must be a non-empty string");
            }
            updateData.name = name.trim();
        }
        if (days !== undefined) {
            if (typeof days !== "number" || days <= 0) {
                throw new https_1.HttpsError("invalid-argument", "days must be a positive number");
            }
            updateData.days = Math.floor(days);
        }
        if (price !== undefined) {
            if (typeof price !== "number" || price < 0) {
                throw new https_1.HttpsError("invalid-argument", "price must be a non-negative number");
            }
            updateData.price = Math.max(0, price);
        }
        if (features !== undefined) {
            if (!Array.isArray(features) || features.length === 0) {
                throw new https_1.HttpsError("invalid-argument", "features must be a non-empty array");
            }
            if (!features.every((f) => typeof f === "string" && f.trim().length > 0)) {
                throw new https_1.HttpsError("invalid-argument", "All features must be non-empty strings");
            }
            updateData.features = features.map((f) => f.trim()).filter((f) => f.length > 0);
        }
        if (orderIndex !== undefined) {
            if (typeof orderIndex !== "number") {
                throw new https_1.HttpsError("invalid-argument", "orderIndex must be a number");
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
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("updatePackage: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to update package");
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
async function deletePackage(request) {
    try {
        // Verify admin access
        await (0, auth_1.verifyAdmin)(request.auth?.uid);
        const { packageId } = request.data;
        if (!packageId || typeof packageId !== "string") {
            throw new https_1.HttpsError("invalid-argument", "packageId is required and must be a string");
        }
        // Check if package exists
        const packageRef = db.collection("packages").doc(packageId);
        const packageDoc = await packageRef.get();
        if (!packageDoc.exists) {
            throw new https_1.HttpsError("not-found", "Package not found");
        }
        // Delete package
        await packageRef.delete();
        logger.info("deletePackage: Package deleted", { packageId });
        return { message: "Package deleted successfully" };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error("deletePackage: Unexpected error", { error });
        throw new https_1.HttpsError("internal", "Failed to delete package");
    }
}
//# sourceMappingURL=crud.js.map