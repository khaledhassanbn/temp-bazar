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
exports.syncProjections = syncProjections;
exports.updateOrderIndexNotificationStatus = updateOrderIndexNotificationStatus;
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const statusMappers_1 = require("./statusMappers");
async function syncProjections(db, orderId, order, options) {
    const legacyStatus = (0, statusMappers_1.lifecycleToLegacyStatus)(order.lifecycleStatus);
    const customerStatus = order.customerStatus;
    const customerStatusAr = (0, statusMappers_1.customerStatusArabic)(customerStatus);
    const now = firestore_1.FieldValue.serverTimestamp();
    const courier = order.delivery?.currentActor;
    const courierFields = courier && courier.name
        ? {
            currentCourierName: courier.name,
            currentCourierPhone: courier.phone ?? "",
            currentCourierId: courier.id ?? "",
        }
        : {};
    const projectionFields = {
        lifecycleStatus: order.lifecycleStatus,
        customerStatus,
        customerStatusArabic: customerStatusAr,
        legacyStatus,
        status: legacyStatus,
        updatedAt: now,
        lastActivityAt: now,
        delivery: order.delivery,
        escalation: order.escalation,
        schemaVersion: order.schemaVersion ?? 2,
        _projectionSync: true,
        ...courierFields,
    };
    const storeId = order.storeId;
    const userId = order.userId;
    if (options.moveToPast && isTerminalLifecycle(order.lifecycleStatus)) {
        await moveToPastOrder(db, storeId, orderId, order, projectionFields);
    }
    else {
        const presentRef = db
            .collection("markets")
            .doc(storeId)
            .collection("present_order")
            .doc(orderId);
        const presentSnap = await presentRef.get();
        if (presentSnap.exists) {
            await presentRef.update(projectionFields);
        }
        else {
            await presentRef.set({
                orderId,
                storeId,
                userId,
                createdAt: order.placedAt ?? firestore_1.FieldValue.serverTimestamp(),
                ...projectionFields,
                customerInfo: order.customerInfo ?? {},
                items: order.items ?? [],
                subtotal: order.subtotal ?? 0,
                deliveryFee: order.deliveryFee ?? 0,
                serviceFee: order.serviceFee ?? 0,
                totalAmount: order.totalAmount ?? 0,
                notes: order.notes ?? "",
            }, { merge: true });
        }
    }
    if (userId) {
        const userOrderRef = db
            .collection("users")
            .doc(userId)
            .collection("orders")
            .doc(orderId);
        const userFields = {
            ...projectionFields,
            status: customerStatusAr,
        };
        if (options.moveToPast && order.lifecycleStatus === "fulfilled") {
            userFields.completedAt = now;
        }
        if (options.moveToPast && order.lifecycleStatus === "cancelled") {
            userFields.completedAt = now;
        }
        const userSnap = await userOrderRef.get();
        if (userSnap.exists) {
            await userOrderRef.update(userFields);
        }
        else {
            await userOrderRef.set({
                orderId,
                storeId,
                userId,
                createdAt: order.placedAt ?? firestore_1.FieldValue.serverTimestamp(),
                ...userFields,
                customerInfo: order.customerInfo ?? {},
                items: order.items ?? [],
                totalAmount: order.totalAmount ?? 0,
            }, { merge: true });
        }
    }
    logger.info("Projections synced", {
        orderId,
        lifecycle: order.lifecycleStatus,
        customerStatus,
        moveToPast: options.moveToPast,
    });
}
async function moveToPastOrder(db, storeId, orderId, order, projectionFields) {
    const presentRef = db
        .collection("markets")
        .doc(storeId)
        .collection("present_order")
        .doc(orderId);
    const presentSnap = await presentRef.get();
    const baseData = presentSnap.exists
        ? (presentSnap.data() ?? {})
        : {
            orderId,
            storeId,
            userId: order.userId,
            customerInfo: order.customerInfo ?? {},
            items: order.items ?? [],
            subtotal: order.subtotal ?? 0,
            deliveryFee: order.deliveryFee ?? 0,
            serviceFee: order.serviceFee ?? 0,
            totalAmount: order.totalAmount ?? 0,
            createdAt: order.placedAt ?? firestore_1.Timestamp.now(),
        };
    const pastData = {
        ...baseData,
        ...projectionFields,
        completedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    const pastRef = db
        .collection("markets")
        .doc(storeId)
        .collection("past_order")
        .doc(orderId);
    await pastRef.set(pastData, { merge: true });
    if (presentSnap.exists) {
        await presentRef.delete();
    }
}
function isTerminalLifecycle(status) {
    return status === "fulfilled" || status === "cancelled";
}
async function updateOrderIndexNotificationStatus(db, orderId, status) {
    const indexRef = db.collection("orders").doc(orderId);
    const snap = await indexRef.get();
    if (snap.exists) {
        await indexRef.update({
            status,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
}
//# sourceMappingURL=projectionSync.js.map