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
exports.orderTransitionCallable = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const auth_1 = require("../utils/auth");
const stateMachine_1 = require("./stateMachine");
const projectionSync_1 = require("./projectionSync");
const statusMappers_1 = require("./statusMappers");
function resolveActorType(action, uid, isAdmin) {
    if (isAdmin && action === "admin_override") {
        return { actorType: "admin", actorId: uid };
    }
    if (action.startsWith("delivery_") &&
        action !== "delivery_mode_office" &&
        action !== "delivery_mode_independent" &&
        action !== "delivery_mode_self") {
        return { actorType: "system", actorId: "system" };
    }
    return { actorType: "merchant", actorId: uid };
}
async function isUserAdmin(db, uid) {
    try {
        await (0, auth_1.verifyAdmin)(uid);
        return true;
    }
    catch {
        return false;
    }
}
async function loadOrBootstrapOrder(db, orderId, storeId) {
    const orderRef = db.collection("orders").doc(orderId);
    const snap = await orderRef.get();
    if (snap.exists) {
        return snap.data();
    }
    const presentSnap = await db
        .collection("markets")
        .doc(storeId)
        .collection("present_order")
        .doc(orderId)
        .get();
    if (!presentSnap.exists) {
        throw new https_1.HttpsError("not-found", `Order ${orderId} not found`);
    }
    const data = presentSnap.data() ?? {};
    const legacyStatus = (data.status ?? "pending").toString();
    const lifecycleStatus = (0, statusMappers_1.inferLifecycleFromLegacy)(legacyStatus);
    const delivery = (0, statusMappers_1.defaultDeliveryBlock)();
    const customerStatus = (0, statusMappers_1.computeCustomerStatus)(lifecycleStatus, delivery.assignmentState);
    const order = {
        orderId,
        storeId,
        userId: (data.userId ?? data.customerInfo?.userId ?? "").toString(),
        lifecycleStatus,
        customerStatus,
        placedAt: data.createdAt ?? firestore_1.Timestamp.now(),
        lastActivityAt: firestore_1.Timestamp.now(),
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
    return order;
}
exports.orderTransitionCallable = (0, https_1.onCall)({
    region: "europe-west1",
    memory: "512MiB",
}, async (request) => {
    const uid = await (0, auth_1.verifyAuth)(request.auth?.uid);
    const data = request.data;
    if (!data.orderId || !data.storeId) {
        throw new https_1.HttpsError("invalid-argument", "orderId and storeId are required");
    }
    let action = data.action;
    if (!action && data.legacyArabicStatus) {
        const mapped = (0, stateMachine_1.mapLegacyArabicStatusToAction)(data.legacyArabicStatus);
        if (!mapped) {
            throw new https_1.HttpsError("invalid-argument", `Unknown legacy status: ${data.legacyArabicStatus}`);
        }
        action = mapped;
    }
    if (!action) {
        throw new https_1.HttpsError("invalid-argument", "action is required");
    }
    const db = (0, firestore_1.getFirestore)();
    const adminUser = await isUserAdmin(db, uid);
    if (action === "admin_override") {
        await (0, auth_1.verifyAdmin)(uid);
    }
    else {
        const storeDoc = await db.collection("markets").doc(data.storeId).get();
        if (!storeDoc.exists) {
            throw new https_1.HttpsError("not-found", "Store not found");
        }
        const ownerUid = storeDoc.data()?.ownerUid;
        await (0, auth_1.verifyStoreOwner)(uid, ownerUid);
    }
    const idempotencyKey = data.idempotencyKey ?? `${data.orderId}:${action}:${Date.now()}`;
    const processedRef = db
        .collection("orders")
        .doc(data.orderId)
        .collection("processed_keys")
        .doc(idempotencyKey);
    const processedSnap = await processedRef.get();
    if (processedSnap.exists) {
        const cached = processedSnap.data()?.result;
        if (cached)
            return cached;
    }
    const order = await loadOrBootstrapOrder(db, data.orderId, data.storeId);
    // «تم رفض الطلب» يُستخدم للرفض (pending) أو الإلغاء (أي حالة أخرى)
    if (action === "merchant_reject" && order.lifecycleStatus !== "pending") {
        action = "merchant_cancel";
    }
    const payload = data.payload ?? {};
    const outcome = (0, stateMachine_1.applyAction)(order, action, payload);
    const now = firestore_1.Timestamp.now();
    const delivery = { ...order.delivery };
    if (outcome.deliveryMode) {
        delivery.mode = outcome.deliveryMode;
    }
    if (outcome.deliveryState) {
        delivery.assignmentState = outcome.deliveryState;
    }
    if (payload.externalRefId) {
        delivery.externalRefId = payload.externalRefId;
    }
    if (payload.courierName || payload.courierPhone) {
        delivery.currentActor = {
            type: payload.courierType ?? "courier",
            id: payload.courierId ?? null,
            name: payload.courierName ?? "",
            phone: payload.courierPhone ?? "",
        };
    }
    if (action === "delivery_failed" || action === "delivery_returned_to_store") {
        delivery.failureCount = (delivery.failureCount ?? 0) + 1;
        if (payload.reason) {
            delivery.lastFailureReason = payload.reason;
        }
    }
    const customerStatus = (0, statusMappers_1.computeCustomerStatus)(outcome.lifecycleStatus, delivery.assignmentState);
    const updatedOrder = {
        ...order,
        lifecycleStatus: outcome.lifecycleStatus,
        customerStatus,
        customerStatusUpdatedAt: now,
        lastActivityAt: now,
        delivery,
        legacyStatus: (0, statusMappers_1.lifecycleToLegacyStatus)(outcome.lifecycleStatus),
        escalation: {
            ...order.escalation,
            level: 0,
        },
    };
    if (outcome.lifecycleStatus === "accepted" && !order.merchantAcceptedAt) {
        updatedOrder.merchantAcceptedAt = now;
    }
    if (outcome.lifecycleStatus === "ready_for_handoff") {
        updatedOrder.readyAt = now;
    }
    if (outcome.lifecycleStatus === "fulfilled") {
        updatedOrder.fulfilledAt = now;
    }
    if (outcome.lifecycleStatus === "cancelled") {
        updatedOrder.cancelledAt = now;
    }
    const { actorType, actorId } = resolveActorType(action, uid, adminUser);
    const eventRef = db
        .collection("orders")
        .doc(data.orderId)
        .collection("events")
        .doc();
    const event = {
        id: eventRef.id,
        orderId: data.orderId,
        type: outcome.eventType,
        actorType,
        actorId,
        timestamp: now,
        metadata: {
            action,
            previousLifecycle: order.lifecycleStatus,
            payload,
            clientVersion: data.clientVersion ?? "2",
        },
        storeId: data.storeId,
        userId: order.userId,
        lifecycleStatusAfter: outcome.lifecycleStatus,
        deliveryStateAfter: delivery.assignmentState,
    };
    const orderRef = db.collection("orders").doc(data.orderId);
    await db.runTransaction(async (tx) => {
        tx.set(orderRef, updatedOrder, { merge: true });
        tx.set(eventRef, event);
        tx.set(processedRef, {
            action,
            processedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    await (0, projectionSync_1.syncProjections)(db, data.orderId, updatedOrder, {
        moveToPast: outcome.moveToPast,
    });
    const result = {
        success: true,
        orderId: data.orderId,
        lifecycleStatus: outcome.lifecycleStatus,
        customerStatus,
        eventId: eventRef.id,
        legacyStatus: updatedOrder.legacyStatus ?? (0, statusMappers_1.lifecycleToLegacyStatus)(outcome.lifecycleStatus),
    };
    await processedRef.update({ result });
    logger.info("Order transition completed", {
        orderId: data.orderId,
        action,
        lifecycle: outcome.lifecycleStatus,
        eventId: eventRef.id,
    });
    return result;
});
//# sourceMappingURL=orderTransition.js.map