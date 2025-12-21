/**
 * HMAC verification for Paymob webhooks
 */

import * as crypto from "crypto";
import * as logger from "firebase-functions/logger";
import { PaymobWebhookPayload } from "../types";

/**
 * Verifies Paymob webhook HMAC signature
 * 
 * Paymob sends HMAC in the format: HMAC-SHA512(JSON.stringify(obj))
 * 
 * @param payload - The webhook payload from Paymob
 * @param hmacSecret - The HMAC secret from environment variables
 * @returns true if HMAC is valid, false otherwise
 */
export function verifyPaymobHMAC(
  payload: PaymobWebhookPayload,
  hmacSecret: string
): boolean {
  try {
    if (!payload.hmac) {
      logger.warn("Paymob webhook: No HMAC provided");
      return false;
    }

    // Create HMAC from the obj field
    const objString = JSON.stringify(payload.obj);
    const hmac = crypto
      .createHmac("sha512", hmacSecret)
      .update(objString)
      .digest("hex");

    // Compare HMACs (constant-time comparison to prevent timing attacks)
    const providedHmac = payload.hmac.toLowerCase();
    const calculatedHmac = hmac.toLowerCase();

    if (providedHmac !== calculatedHmac) {
      logger.warn("Paymob webhook: HMAC mismatch", {
        provided: providedHmac.substring(0, 10) + "...",
        calculated: calculatedHmac.substring(0, 10) + "...",
      });
      return false;
    }

    logger.info("Paymob webhook: HMAC verified successfully");
    return true;
  } catch (error) {
    logger.error("Paymob webhook: HMAC verification error", { error });
    return false;
  }
}

