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
exports.onPresentOrderCreated = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const statusMappers_1 = require("./statusMappers");
/**
 * Bootstrap canonical order when merchant present_order is created (checkout).
 */
exports.onPresentOrderCreated = (0, firestore_2.onDocumentCreated)({
    document: "markets/{storeId}/present_order/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const storeId = event.params.storeId;
    const orderId = event.params.orderId;
    const data = snap.data();
    const db = (0, firestore_1.getFirestore)();
    const orderRef = db.collection("orders").doc(orderId);
    const existing = await orderRef.get();
    if (existing.exists && (existing.data()?.schemaVersion ?? 0) >= 2) {
        return;
    }
    const legacyStatus = (data.status ?? "pending").toString();
    const lifecycleStatus = (0, statusMappers_1.inferLifecycleFromLegacy)(legacyStatus);
    const delivery = (0, statusMappers_1.defaultDeliveryBlock)();
    const customerStatus = (0, statusMappers_1.computeCustomerStatus)(lifecycleStatus, delivery.assignmentState);
    const now = firestore_1.Timestamp.now();
    const order = {
        orderId,
        storeId,
        userId: (data.userId ?? data.customerInfo?.userId ?? "").toString(),
        lifecycleStatus,
        customerStatus,
        customerStatusUpdatedAt: now,
        placedAt: data.createdAt ?? now,
        lastActivityAt: now,
        escalation: (0, statusMappers_1.defaultEscalationBlock)(),
        delivery,
        customerInfo: data.customerInfo,
        items: data.items,
        subtotal: data.subtotal,
        deliveryFee: data.deliveryFee,
        serviceFee: data.serviceFee,
        totalAmount: data.totalAmount,
        notes: data.notes,
        storeName: data.storeName,
        storeLogo: data.storeLogo,
        legacyStatus: (0, statusMappers_1.lifecycleToLegacyStatus)(lifecycleStatus),
        schemaVersion: 2,
    };
    await orderRef.set(order, { merge: true });
    const eventRef = orderRef.collection("events").doc();
    const placedEvent = {
        id: eventRef.id,
        orderId,
        type: "order.placed",
        actorType: "customer",
        actorId: order.userId || "unknown",
        timestamp: now,
        metadata: { source: "present_order_create" },
        storeId,
        userId: order.userId,
        lifecycleStatusAfter: lifecycleStatus,
        deliveryStateAfter: delivery.assignmentState,
    };
    await eventRef.set(placedEvent);
    await orderRef.update({
        lifecycleStatus: order.lifecycleStatus,
        customerStatus: order.customerStatus,
        legacyStatus: order.legacyStatus,
        schemaVersion: 2,
    });
    await snap.ref.update({
        lifecycleStatus,
        customerStatus,
        legacyStatus: order.legacyStatus,
        schemaVersion: 2,
        lastActivityAt: firestore_1.FieldValue.serverTimestamp(),
    });
    logger.info("Canonical order bootstrapped from present_order", {
        orderId,
        storeId,
    });
});
//# sourceMappingURL=onPresentOrderCreated.js.map