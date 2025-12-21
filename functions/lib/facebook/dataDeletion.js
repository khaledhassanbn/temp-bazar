"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.facebookDataDeletion = void 0;
const firebase_functions_1 = require("firebase-functions");
const firestore_1 = require("firebase-admin/firestore");
const crypto_1 = __importDefault(require("crypto"));
const APP_SECRET = process.env.FACEBOOK_APP_SECRET;
const base64UrlDecode = (input) => {
    const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
    const padding = normalized.length % 4;
    const padded = padding === 0 ? normalized : normalized + "=".repeat(4 - padding);
    return Buffer.from(padded, "base64");
};
const parseSignedRequest = (signedRequest, appSecret) => {
    const [encodedSignature, encodedPayload] = signedRequest.split(".");
    if (!encodedSignature || !encodedPayload) {
        throw new Error("Malformed signed_request");
    }
    const signature = base64UrlDecode(encodedSignature);
    const payloadBuffer = base64UrlDecode(encodedPayload);
    const payloadJson = payloadBuffer.toString("utf8");
    const payload = JSON.parse(payloadJson);
    const expectedSignature = crypto_1.default
        .createHmac("sha256", appSecret)
        .update(encodedPayload)
        .digest();
    if (signature.length !== expectedSignature.length ||
        !crypto_1.default.timingSafeEqual(signature, expectedSignature)) {
        throw new Error("Invalid signature");
    }
    return payload;
};
const extractSignedRequest = (req) => {
    // Facebook can send application/x-www-form-urlencoded or JSON
    if (typeof req.body === "string") {
        const params = new URLSearchParams(req.body);
        return params.get("signed_request");
    }
    if (req.body && typeof req.body === "object") {
        return (req.body.signed_request ??
            req.body.signedRequest ??
            null);
    }
    if (req.query && typeof req.query === "object") {
        return (req.query.signed_request ??
            req.query.signedRequest ??
            null);
    }
    return null;
};
const facebookDataDeletion = async (req, res, fbAppSecret) => {
    if (req.method !== "POST") {
        res.set("Allow", "POST");
        res.status(405).json({ error: "Method Not Allowed" });
        return;
    }
    if (!APP_SECRET) {
        firebase_functions_1.logger.error("FACEBOOK_APP_SECRET is not configured");
        res
            .status(500)
            .json({ error: "FACEBOOK_APP_SECRET is not configured" });
        return;
    }
    const signedRequest = extractSignedRequest(req);
    if (!signedRequest) {
        res.status(400).json({ error: "signed_request is required" });
        return;
    }
    try {
        const payload = parseSignedRequest(signedRequest, APP_SECRET);
        const facebookUserId = payload.user_id ?? payload.user?.id;
        if (!facebookUserId) {
            throw new Error("Unable to extract user_id");
        }
        const confirmationCode = `fb-delete-${facebookUserId}-${Date.now()}`;
        const firestore = (0, firestore_1.getFirestore)();
        await firestore
            .collection("facebookDeletionRequests")
            .doc(confirmationCode)
            .set({
            facebookUserId,
            payload,
            status: "pending",
            createdAt: firestore_1.Timestamp.now(),
        });
        const statusUrl = `https://bazar-suez.web.app/facebook-data-deletion?request_id=${confirmationCode}`;
        res.json({
            url: statusUrl,
            confirmation_code: confirmationCode,
        });
        return;
    }
    catch (error) {
        firebase_functions_1.logger.error("Failed to process facebook data deletion request", error);
        res.status(400).json({
            error: "Invalid signed_request",
        });
        return;
    }
};
exports.facebookDataDeletion = facebookDataDeletion;
//# sourceMappingURL=dataDeletion.js.map