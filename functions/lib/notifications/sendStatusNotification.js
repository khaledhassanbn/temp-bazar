"use strict";
/**
 * إرسال إشعارات عند تغيير حالة الطلب
 * Trigger: تحديث document في present_order
 *
 * الحالات المشمولة (جميع الحالات المحتملة بالعربية والإنجليزية)
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
exports.sendPastOrderNotification = exports.sendOrderStatusNotification = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
// جميع الحالات التي نريد إرسال إشعارات عنها
const STATUS_NOTIFICATIONS = {
    // ============================================================
    // إشعارات للتاجر عند قبول الطلب من المكتب
    // ============================================================
    "accepted": {
        title: "تم قبول الطلب",
        body: "تم قبول طلبك رقم {orderId} من مكتب التوصيل وسيتم تعيين مندوب قريباً",
        target: "store",
        emoji: "✅",
    },
    "تم قبوله من المكتب": {
        title: "تم قبول الطلب",
        body: "تم قبول طلبك رقم {orderId} من مكتب التوصيل وسيتم تعيين مندوب قريباً",
        target: "store",
        emoji: "✅",
    },
    "تم استلام الطلب": {
        title: "تم استلام الطلب",
        body: "طلبك رقم {orderId} تم استلامه وسيتم تجهيزه قريباً",
        target: "store",
        emoji: "✅",
    },
    // ============================================================
    // إشعارات للتاجر عند رفض الطلب من المكتب
    // ============================================================
    "rejected": {
        title: "تم رفض الطلب",
        body: "للأسف، تم رفض طلبك رقم {orderId} من مكتب التوصيل",
        target: "store",
        emoji: "❌",
    },
    "تم رفض الطلب": {
        title: "تم رفض الطلب",
        body: "للأسف، تم رفض طلبك رقم {orderId} من مكتب التوصيل",
        target: "store",
        emoji: "❌",
    },
    "تم رفض الطلب من المكتب": {
        title: "تم رفض الطلب",
        body: "للأسف، تم رفض طلبك رقم {orderId} من مكتب التوصيل",
        target: "store",
        emoji: "❌",
    },
    // ============================================================
    // إشعارات للعميل عند التسليم
    // ============================================================
    "completed": {
        title: "تم تسليم طلبك!",
        body: "تم تسليم طلبك رقم {orderId} بنجاح. شكراً لثقتك!",
        target: "user",
        emoji: "🎉",
    },
    "الطلب مكتمل": {
        title: "تم تسليم طلبك!",
        body: "تم تسليم طلبك رقم {orderId} بنجاح. شكراً لثقتك!",
        target: "user",
        emoji: "🎉",
    },
    "تم التسليم للطيار": {
        title: "تم تسليم طلبك!",
        body: "تم تسليم طلبك رقم {orderId} بنجاح. شكراً لثقتك!",
        target: "user",
        emoji: "🎉",
    },
    "تم التسليم": {
        title: "تم تسليم طلبك!",
        body: "تم تسليم طلبك رقم {orderId} بنجاح. شكراً لثقتك!",
        target: "user",
        emoji: "🎉",
    },
};
exports.sendOrderStatusNotification = functions.firestore.onDocumentUpdated({
    document: "markets/{storeId}/present_order/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) {
        console.log("Missing before or after data");
        return;
    }
    const oldStatus = beforeData.status;
    const newStatus = afterData.status;
    // لا إشعار إذا لم تتغير الحالة
    if (oldStatus === newStatus) {
        return;
    }
    console.log(`📊 Order status changed: "${oldStatus}" → "${newStatus}"`);
    // تحقق إذا كانت الحالة الجديدة من الحالات المشمولة
    const config = STATUS_NOTIFICATIONS[newStatus];
    if (!config) {
        console.log(`ℹ️ Status "${newStatus}" not configured for notifications - skipping`);
        return;
    }
    const storeId = event.params.storeId;
    const orderId = event.params.orderId;
    const displayOrderId = afterData.orderId || orderId;
    console.log(`🔔 Sending notification for status: ${newStatus}, target: ${config.target}`);
    try {
        let fcmToken;
        if (config.target === "store") {
            // جلب توكن المتجر
            console.log(`📍 Fetching store token for: ${storeId}`);
            const storeDoc = await (0, firestore_1.getFirestore)()
                .collection("markets")
                .doc(storeId)
                .get();
            if (storeDoc.exists) {
                const storeData = storeDoc.data();
                fcmToken = storeData?.fcmToken;
                console.log(`🏪 Store FCM token: ${fcmToken ? fcmToken.substring(0, 20) + "..." : "NOT FOUND"}`);
            }
            else {
                console.log(`❌ Store document not found: ${storeId}`);
            }
        }
        else if (config.target === "user") {
            // جلب توكن العميل
            const userId = afterData.userId || afterData.customerInfo?.userId;
            console.log(`📍 Fetching user token for userId: ${userId}`);
            if (userId) {
                const userDoc = await (0, firestore_1.getFirestore)()
                    .collection("users")
                    .doc(userId)
                    .get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    fcmToken = userData?.fcmToken;
                    console.log(`👤 User FCM token: ${fcmToken ? fcmToken.substring(0, 20) + "..." : "NOT FOUND"}`);
                }
                else {
                    console.log(`❌ User document not found: ${userId}`);
                }
            }
            else {
                console.log(`❌ No userId in order data`);
            }
        }
        if (!fcmToken) {
            console.log(`❌ No FCM token available for ${config.target} - cannot send notification`);
            return;
        }
        // استبدال المتغيرات في النص
        const body = config.body.replace("{orderId}", displayOrderId);
        console.log(`📤 Sending notification: "${config.emoji} ${config.title}" - "${body}"`);
        const message = {
            token: fcmToken,
            notification: {
                title: `${config.emoji} ${config.title}`,
                body: body,
            },
            data: {
                type: "order_status",
                status: newStatus,
                orderId: orderId,
                displayOrderId: displayOrderId,
                storeId: storeId,
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
        const response = await (0, messaging_1.getMessaging)().send(message);
        console.log(`✅ Notification sent successfully! Response: ${response}`);
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`❌ Error sending notification: ${errorMessage}`);
        // طباعة تفاصيل أكثر للخطأ
        if (error instanceof Error && error.stack) {
            console.error(`Stack: ${error.stack}`);
        }
    }
});
/**
 * إشعار إضافي للتعامل مع الطلبات المنتقلة إلى past_order
 */
