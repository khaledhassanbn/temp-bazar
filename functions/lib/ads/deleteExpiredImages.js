"use strict";
/**
 * Cloud Function to delete images of expired ads
 *
 * This function:
 * - Fetches all ads from Firestore
 * - Identifies expired ads (not valid)
 * - Deletes their images from Firebase Storage
 * - Updates ads to remove image URLs
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
exports.deleteExpiredAdsImages = deleteExpiredAdsImages;
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
// Ensure Admin SDK is initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
/**
 * Check if an ad is expired (not valid)
 */
function isAdExpired(ad) {
    // Ad is expired if:
    // 1. Not active
    // 2. Active but no image
    // 3. Active but no startTime
    // 4. Active but expired based on duration
    if (!ad.isActive || !ad.imageUrl || !ad.startTime) {
        return !ad.isActive && ad.imageUrl != null && ad.imageUrl.length > 0;
    }
    const startTime = ad.startTime.toDate();
    const expiryTime = new Date(startTime.getTime() + ad.durationHours * 60 * 60 * 1000);
    const now = new Date();
    return now >= expiryTime;
}
/**
 * Delete image from Firebase Storage
 */
async function deleteImageFromStorage(imageUrl) {
    try {
        // Extract the path from the URL
        // URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
        const url = new URL(imageUrl);
        const pathMatch = url.pathname.match(/\/o\/(.+)\?/);
        if (!pathMatch) {
            logger.warn(`Could not extract path from URL: ${imageUrl}`);
            return false;
        }
        const encodedPath = pathMatch[1];
        const decodedPath = decodeURIComponent(encodedPath);
        const bucket = admin.storage().bucket();
        const file = bucket.file(decodedPath);
        const [exists] = await file.exists();
        if (!exists) {
            logger.warn(`File does not exist: ${decodedPath}`);
            return false;
        }
        await file.delete();
        logger.info(`Deleted image: ${decodedPath}`);
        return true;
    }
    catch (error) {
        logger.error(`Error deleting image ${imageUrl}:`, error);
        return false;
    }
}
/**
 * Main function to delete expired ads images
 */
async function deleteExpiredAdsImages(event) {
    logger.info("deleteExpiredAdsImages: Starting scheduled check");
    try {
        // Fetch ads document
        const adsDoc = await db.collection("app_settings").doc("home_ads").get();
        if (!adsDoc.exists) {
            logger.info("deleteExpiredAdsImages: No ads document found");
            return;
        }
        const data = adsDoc.data();
        if (!data || !data.ads || !Array.isArray(data.ads)) {
            logger.info("deleteExpiredAdsImages: No ads array found");
            return;
        }
        const ads = data.ads;
        let deletedCount = 0;
        let updatedCount = 0;
        // Filter expired ads
        const expiredAds = ads.filter((ad) => isAdExpired(ad));
        logger.info(`deleteExpiredAdsImages: Found ${expiredAds.length} expired ads`);
        // Process each expired ad
        for (const ad of expiredAds) {
            if (!ad.imageUrl || ad.imageUrl.length === 0) {
                continue;
            }
            try {
                // Delete image from Storage
                const deleted = await deleteImageFromStorage(ad.imageUrl);
                if (deleted) {
                    deletedCount++;
                }
                // Update ad to remove image URL
                const adIndex = ads.findIndex((a) => a.slotId === ad.slotId);
                if (adIndex !== -1) {
                    ads[adIndex] = {
                        ...ads[adIndex],
                        imageUrl: null,
                    };
                    updatedCount++;
                }
            }
            catch (error) {
                logger.error(`Error processing ad ${ad.slotId}:`, error);
                // Continue processing other ads
            }
        }
        // Update Firestore if any ads were updated
        if (updatedCount > 0) {
            await db.collection("app_settings").doc("home_ads").set({
                ads: ads,
                updatedAt: firestore_1.Timestamp.now(),
            }, { merge: true });
            logger.info(`deleteExpiredAdsImages: Updated ${updatedCount} ads in Firestore`);
        }
        logger.info("deleteExpiredAdsImages: Completed", {
            totalExpired: expiredAds.length,
            imagesDeleted: deletedCount,
            adsUpdated: updatedCount,
        });
    }
    catch (error) {
        logger.error("deleteExpiredAdsImages: Error occurred", { error });
        throw error;
    }
}
//# sourceMappingURL=deleteExpiredImages.js.map