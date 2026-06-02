"use strict";
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
exports.updateCompletionRate = updateCompletionRate;
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const ENGAGEMENT_EVENTS = new Set([
    "order.merchant_accepted",
    "delivery.accepted",
    "order.placed",
]);
const COMPLETED_EVENTS = new Set(["order.fulfilled", "delivery.completed"]);
const FAILED_EVENTS = new Set(["delivery.failed", "delivery.returned_to_store"]);
const CANCELLED_EVENTS = new Set([
    "order.cancelled",
    "order.merchant_rejected",
]);
async function updateCompletionRate(event) {
    const db = (0, firestore_1.getFirestore)();
    const orderDoc = await db.collection("orders").doc(event.orderId).get();
    if (!orderDoc.exists)
        return;
    const storeId = event.storeId;
    const userId = event.userId;
    const updates = [];
    if (storeId) {
        updates.push(adjustRate(db.collection("markets").doc(storeId).collection("metrics").doc("completion"), event.type));
    }
    if (userId) {
        updates.push(adjustRate(db.collection("users").doc(userId).collection("metrics").doc("completion"), event.type));
    }
    const courierId = event.metadata.courierId;
    if (courierId) {
        updates.push(adjustRate(db.collection("courier_requests").doc(courierId).collection("metrics").doc("completion"), event.type));
    }
    await Promise.all(updates);
    await db
        .collection("orders")
        .doc(event.orderId)
        .collection("events")
        .doc()
        .set({
        type: "completion.rate_adjusted",
        orderId: event.orderId,
        actorType: "system",
        actorId: "system",
        timestamp: firestore_1.Timestamp.now(),
        metadata: { triggeredBy: event.type },
        storeId,
        userId,
    });
    logger.info("Completion rates updated", { orderId: event.orderId });
}
async function adjustRate(ref, eventType) {
    await applyIncrement(ref, eventType);
}
async function applyIncrement(ref, eventType) {
    const inc = {
        lastUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    if (ENGAGEMENT_EVENTS.has(eventType)) {
        inc.totalEngaged = firestore_1.FieldValue.increment(1);
    }
    if (COMPLETED_EVENTS.has(eventType)) {
        inc.totalCompleted = firestore_1.FieldValue.increment(1);
    }
    if (FAILED_EVENTS.has(eventType)) {
        inc.totalFailed = firestore_1.FieldValue.increment(1);
    }
    if (CANCELLED_EVENTS.has(eventType)) {
        inc.totalCancelled = firestore_1.FieldValue.increment(1);
    }
    if (Object.keys(inc).length <= 1)
        return;
    await ref.set(inc, { merge: true });
}
//# sourceMappingURL=completionRate.js.map