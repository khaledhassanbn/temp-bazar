"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendSupportReplyNotification = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
/**
 * عند إضافة رسالة جديدة من الإدارة في محادثة دعم
 * يتم إرسال إشعار FCM للمستخدم
 */
exports.sendSupportReplyNotification = (0, firestore_1.onDocumentCreated)({
    document: "support_conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
}, async (event) => {
    const messageData = event.data?.data();
    if (!messageData)
        return;
    // فقط رسائل الإدارة
    if (messageData.senderType !== "admin")
        return;
    const conversationId = event.params.conversationId;
    const db = (0, firestore_2.getFirestore)();
    try {
        // جلب بيانات المحادثة
        const conversationDoc = await db
            .collection("support_conversations")
            .doc(conversationId)
            .get();
        if (!conversationDoc.exists)
            return;
        const conversationData = conversationDoc.data();
        const userId = conversationData.userId;
        // جلب FCM token للمستخدم
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            console.log(`User ${userId} does not exist`);
            return;
        }
        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for user ${userId}`);
            return;
        }
        await (0, messaging_1.getMessaging)().send({
            token: fcmToken,
            notification: {
                title: "بازار السويس - الدعم",
                body: "تم الرد على طلب الدعم الخاص بك.",
            },
            data: {
                type: "support_reply",
                conversationId: conversationId,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "support_channel",
                    sound: "default",
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
        });
        console.log(`✅ Support notification sent to user ${userId}`);
    }
    catch (error) {
        console.error(`❌ Error sending support notification:`, error);
    }
});
//# sourceMappingURL=sendSupportNotification.js.map