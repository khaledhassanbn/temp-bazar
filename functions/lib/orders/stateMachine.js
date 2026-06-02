"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isTerminal = isTerminal;
exports.applyAction = applyAction;
exports.mapLegacyArabicStatusToAction = mapLegacyArabicStatusToAction;
const https_1 = require("firebase-functions/v2/https");
const TERMINAL = ["fulfilled", "cancelled"];
function isTerminal(status) {
    return TERMINAL.includes(status);
}
/** Validates and computes next state for an action. */
function applyAction(order, action, payload = {}) {
    const current = order.lifecycleStatus;
    const delivery = order.delivery;
    switch (action) {
        case "merchant_accept":
            if (current !== "pending") {
                throw conflict(`Cannot accept from ${current}`);
            }
            return {
                lifecycleStatus: "accepted",
                eventType: "order.merchant_accepted",
                terminal: false,
                moveToPast: false,
            };
        case "merchant_reject":
            if (current !== "pending") {
                throw conflict(`Cannot reject from ${current}`);
            }
            return {
                lifecycleStatus: "cancelled",
                eventType: "order.merchant_rejected",
                terminal: true,
                moveToPast: true,
            };
        case "merchant_mark_preparing":
            if (!["accepted", "returned_to_store"].includes(current)) {
                throw conflict(`Cannot mark preparing from ${current}`);
            }
            return {
                lifecycleStatus: "preparing",
                deliveryMode: payload.deliveryMode,
                deliveryState: "mode_selected",
                eventType: "order.preparation_started",
                terminal: false,
                moveToPast: false,
            };
        case "merchant_mark_ready":
            if (!["accepted", "preparing", "returned_to_store"].includes(current)) {
                throw conflict(`Cannot mark ready from ${current}`);
            }
            return {
                lifecycleStatus: "ready_for_handoff",
                deliveryState: delivery.assignmentState === "none" ? "searching" : delivery.assignmentState,
                eventType: "order.ready_for_handoff",
                terminal: false,
                moveToPast: false,
            };
        case "merchant_self_delivered":
            if (!["accepted", "preparing", "ready_for_handoff", "returned_to_store"].includes(current)) {
                throw conflict(`Cannot self-deliver from ${current}`);
            }
            return {
                lifecycleStatus: "fulfilled",
                deliveryMode: "merchant_self",
                deliveryState: "delivered",
                eventType: "order.fulfilled",
                terminal: true,
                moveToPast: true,
            };
        case "merchant_cancel":
            if (isTerminal(current)) {
                throw conflict(`Order already terminal: ${current}`);
            }
            return {
                lifecycleStatus: "cancelled",
                deliveryState: "cancelled",
                eventType: "order.cancelled",
                terminal: true,
                moveToPast: true,
            };
        case "delivery_mode_office":
            if (isTerminal(current))
                throw conflict(`Order terminal: ${current}`);
            return {
                lifecycleStatus: current === "pending" ? "accepted" : current === "accepted" ? "preparing" : current,
                deliveryMode: "delivery_office",
                deliveryState: "searching",
                eventType: "delivery.mode_selected",
                terminal: false,
                moveToPast: false,
            };
        case "delivery_mode_independent":
            if (isTerminal(current))
                throw conflict(`Order terminal: ${current}`);
            return {
                lifecycleStatus: current === "pending"
                    ? "accepted"
                    : current === "accepted"
                        ? "preparing"
                        : current,
                deliveryMode: "independent_courier",
                deliveryState: "searching",
                eventType: "delivery.search_started",
                terminal: false,
                moveToPast: false,
            };
        case "delivery_mode_self":
            return applyAction(order, "merchant_self_delivered", payload);
        case "delivery_completed":
            if (isTerminal(current))
                throw conflict(`Order terminal: ${current}`);
            return {
                lifecycleStatus: "fulfilled",
                deliveryState: "delivered",
                eventType: "delivery.completed",
                terminal: true,
                moveToPast: true,
            };
        case "delivery_failed":
            if (isTerminal(current))
                throw conflict(`Order terminal: ${current}`);
            return {
                lifecycleStatus: "returned_to_store",
                deliveryState: "failed",
                eventType: "delivery.failed",
                terminal: false,
                moveToPast: false,
            };
        case "delivery_returned_to_store":
            if (isTerminal(current))
                throw conflict(`Order terminal: ${current}`);
            return {
                lifecycleStatus: "returned_to_store",
                deliveryState: "returned",
                eventType: "delivery.returned_to_store",
                terminal: false,
                moveToPast: false,
            };
        case "admin_override": {
            const newStatus = payload.lifecycleStatus;
            if (!newStatus) {
                throw new https_1.HttpsError("invalid-argument", "admin_override requires lifecycleStatus");
            }
            return {
                lifecycleStatus: newStatus,
                deliveryState: payload.deliveryState,
                eventType: "admin.override",
                terminal: isTerminal(newStatus),
                moveToPast: isTerminal(newStatus),
            };
        }
        default:
            throw new https_1.HttpsError("invalid-argument", `Unknown action: ${action}`);
    }
}
function conflict(message) {
    return new https_1.HttpsError("failed-precondition", message);
}
/** Map legacy Arabic button labels to canonical actions. */
function mapLegacyArabicStatusToAction(newStatus) {
    switch (newStatus.trim()) {
        case "تم استلام الطلب":
            return "merchant_accept";
        case "تم رفض الطلب":
            return "merchant_reject";
        case "جارى تسليم للدليفري":
            return "merchant_mark_preparing";
        case "تم التسليم للطيار":
            return "merchant_self_delivered";
        case "مرجع للمتجر":
            return "delivery_returned_to_store";
        default:
            return null;
    }
}
//# sourceMappingURL=stateMachine.js.map