exports.sendPastOrderNotification = functions.firestore.onDocumentCreated({
    document: "markets/{storeId}/past_order/{orderId}",
    region: "europe-west1",
}, async (event) => {
    const orderData = event.data?.data();
    if (!orderData)
        return;
    const status = orderData.status;
    const storeId = event.params.storeId;
    const orderId = event.params.orderId;
    const displayOrderId = orderData.orderId || orderId;
    console.log(`📦 Past order created: ${displayOrderId}, status: "${status}"`);
    // الحالات التي تعني التسليم الناجح (إشعار للعميل)
    const completedStatuses = [
        "completed",
        "الطلب مكتمل",
        "تم التسليم",
        "تم التسليم للطيار",
    ];
    // الحالات التي تعني الرفض (إشعار للتاجر)
    const rejectedStatuses = [
        "rejected",
        "تم رفض الطلب",
        "تم رفض الطلب من المكتب",
        "المندوب رفض الطلب",
    ];
    // 1️⃣ التعامل مع التسليم الناجح (للعميل)
    if (completedStatuses.includes(status)) {
        const userId = orderData.userId || orderData.customerInfo?.userId;
        if (!userId) {
            console.log("❌ No userId found in order - cannot send notification");
            return;
        }
        try {
            const userDoc = await (0, firestore_1.getFirestore)()
                .collection("users")
                .doc(userId)
                .get();
            if (!userDoc.exists) {
                console.log(`❌ User ${userId} not found`);
                return;
            }
            const fcmToken = userDoc.data()?.fcmToken;
            if (!fcmToken) {
                console.log(`❌ No FCM token for user ${userId}`);
                return;
            }
            const message = {
                token: fcmToken,
                notification: {
                    title: "🎉 تم تسليم طلبك!",
                    body: `تم تسليم طلبك رقم ${displayOrderId} بنجاح. شكراً لثقتك!`,
                },
                data: {
                    type: "order_completed",
                    orderId: orderId,
                    displayOrderId: displayOrderId,
                    storeId: storeId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "orders",
                    },
                },
            };
            const response = await (0, messaging_1.getMessaging)().send(message);
            console.log(`✅ Completion notification sent! Response: ${response}`);
        }
        catch (error) {
            console.error(`❌ Error sending completion notification:`, error);
        }
        return;
    }
    // 2️⃣ التعامل مع الرفض (للتاجر)
    if (rejectedStatuses.includes(status)) {
        console.log(`⚠️ Order rejected in past_order. Sending notification to store...`);
        try {
            const storeDoc = await (0, firestore_1.getFirestore)()
                .collection("markets")
                .doc(storeId)
                .get();
            if (!storeDoc.exists) {
                console.log(`❌ Store ${storeId} not found`);
                return;
            }
            const fcmToken = storeDoc.data()?.fcmToken;
            if (!fcmToken) {
                console.log(`❌ No FCM token for store ${storeId}`);
                return;
            }
            const message = {
                token: fcmToken,
                notification: {
                    title: "❌ تم رفض الطلب",
                    body: `للأسف، تم رفض طلبك رقم ${displayOrderId} من مكتب التوصيل`,
                },
                data: {
                    type: "order_rejected",
                    orderId: orderId,
                    displayOrderId: displayOrderId,
                    storeId: storeId,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "orders",
                    },
                },
            };
            const response = await (0, messaging_1.getMessaging)().send(message);
            console.log(`✅ Rejection notification sent to store! Response: ${response}`);
        }
        catch (error) {
            console.error(`❌ Error sending rejection notification:`, error);
        }
        return;
    }
    console.log(`ℹ️ Status "${status}" handling not required in past_order`);
});
//# sourceMappingURL=sendStatusNotification.js.map