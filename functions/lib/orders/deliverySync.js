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
exports.onDeliveryRequestCreated = exports.onPresentOrderLegacyUpdate = exports.onDeliveryRequestUpdated = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const stateMachine_1 = require("./stateMachine");
const statusMappers_1 = require("./statusMappers");
const OFFICE_STATUS_TO_DELIVERY = {
    pending: "searching",
    accepted: "accepted",
    assigned: "assigned",
    driver_accepted: "accepted",
    picked_up: "picked_up",
    completed: "delivered",
    driver_rejected: "failed",
    customer_rejected: "failed",
    returned_to_merchant: "returned",
    rejected: "failed",
};
/**
 * Sync delivery office status changes into canonical order via transition actions.
 */
exports.onDeliveryRequestUpdated = (0, firestore_2.onDocumentUpdated)({
    document: "request delivery/{requestId}",
    region: "europe-west1",
}, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    const oldStatus = (before.status ?? "").toString();
    const newStatus = (after.status ?? "").toString();
    if (oldStatus === newStatus)
        return;
    const orderDocumentId = (after.orderDocumentId ?? after.orderId ?? "").toString();
    const storeId = (after.marketId ?? "").toString();
    if (!orderDocumentId || !storeId)
        return;
    const db = (0, firestore_1.getFirestore)();
    const orderRef = db.collection("orders").doc(orderDocumentId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists)
        return;
    const order = orderSnap.data();
    const deliveryState = OFFICE_STATUS_TO_DELIVERY[newStatus.toLowerCase()];
    const courierName = (after.driverName ?? after.courierName ?? after.officeName ?? "").toString();
    const courierPhone = (after.driverPhone ?? after.courierPhone ?? after.officePhone ?? "").toString();
    const courierId = (after.driverId ?? after.courierId ?? after.officeId ?? "").toString();
    const updates = {
        "delivery.mode": "delivery_office",
        "delivery.externalRefId": event.params.requestId,
        "delivery.assignmentState": deliveryState ?? newStatus,
        "delivery.currentActor": {
            type: courierId ? "courier" : "office",
            id: courierId || (after.officeId ?? "").toString(),
            name: courierName,
            phone: courierPhone,
        },
        lastActivityAt: firestore_1.Timestamp.now(),
    };
    let action = null;
    if (newStatus === "completed")
        action = "delivery_completed";
    else if (newStatus === "returned_to_merchant" ||
        newStatus === "customer_rejected" ||
        newStatus === "driver_rejected") {
        action = "delivery_returned_to_store";
    }
    else if (newStatus === "picked_up") {
        updates["delivery.assignmentState"] = "picked_up";
    }
    if (action) {
        try {
            const outcome = (0, stateMachine_1.applyAction)(order, action, {
                reason: newStatus,
                externalRefId: event.params.requestId,
                courierName,
                courierPhone,
                courierId,
            });
            const customerStatus = (0, statusMappers_1.computeCustomerStatus)(outcome.lifecycleStatus, updates["delivery.assignmentState"] ??
                order.delivery.assignmentState);
            updates.lifecycleStatus = outcome.lifecycleStatus;
            updates.customerStatus = customerStatus;
            const eventRef = orderRef.collection("events").doc();
            await db.runTransaction(async (tx) => {
                tx.update(orderRef, updates);
                tx.set(eventRef, {
                    id: eventRef.id,
                    orderId: orderDocumentId,
                    type: action === "delivery_completed"
                        ? "delivery.completed"
                        : "delivery.returned_to_store",
                    actorType: "office",
                    actorId: (after.officeId ?? "office").toString(),
                    timestamp: firestore_1.Timestamp.now(),
                    metadata: { deliveryStatus: newStatus, requestId: event.params.requestId },
                    storeId,
                    userId: order.userId,
                    lifecycleStatusAfter: outcome.lifecycleStatus,
                    deliveryStateAfter: updates["delivery.assignmentState"],
                });
            });
        }
        catch (err) {
            logger.warn("Delivery sync action failed", { err, orderDocumentId, newStatus });
            await orderRef.update(updates);
        }
    }
    else {
        const customerStatus = (0, statusMappers_1.computeCustomerStatus)(order.lifecycleStatus, deliveryState ??
            order.delivery.assignmentState);
        updates.customerStatus = customerStatus;
        await orderRef.update(updates);
    }
    logger.info("Delivery request synced to canonical order", {
        orderId: orderDocumentId,
        newStatus,
    });
});
/**
 * Intercept legacy direct present_order status writes and sync to canonical order.
 */
exports.onPresentOrderLegacyUpdate = (0, firestore_2.onDocumentUpdated)({
    document: "markets/{storeId}/present_order/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    if (after.schemaVersion >= 2 && after._projectionSync === true)
        return;
    const oldStatus = (before.status ?? "").toString();
    const newStatus = (after.status ?? "").toString();
    if (oldStatus === newStatus)
        return;
    const orderId = event.params.orderId;
    const storeId = event.params.storeId;
    const db = (0, firestore_1.getFirestore)();
    const orderRef = db.collection("orders").doc(orderId);
    const lifecycle = (0, statusMappers_1.inferLifecycleFromLegacy)(newStatus);
    const customerStatus = (0, statusMappers_1.computeCustomerStatus)(lifecycle, after.delivery?.assignmentState ?? "none");
    await orderRef.set({
        orderId,
        storeId,
        userId: after.userId ?? after.customerInfo?.userId ?? "",
        lifecycleStatus: lifecycle,
        customerStatus,
        legacyStatus: newStatus,
        lastActivityAt: firestore_1.Timestamp.now(),
        schemaVersion: 2,
    }, { merge: true });
    const eventRef = orderRef.collection("events").doc();
    await eventRef.set({
        id: eventRef.id,
        orderId,
        type: "admin.override",
        actorType: "system",
        actorId: "legacy_interceptor",
        timestamp: firestore_1.Timestamp.now(),
        metadata: { oldStatus, newStatus, source: "present_order_legacy" },
        storeId,
        userId: (after.userId ?? after.customerInfo?.userId ?? "").toString(),
        lifecycleStatusAfter: lifecycle,
    });
});
exports.onDeliveryRequestCreated = (0, firestore_2.onDocumentCreated)({
    document: "request delivery/{requestId}",
    region: "europe-west1",
}, async (event) => {
    const data = event.data?.data();
    if (!data)
        return;
    const orderDocumentId = (data.orderDocumentId ?? data.orderId ?? "").toString();
    const storeId = (data.marketId ?? "").toString();
    if (!orderDocumentId || !storeId)
        return;
    const db = (0, firestore_1.getFirestore)();
    await db.collection("orders").doc(orderDocumentId).set({
        "delivery.mode": "delivery_office",
        "delivery.assignmentState": "searching",
        "delivery.externalRefId": event.params.requestId,
        "delivery.currentActor": {
            type: "office",
            id: (data.officeId ?? "").toString(),
            name: (data.officeName ?? "").toString(),
            phone: (data.officePhone ?? "").toString(),
        },
        lastActivityAt: firestore_1.Timestamp.now(),
    }, { merge: true });
});
//# sourceMappingURL=deliverySync.js.map