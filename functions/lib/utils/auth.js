"use strict";
/**
 * Authentication and authorization utilities
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
exports.verifyAuth = verifyAuth;
exports.verifyAdmin = verifyAdmin;
exports.verifyStoreOwner = verifyStoreOwner;
const https_1 = require("firebase-functions/v2/https");
const auth_1 = require("firebase-admin/auth");
const logger = __importStar(require("firebase-functions/logger"));
/**
 * Verifies that the user is authenticated
 */
async function verifyAuth(uid) {
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    return uid;
}
/**
 * Verifies that the user is an admin
 * Checks both customClaims and Firestore user document (status field)
 */
async function verifyAdmin(uid) {
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    // Get Firestore instance
    const { getFirestore } = require("firebase-admin/firestore");
    const db = getFirestore();
    // First check customClaims (if set)
    const auth = (0, auth_1.getAuth)();
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
        }
        else {
            logger.warn("verifyAdmin: User document not found", { uid });
        }
    }
    catch (error) {
        logger.error("verifyAdmin: Error checking Firestore", { uid, error });
    }
    // User is not admin
    logger.warn("verifyAdmin: User is not admin", {
        uid,
        customClaims,
    });
    throw new https_1.HttpsError("permission-denied", "Only admins can perform this action");
}
/**
 * Verifies that the user owns the store or is an admin
 */
async function verifyStoreOwner(uid, storeOwnerUid) {
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    // Allow if user is admin
    try {
        await verifyAdmin(uid);
        return;
    }
    catch {
        // Not admin, check if owner
    }
    if (uid !== storeOwnerUid) {
        throw new https_1.HttpsError("permission-denied", "User does not own this store");
    }
}
//# sourceMappingURL=auth.js.map