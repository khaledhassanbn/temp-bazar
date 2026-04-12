"use strict";
/**
 * Cloud Function: updateStoreOpenStatus
 *
 * تشتغل كل 15 دقيقة وتحدّث حقل `isOpenNow` لكل متجر
 * بناءً على مواعيد العمل (workingHours) المحفوظة في Firestore.
 *
 * الحقول اللي بتتحدّث:
 *   - isOpenNow: boolean — هل المتجر مفتوح دلوقتي؟
 *   - lastOpenStatusUpdate: Timestamp — آخر مرة اتحدّث الحقل ده
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
exports.updateStoreOpenStatus = updateStoreOpenStatus;
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
// ══════════════════════════════════════════════════════════════════════════════
// Helper: map JS weekday to Arabic day name
// ══════════════════════════════════════════════════════════════════════════════
/**
 * JavaScript Date.getDay() returns 0 (Sunday) – 6 (Saturday).
 * We map to Arabic names matching the Flutter WeeklyWorkingHours model.
 */
const WEEKDAY_AR = {
    0: "الأحد",
    1: "الاثنين",
    2: "الثلاثاء",
    3: "الأربعاء",
    4: "الخميس",
    5: "الجمعة",
    6: "السبت",
};
// ══════════════════════════════════════════════════════════════════════════════
// Helper: check if a time string (HH:mm) is within a range
// ══════════════════════════════════════════════════════════════════════════════
function isTimeInRange(currentTime, openTime, closeTime) {
    // Normal range (e.g. 09:00 – 18:00)
    if (openTime <= closeTime) {
        return currentTime >= openTime && currentTime <= closeTime;
    }
    // Overnight range (e.g. 22:00 – 02:00)
    return currentTime >= openTime || currentTime <= closeTime;
}
// ══════════════════════════════════════════════════════════════════════════════
// Core logic: determine if a store is open NOW
// ══════════════════════════════════════════════════════════════════════════════
function isStoreOpenNow(wh, now) {
    // لو مفيش مواعيد عمل — يعتبر مفتوح دائماً
    if (!wh)
        return true;
    // لو isAlwaysOpen = true
    if (wh.isAlwaysOpen)
        return true;
    // لو مفيش workingHours array
    if (!wh.workingHours || wh.workingHours.length === 0)
        return true;
    const dayName = WEEKDAY_AR[now.getDay()];
    const dayEntry = wh.workingHours.find((d) => d.dayOfWeek === dayName);
    // لو اليوم مش موجود أو مغلق — المتجر مغلق
    if (!dayEntry || !dayEntry.isOpen)
        return false;
    // لو مفيش openTime/closeTime — يعتبر مفتوح
    if (!dayEntry.openTime || !dayEntry.closeTime)
        return true;
    const currentTime = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
    // التحقق من أن الوقت الحالي داخل ساعات العمل
    if (!isTimeInRange(currentTime, dayEntry.openTime, dayEntry.closeTime)) {
        return false;
    }
    // التحقق من الاستراحة
    if (dayEntry.hasBreak &&
        dayEntry.breakStartTime &&
        dayEntry.breakEndTime) {
        if (isTimeInRange(currentTime, dayEntry.breakStartTime, dayEntry.breakEndTime)) {
            return false; // في وقت الاستراحة
        }
    }
    return true;
}
// ══════════════════════════════════════════════════════════════════════════════
// Exported handler (will be wired-up as a scheduled function in index.ts)
// ══════════════════════════════════════════════════════════════════════════════
async function updateStoreOpenStatus() {
    const db = (0, firestore_1.getFirestore)();
    // الوقت الحالي بتوقيت مصر (Africa/Cairo = UTC+2 or UTC+3 in DST)
    const now = new Date(new Date().toLocaleString("en-US", { timeZone: "Africa/Cairo" }));
    logger.info(`updateStoreOpenStatus: Running at ${now.toISOString()} (Cairo time)`);
    try {
        // جلب كل المتاجر النشطة (active و isVisible)
        const snapshot = await db
            .collection("markets")
            .where("status", "==", "active")
            .get();
        if (snapshot.empty) {
            logger.info("updateStoreOpenStatus: No active markets found");
            return;
        }
        // Batch update (max 500 per batch)
        const batches = [];
        let currentBatch = db.batch();
        let operationCount = 0;
        let updatedCount = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const wh = data.workingHours;
            const currentIsOpenNow = data.isOpenNow;
            const newIsOpenNow = isStoreOpenNow(wh, now);
            // فقط نحدّث لو القيمة اتغيرت (أو أول مرة)
            if (currentIsOpenNow !== newIsOpenNow) {
                currentBatch.update(doc.ref, {
                    isOpenNow: newIsOpenNow,
                    lastOpenStatusUpdate: firestore_1.Timestamp.now(),
                });
                operationCount++;
                updatedCount++;
                // Firestore batch limit = 500
                if (operationCount >= 500) {
                    batches.push(currentBatch);
                    currentBatch = db.batch();
                    operationCount = 0;
                }
            }
        }
        // Commit remaining operations
        if (operationCount > 0) {
            batches.push(currentBatch);
        }
        // Execute all batches
        for (const batch of batches) {
            await batch.commit();
        }
        logger.info(`updateStoreOpenStatus: Checked ${snapshot.size} markets, updated ${updatedCount}`);
    }
    catch (error) {
        logger.error("updateStoreOpenStatus failed", { error });
        throw error;
    }
}
//# sourceMappingURL=updateStoreOpenStatus.js.map