"use strict";
/**
 * إرسال إشعار للتاجر عند وصول طلب جديد
 * Trigger: إضافة document جديد في present_order
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
exports.sendNewOrderNotification = functions.firestore.onDocumentCreated({
    document: "markets/{storeId}/present_order/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const storeId = event.params.storeId;
    const orderId = event.params.orderId;
    const orderData = event.data?.data();
    if (!orderData) {
        console.log(`No order data for order ${orderId}`);
        return;
    }
    console.log(`📦 New order created: ${orderId} for store ${storeId}`);
    try {
        // جلب FCM token من بيانات المتجر
        const storeDoc = await (0, firestore_1.getFirestore)()
            .collection("markets")
            .doc(storeId)
            .get();
        if (!storeDoc.exists) {
            console.log(`Store ${storeId} not found`);
            return;
        }
        const storeData = storeDoc.data();
        const fcmToken = storeData?.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for store ${storeId}`);
            return;
        }
        // حساب إجمالي الطلب
        const totalAmount = orderData.totalAmount || 0;
        const itemsCount = orderData.items?.length || 0;
        const message = {
            token: fcmToken,
            notification: {
                title: "🛒 طلب جديد!",
                body: `لديك طلب جديد رقم ${orderId} - ${itemsCount} منتجات بقيمة ${totalAmount} ج.م`,
            },
            data: {
                type: "new_order",
                orderId: orderId,
                storeId: storeId,
                totalAmount: totalAmount.toString(),
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId: "orders",
                    icon: "notification_icon",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        };
        await (0, messaging_1.getMessaging)().send(message);
        console.log(`✅ New order notification sent to store ${storeId} for order ${orderId}`);
    }
    catch (error) {
        console.error(`❌ Error sending notification for order ${orderId}:`, error);
    }
});
//# sourceMappingURL=sendOrderNotification.js.map