"use strict";
/**
 * إشعار الطلبات للتاجر — مسار الإنتاج
 *
 * Trigger: مستند جديد في مجموعة `orders` (سجل موحّد للطلبات).
 * مصدر توكن FCM: `stores/{storeId}` أولاً، ثم احتياطي `markets/{storeId}`
 * للتوافق مع التطبيقات القديمة.
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
exports.sendNewOrderNotification = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
async function resolveStoreFcmToken(storeId) {
    const db = (0, firestore_1.getFirestore)();
    const storesSnap = await db.collection("stores").doc(storeId).get();
    const fromStores = storesSnap.data()?.fcmToken;
    if (typeof fromStores === "string" && fromStores.length > 0) {
        return fromStores;
    }
    const marketSnap = await db.collection("markets").doc(storeId).get();
    const fromMarkets = marketSnap.data()?.fcmToken;
    if (typeof fromMarkets === "string" && fromMarkets.length > 0) {
        return fromMarkets;
    }
    return undefined;
}
async function buildOrderProductsPreview(storeId, orderId) {
    const db = (0, firestore_1.getFirestore)();
    try {
        const snap = await db
            .collection("markets")
            .doc(storeId)
            .collection("present_order")
            .doc(orderId)
            .get();
        const data = snap.data();
        const items = data?.items ?? [];
        if (!Array.isArray(items) || items.length === 0)
            return undefined;
        const preview = items.slice(0, 3).map((it) => {
            const name = typeof it?.productName === "string" && it.productName.trim().length > 0 ? it.productName.trim() : "منتج";
            const qty = typeof it?.quantity === "number" ? it.quantity : Number(it?.quantity ?? 1);
            const qtyText = Number.isFinite(qty) && qty > 0 ? String(qty) : "1";
            return `${name} ×${qtyText}`;
        });
        const extra = items.length - preview.length;
        const suffix = extra > 0 ? ` (+${extra})` : "";
        return `المنتجات: ${preview.join("، ")}${suffix}`;
    }
    catch (e) {
        console.log("buildOrderProductsPreview failed:", e);
        return undefined;
    }
}
exports.sendNewOrderNotification = functions.firestore.onDocumentCreated({
    document: "orders/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const orderId = event.params.orderId;
    const orderData = event.data?.data();
    if (!orderData) {
        console.log(`sendNewOrderNotification: no payload for ${orderId}`);
        return;
    }
    const storeId = orderData.storeId;
    if (!storeId) {
        console.log(`sendNewOrderNotification: missing storeId on order ${orderId}`);
        return;
    }
    console.log(`📦 orders/onCreate → notify store=${storeId} order=${orderId}`);
    try {
        const fcmToken = await resolveStoreFcmToken(storeId);
        if (!fcmToken) {
            console.log(`No FCM token for store ${storeId} (stores/markets)`);
            return;
        }
        const dataTitle = "طلب جديد";
        const productsPreview = await buildOrderProductsPreview(storeId, orderId);
        const dataBody = productsPreview ?? "فيه طلب جديد عندك";
        // رسالة بيانات فقط — التطبيق يعرض الإشعار المحلي في الخلفية عبر flutter_local_notifications.
        const message = {
            token: fcmToken,
            data: {
                type: "NEW_ORDER",
                orderId: String(orderId),
                storeId: String(storeId),
                title: dataTitle,
                body: dataBody,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
            },
            apns: {
                payload: {
                    aps: {
                        "content-available": 1,
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        };
        await (0, messaging_1.getMessaging)().send(message);
        console.log(`✅ FCM sent for order ${orderId} → store ${storeId}`);
    }
    catch (error) {
        console.error(`❌ sendNewOrderNotification failed for ${orderId}:`, error);
    }
});
//# sourceMappingURL=sendOrderNotification.js.map