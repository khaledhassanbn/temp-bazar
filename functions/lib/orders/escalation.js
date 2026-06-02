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
exports.checkOrderEscalationsScheduled = void 0;
const firestore_1 = require("firebase-admin/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const logger = __importStar(require("firebase-functions/logger"));
const TERMINAL = new Set(["fulfilled", "cancelled"]);
const THRESHOLDS = [
    { minutes: 30, level: 1, eventType: "escalation.warning_30" },
    { minutes: 45, level: 2, eventType: "escalation.warning_45" },
    { minutes: 60, level: 3, eventType: "escalation.flagged_60" },
    { minutes: 90, level: 4, eventType: "escalation.needs_attention_90" },
];
exports.checkOrderEscalationsScheduled = (0, scheduler_1.onSchedule)({
    schedule: "*/5 * * * *",
    timeZone: "Africa/Cairo",
    region: "europe-west1",
    memory: "512MiB",
}, async () => {
    const db = (0, firestore_1.getFirestore)();
    const now = Date.now();
    const snapshot = await db
        .collection("orders")
        .where("schemaVersion", ">=", 2)
        .limit(500)
        .get();
    let processed = 0;
    for (const doc of snapshot.docs) {
        const data = doc.data();
        const lifecycle = data.lifecycleStatus;
        if (TERMINAL.has(lifecycle))
            continue;
        const lastActivity = data.lastActivityAt ?? data.placedAt ?? data.createdAt;
        if (!lastActivity)
            continue;
        const elapsedMin = (now - lastActivity.toMillis()) / 60000;
        const currentLevel = (data.escalation?.level ?? 0);
        for (const threshold of THRESHOLDS) {
            if (elapsedMin >= threshold.minutes && currentLevel < threshold.level) {
                await emitEscalation(db, doc.id, data, threshold);
                processed++;
                break;
            }
        }
    }
    logger.info("Escalation check completed", { scanned: snapshot.size, processed });
});
async function emitEscalation(db, orderId, orderData, threshold) {
    const orderRef = db.collection("orders").doc(orderId);
    const eventRef = orderRef.collection("events").doc();
    const now = firestore_1.Timestamp.now();
    const event = {
        id: eventRef.id,
        orderId,
        type: threshold.eventType,
        actorType: "system",
        actorId: "escalation_cron",
        timestamp: now,
        metadata: { minutes: threshold.minutes },
        storeId: orderData.storeId ?? "",
        userId: orderData.userId ?? "",
        lifecycleStatusAfter: orderData.lifecycleStatus,
        deliveryStateAfter: orderData.delivery?.assignmentState,
    };
    const escalationUpdate = {
        "escalation.level": threshold.level,
        lastActivityAt: now,
    };
    if (threshold.level === 1)
        escalationUpdate["escalation.warning30At"] = now;
    if (threshold.level === 2)
        escalationUpdate["escalation.warning45At"] = now;
    if (threshold.level === 3)
        escalationUpdate["escalation.flagged60At"] = now;
    if (threshold.level === 4) {
        escalationUpdate["escalation.needsAttentionAt"] = now;
        await db.collection("admin_attention").doc(orderId).set({
            orderId,
            storeId: orderData.storeId ?? "",
            userId: orderData.userId ?? "",
            reason: "stuck_90min",
            priority: "critical",
            lifecycleStatus: orderData.lifecycleStatus ?? "",
            deliveryState: orderData.delivery?.assignmentState ?? "",
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            resolvedAt: null,
        }, { merge: true });
    }
    await db.runTransaction(async (tx) => {
        tx.update(orderRef, escalationUpdate);
        tx.set(eventRef, event);
    });
}
//# sourceMappingURL=escalation.js.map