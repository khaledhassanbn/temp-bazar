/**
 * إرسال إشعار للتاجر عند وصول طلب جديد
 * Trigger: إضافة document جديد في present_order
 */

import * as functions from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const sendNewOrderNotification = functions.firestore.onDocumentCreated(
    {
        document: "markets/{storeId}/present_order/{orderId}",
        region: "europe-west1",
    },
    async (event) => {
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
            const storeDoc = await getFirestore()
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
                    priority: "high" as const,
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

            await getMessaging().send(message);
            console.log(`✅ New order notification sent to store ${storeId} for order ${orderId}`);
        } catch (error) {
            console.error(`❌ Error sending notification for order ${orderId}:`, error);
        }
    }
);
