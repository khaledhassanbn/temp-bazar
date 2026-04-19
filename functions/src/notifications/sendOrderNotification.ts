/**
 * إشعار الطلبات للتاجر — مسار الإنتاج
 *
 * Trigger: مستند جديد في مجموعة `orders` (سجل موحّد للطلبات).
 * مصدر توكن FCM: `stores/{storeId}` أولاً، ثم احتياطي `markets/{storeId}`
 * للتوافق مع التطبيقات القديمة.
 */

import * as functions from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

async function resolveStoreFcmToken(storeId: string): Promise<string | undefined> {
    const db = getFirestore();
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

export const sendNewOrderNotification = functions.firestore.onDocumentCreated(
    {
        document: "orders/{orderId}",
        region: "europe-west1",
    },
    async (event) => {
        const orderId = event.params.orderId;
        const orderData = event.data?.data();

        if (!orderData) {
            console.log(`sendNewOrderNotification: no payload for ${orderId}`);
            return;
        }

        const storeId = orderData.storeId as string | undefined;
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
            const dataBody = "فيه طلب جديد عندك";

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
                    priority: "high" as const,
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

            await getMessaging().send(message);
            console.log(`✅ FCM sent for order ${orderId} → store ${storeId}`);
        } catch (error) {
            console.error(`❌ sendNewOrderNotification failed for ${orderId}:`, error);
        }
    }
);
