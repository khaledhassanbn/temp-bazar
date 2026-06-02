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
exports.onOrderEventCreated = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const notificationEngine_1 = require("./notificationEngine");
const completionRate_1 = require("./completionRate");
async function indexAdminAttention(event) {
    const attentionTypes = [
        "escalation.needs_attention_90",
        "delivery.failed",
        "delivery.returned_to_store",
        "admin.override",
    ];
    if (!attentionTypes.includes(event.type))
        return;
    const db = (0, firestore_1.getFirestore)();
    const reason = event.type === "escalation.needs_attention_90"
        ? "stuck_90min"
        : event.type === "delivery.failed"
            ? "delivery_failed"
            : event.type === "delivery.returned_to_store"
                ? "delivery_failed"
                : "manual_flag";
    await db.collection("admin_attention").doc(event.orderId).set({
        orderId: event.orderId,
        storeId: event.storeId,
        userId: event.userId,
        reason,
        priority: event.type === "escalation.needs_attention_90" ? "critical" : "high",
        lifecycleStatus: event.lifecycleStatusAfter ?? "",
        deliveryState: event.deliveryStateAfter ?? "",
        lastEventType: event.type,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        resolvedAt: null,
    }, { merge: true });
}
exports.onOrderEventCreated = (0, firestore_2.onDocumentCreated)({
    document: "orders/{orderId}/events/{eventId}",
    region: "europe-west1",
}, async (firestoreEvent) => {
    const snap = firestoreEvent.data;
    if (!snap)
        return;
    const event = snap.data();
    event.id = firestoreEvent.params.eventId;
    event.orderId = firestoreEvent.params.orderId;
    logger.info("Processing order event", {
        orderId: event.orderId,
        type: event.type,
    });
    await (0, notificationEngine_1.processEventNotifications)(event);
    await indexAdminAttention(event);
    const terminalEvents = [
        "order.fulfilled",
        "delivery.completed",
        "order.cancelled",
        "order.merchant_rejected",
        "delivery.failed",
    ];
    if (terminalEvents.includes(event.type)) {
        try {
            await (0, completionRate_1.updateCompletionRate)(event);
        }
        catch (err) {
            logger.error("Completion rate update failed", { err });
        }
    }
});
//# sourceMappingURL=onOrderEventCreated.js.map