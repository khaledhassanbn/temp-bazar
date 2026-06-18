import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * عند إضافة رسالة جديدة من الإدارة في محادثة دعم
 * يتم إرسال إشعار FCM للمستخدم
 */
export const sendSupportReplyNotification = onDocumentCreated(
  {
    document: "support_conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // فقط رسائل الإدارة
    if (messageData.senderType !== "admin") return;

    const conversationId = event.params.conversationId;
    const db = getFirestore();
    
    try {
      // جلب بيانات المحادثة
      const conversationDoc = await db
        .collection("support_conversations")
        .doc(conversationId)
        .get();
      
      if (!conversationDoc.exists) return;
      
      const conversationData = conversationDoc.data()!;
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

      await getMessaging().send({
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
    } catch (error) {
      console.error(`❌ Error sending support notification:`, error);
    }
  }
);
