"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.lifecycleToLegacyStatus = lifecycleToLegacyStatus;
exports.inferLifecycleFromLegacy = inferLifecycleFromLegacy;
exports.computeCustomerStatus = computeCustomerStatus;
exports.customerStatusArabic = customerStatusArabic;
exports.defaultDeliveryBlock = defaultDeliveryBlock;
exports.defaultEscalationBlock = defaultEscalationBlock;
/** Arabic status shown in merchant app (legacy projection). */
function lifecycleToLegacyStatus(status) {
    switch (status) {
        case "pending":
            return "قيد المراجعة";
        case "accepted":
            return "تم استلام الطلب";
        case "preparing":
        case "ready_for_handoff":
            return "جارى تسليم للدليفري";
        case "returned_to_store":
            return "مرجع للمتجر";
        case "fulfilled":
            return "تم التسليم للطيار";
        case "cancelled":
            return "تم رفض الطلب";
        default:
            return status;
    }
}
/** Infer lifecycle from legacy Arabic/English status (backfill + intercept). */
function inferLifecycleFromLegacy(status) {
    const s = status.trim();
    const lower = s.toLowerCase();
    if (s === "قيد المراجعة" ||
        lower === "pending" ||
        s === "في انتظار قبول المكتب") {
        return "pending";
    }
    if (s === "تم استلام الطلب" ||
        lower === "accepted" ||
        s === "تم قبوله من المكتب") {
        return "accepted";
    }
    if (s === "جارى تسليم للدليفري" ||
        lower === "preparing" ||
        lower === "assigned" ||
        lower === "driver_accepted" ||
        s === "تم تعيين مندوب" ||
        s === "المندوب قبل الطلب") {
        return "preparing";
    }
    if (lower === "picked_up" ||
        s === "تم استلام الطلب من المتجر" ||
        s === "المندوب في الطريق") {
        return "ready_for_handoff";
    }
    if (lower === "returned_to_merchant" ||
        s === "مرجع للمتجر" ||
        s === "المكتب رفض الطلب") {
        return "returned_to_store";
    }
    if (s === "تم التسليم للطيار" ||
        lower === "completed" ||
        lower === "delivered" ||
        s === "الطلب مكتمل" ||
        s === "تم التسليم") {
        return "fulfilled";
    }
    if (s === "تم رفض الطلب" ||
        lower === "rejected" ||
        s === "مرفوض نهائياً" ||
        s === "تم رفض الطلب من المكتب") {
        return "cancelled";
    }
    return "pending";
}
function computeCustomerStatus(lifecycle, deliveryState) {
    if (lifecycle === "cancelled")
        return "cancelled";
    if (lifecycle === "fulfilled")
        return "delivered";
    if (lifecycle === "pending" || lifecycle === "accepted") {
        return "order_received";
    }
    if (deliveryState === "picked_up" ||
        deliveryState === "in_transit" ||
        deliveryState === "delivered") {
        return "on_the_way";
    }
    return "preparing";
}
function customerStatusArabic(status) {
    switch (status) {
        case "order_received":
            return "تم استلام الطلب";
        case "preparing":
            return "جاري التحضير";
        case "on_the_way":
            return "في الطريق";
        case "delivered":
            return "تم التسليم";
        case "cancelled":
            return "ملغي";
        default:
            return status;
    }
}
function defaultDeliveryBlock() {
    return {
        mode: "none",
        assignmentState: "none",
        currentActor: {
            type: null,
            id: null,
            name: "",
            phone: "",
        },
        failureCount: 0,
    };
}
function defaultEscalationBlock() {
    return { level: 0 };
}
//# sourceMappingURL=statusMappers.js.map