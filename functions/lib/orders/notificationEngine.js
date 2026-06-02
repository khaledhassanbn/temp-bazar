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
exports.RULES = void 0;
exports.processEventNotifications = processEventNotifications;
const messaging_1 = require("firebase-admin/messaging");
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const RULES = [
    {
        eventType: "order.placed",
        recipients: ["merchant"],
        priority: "high",
        title: "طلب جديد",
        bodyTemplate: "وصل طلب جديد رقم {orderId}",
    },
    {
        eventType: "order.merchant_accepted",
        recipients: ["customer"],
        priority: "normal",
        title: "تم قبول طلبك",
        bodyTemplate: "المتجر قبل طلبك رقم {orderId} وجاري التحضير",
    },
    {
        eventType: "order.merchant_rejected",
        recipients: ["customer"],
        priority: "high",
        title: "تم رفض الطلب",
        bodyTemplate: "عذراً، تم رفض طلبك رقم {orderId}",
    },
    {
        eventType: "order.preparation_started",
        recipients: ["customer"],
        priority: "normal",
        title: "جاري التحضير",
        bodyTemplate: "طلبك رقم {orderId} جاري تحضيره",
    },
    {
        eventType: "order.ready_for_handoff",
        recipients: ["customer"],
        priority: "normal",
        title: "الطلب جاهز",
        bodyTemplate: "طلبك رقم {orderId} جاهز وسيتم توصيله قريباً",
    },
    {
        eventType: "delivery.picked_up",
        recipients: ["customer"],
        priority: "normal",
        title: "طلبك في الطريق",
        bodyTemplate: "المندوب {courierName} في الطريق. للتواصل: {courierPhone}",
    },
    {
        eventType: "delivery.in_transit",
        recipients: ["customer"],
        priority: "normal",
        title: "طلبك في الطريق",
        bodyTemplate: "المندوب {courierName} في الطريق. للتواصل: {courierPhone}",
    },
    {
        eventType: "delivery.completed",
        recipients: ["customer", "merchant"],
        priority: "normal",
        title: "تم التسليم",
        bodyTemplate: "تم تسليم طلبك رقم {orderId} بنجاح",
    },
    {
        eventType: "order.fulfilled",
        recipients: ["customer", "merchant"],
        priority: "normal",
        title: "تم التسليم",
        bodyTemplate: "تم تسليم طلبك رقم {orderId} بنجاح",
    },
    {
        eventType: "delivery.failed",
        recipients: ["merchant"],
        priority: "high",
        title: "فشل التوصيل",
        bodyTemplate: "فشل توصيل الطلب {orderId}. يمكنك إعادة التعيين أو الإلغاء",
    },
    {
        eventType: "delivery.returned_to_store",
        recipients: ["merchant"],
        priority: "high",
        title: "الطلب رجع للمتجر",
        bodyTemplate: "الطلب {orderId} رجع للمتجر. اختر: مندوب / مكتب / تسليم ذاتي / إلغاء",
    },
    {
        eventType: "order.cancelled",
        recipients: ["customer", "merchant"],
        priority: "high",
        title: "تم إلغاء الطلب",
        bodyTemplate: "تم إلغاء الطلب رقم {orderId}",
    },
    {
        eventType: "escalation.warning_30",
        recipients: ["merchant"],
        priority: "high",
        title: "تنبيه: تأخير في الطلب",
        bodyTemplate: "الطلب {orderId} متأخر 30 دقيقة — يرجى المتابعة",
    },
    {
        eventType: "escalation.warning_45",
        recipients: ["merchant"],
        priority: "high",
        title: "تنبيه: تأخير في الطلب",
        bodyTemplate: "الطلب {orderId} متأخر 45 دقيقة — يرجى المتابعة",
    },
    {
        eventType: "escalation.flagged_60",
        recipients: ["merchant"],
        priority: "critical",
        title: "تصعيد: طلب متأخر",
        bodyTemplate: "الطلب {orderId} متأخر 60 دقيقة",
    },
    // Admin is NOT notified via push — dashboard queue only
    {
        eventType: "escalation.needs_attention_90",
        recipients: [],
        priority: "critical",
        title: "",
        bodyTemplate: "",
    },
];
exports.RULES = RULES;
function findRule(eventType) {
    return RULES.find((r) => r.eventType === eventType);
}
async function getFcmToken(recipient, event) {
    const db = (0, firestore_1.getFirestore)();
    if (recipient === "merchant") {
        const storeDoc = await db.collection("markets").doc(event.storeId).get();
        return storeDoc.data()?.fcmToken;
    }
    if (recipient === "customer" && event.userId) {
        const userDoc = await db.collection("users").doc(event.userId).get();
        return userDoc.data()?.fcmToken;
    }
    if (recipient === "courier" && event.metadata.courierId) {
        const courierDoc = await db
            .collection("users")
            .doc(event.metadata.courierId)
            .get();
        return courierDoc.data()?.fcmToken;
    }
    return undefined;
}
function fillTemplate(template, event, orderData) {
    const courier = orderData?.delivery
        ?.currentActor;
    return template
        .replace("{orderId}", event.orderId)
        .replace("{courierName}", courier?.name ?? "المندوب")
        .replace("{courierPhone}", courier?.phone ?? "");
}
async function processEventNotifications(event) {
    const rule = findRule(event.type);
    if (!rule || rule.recipients.length === 0) {
        logger.info("No notification rule for event", { type: event.type });
        return;
    }
    const db = (0, firestore_1.getFirestore)();
    const orderDoc = await db.collection("orders").doc(event.orderId).get();
    const orderData = orderDoc.data();
    for (const recipient of rule.recipients) {
        const token = await getFcmToken(recipient, event);
        if (!token) {
            logger.warn("No FCM token", { recipient, orderId: event.orderId });
            continue;
        }
        const body = fillTemplate(rule.bodyTemplate, event, orderData);
        const message = {
            token,
            notification: {
                title: rule.title,
                body,
            },
            data: {
                type: "order_event",
                eventType: event.type,
                orderId: event.orderId,
                storeId: event.storeId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: (rule.priority === "normal" ? "normal" : "high"),
                notification: {
                    sound: "default",
                    channelId: "orders",
                },
            },
        };
        try {
            await (0, messaging_1.getMessaging)().send(message);
            logger.info("Event notification sent", {
                eventType: event.type,
                recipient,
                orderId: event.orderId,
            });
        }
        catch (err) {
            logger.error("Failed to send notification", { err, recipient });
        }
    }
}
//# sourceMappingURL=notificationEngine.js.map