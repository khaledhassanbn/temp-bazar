import { Request } from "firebase-functions/v2/https";
import type { Response } from "express";
import { logger } from "firebase-functions";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import crypto from "crypto";

const APP_SECRET = process.env.FACEBOOK_APP_SECRET;

interface SignedRequestPayload {
  user_id?: string;
  user?: {
    id?: string;
  };
  [key: string]: unknown;
}

const base64UrlDecode = (input: string): Buffer => {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padding = normalized.length % 4;
  const padded =
    padding === 0 ? normalized : normalized + "=".repeat(4 - padding);
  return Buffer.from(padded, "base64");
};

const parseSignedRequest = (
  signedRequest: string,
  appSecret: string
): SignedRequestPayload => {
  const [encodedSignature, encodedPayload] = signedRequest.split(".");

  if (!encodedSignature || !encodedPayload) {
    throw new Error("Malformed signed_request");
  }

  const signature = base64UrlDecode(encodedSignature);
  const payloadBuffer = base64UrlDecode(encodedPayload);
  const payloadJson = payloadBuffer.toString("utf8");
  const payload = JSON.parse(payloadJson) as SignedRequestPayload;

  const expectedSignature = crypto
    .createHmac("sha256", appSecret)
    .update(encodedPayload)
    .digest();

  if (
    signature.length !== expectedSignature.length ||
    !crypto.timingSafeEqual(signature, expectedSignature)
  ) {
    throw new Error("Invalid signature");
  }

  return payload;
};

const extractSignedRequest = (req: Request): string | null => {
  // Facebook can send application/x-www-form-urlencoded or JSON
  if (typeof req.body === "string") {
    const params = new URLSearchParams(req.body);
    return params.get("signed_request");
  }

  if (req.body && typeof req.body === "object") {
    return (
      (req.body as Record<string, string>).signed_request ??
      (req.body as Record<string, string>).signedRequest ??
      null
    );
  }

  if (req.query && typeof req.query === "object") {
    return (
      (req.query as Record<string, string>).signed_request ??
      (req.query as Record<string, string>).signedRequest ??
      null
    );
  }

  return null;
};

export const facebookDataDeletion = async (req: Request, res: Response, fbAppSecret: string) => {
  if (req.method !== "POST") {
    res.set("Allow", "POST");
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  if (!APP_SECRET) {
    logger.error("FACEBOOK_APP_SECRET is not configured");
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
    const firestore = getFirestore();

    await firestore
      .collection("facebookDeletionRequests")
      .doc(confirmationCode)
      .set({
        facebookUserId,
        payload,
        status: "pending",
        createdAt: Timestamp.now(),
      });

    const statusUrl = `https://bazar-suez.web.app/facebook-data-deletion?request_id=${confirmationCode}`;

    res.json({
      url: statusUrl,
      confirmation_code: confirmationCode,
    });
    return;
  } catch (error) {
    logger.error("Failed to process facebook data deletion request", error);
    res.status(400).json({
      error: "Invalid signed_request",
    });
    return;
  }
};


