/**
 * Paymob Webhook Handler
 * 
 * Handles subscription renewal payments from Paymob.
 * Validates HMAC, processes payment, and updates store subscription.
 */

import { Request, Response } from "express";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { verifyPaymobHMAC } from "../utils/hmac";
import { PaymobWebhookPayload } from "../types";

// Ensure Admin SDK is initialized once
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Paymob webhook handler
 * 
 * Expected webhook payload structure:
 * {
 *   "obj": { ... transaction data ... },
 *   "type": "TRANSACTION",
 *   "hmac": "signature"
 * }
 * 
 * The metadata field in the order should contain:
 * - storeId: The store document ID
 * - packageId: The package document ID
 */
export async function paymobWebhook(req: Request, res: Response): Promise<void> {
  try {
    // Only POST allowed
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    const payload = req.body as PaymobWebhookPayload;

    // Validate payload structure
    if (!payload.obj || !payload.type) {
      logger.error("Paymob webhook: Invalid payload structure", { payload });
      res.status(400).json({ error: "Invalid payload structure" });
      return;
    }

    // HMAC Secret
    const hmacSecret = process.env.PAYMOB_HMAC_SECRET;
    if (!hmacSecret) {
      logger.error("Paymob webhook: PAYMOB_HMAC_SECRET not configured");
      res.status(500).json({ error: "Server configuration error" });
      return;
    }

    // Verify HMAC
    if (!verifyPaymobHMAC(payload, hmacSecret)) {
      logger.error("Paymob webhook: HMAC verification failed", {
        orderId: payload.obj.order?.id,
      });
      res.status(401).json({ error: "Invalid HMAC signature" });
      return;
    }

    // Check if payment is successful
    if (!payload.obj.is_paid || payload.obj.is_refunded) {
      logger.info("Paymob webhook: Payment not successful or refunded", {
        is_paid: payload.obj.is_paid,
        is_refunded: payload.obj.is_refunded,
        orderId: payload.obj.order?.id,
      });
      res.status(200).json({ message: "Payment not processed (not paid or refunded)" });
      return;
    }

    // Extract metadata
    const metadata = (payload.obj.metadata as any) ||
                     ((payload.obj.order as any)?.metadata) ||
                     {};

    const storeId = metadata.storeId || payload.obj.merchant_order_id;
    const packageId = metadata.packageId;

    if (!storeId) {
      logger.error("Paymob webhook: Missing storeId", {
        orderId: payload.obj.order?.id,
      });
      res.status(400).json({ error: "Missing storeId in metadata" });
      return;
    }

    if (!packageId) {
      logger.error("Paymob webhook: Missing packageId", {
        orderId: payload.obj.order?.id,
        storeId,
      });
      res.status(400).json({ error: "Missing packageId in metadata" });
      return;
    }

    // Fetch Package
    const packageDoc = await db.collection("packages").doc(packageId).get();
    if (!packageDoc.exists) {
      logger.error("Paymob webhook: Package not found", { packageId });
      res.status(404).json({ error: "Package not found" });
      return;
    }

    const packageData = packageDoc.data()!;
    const days = packageData.days as number;
    const packageName = packageData.name as string;

    // Calculate new expiry date
    const now = Timestamp.now();
    const expiryDate = new Date(now.toMillis());
    expiryDate.setDate(expiryDate.getDate() + days);
    const expiryTimestamp = Timestamp.fromDate(expiryDate);

    const storeRef = db.collection("markets").doc(storeId);
    const storeDoc = await storeRef.get();

    if (!storeDoc.exists) {
      logger.error("Paymob webhook: Store not found", { storeId });
      res.status(404).json({ error: "Store not found" });
      return;
    }

    // Update Store Subscription
    await storeRef.update({
      isActive: true,
      expiryDate: expiryTimestamp,
      canAddProducts: true,
      canReceiveOrders: true,
      subscription: {
        packageName: packageName,
        startDate: now,
        endDate: expiryTimestamp,
        durationDays: days,
      },
      deactivatedAt: null,
      status: "active",
      isVisible: true,
    });

    // Save payment record
    const paymentId = `paymob_${payload.obj.id}_${Date.now()}`;

    await storeRef.collection("payments").doc(paymentId).set({
      paymentId,
      packageId,
      packageName,
      amount: payload.obj.amount_cents / 100,
      currency: payload.obj.currency,
      status: "completed",
      createdAt: now,
      paymobOrderId: payload.obj.order?.id?.toString(),
      paymobTransactionId: payload.obj.id?.toString(),
    });

    logger.info("Paymob webhook: Subscription renewed successfully", {
      storeId,
      packageId,
      packageName,
      expiryDate: expiryTimestamp.toDate().toISOString(),
    });

    res.status(200).json({
      success: true,
      message: "Subscription renewed successfully",
      storeId,
      expiryDate: expiryTimestamp.toDate().toISOString(),
    });

  } catch (error) {
    logger.error("Paymob webhook: Unexpected error", { error });
    res.status(500).json({ error: "Internal server error" });
  }
}
