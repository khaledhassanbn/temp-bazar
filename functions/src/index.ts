/**
 * Firebase Cloud Functions - Store Subscription System
 * 
 * This module provides:
 * - Paymob webhook integration for subscription renewals
 * - Facebook Data Deletion callback
 * - Scheduled function for cleanup and auto-renewal
 */

// ---------------------------------------------------------------------------
// INITIALIZE FIREBASE ADMIN
// ---------------------------------------------------------------------------
import { initializeApp } from "firebase-admin/app";

try {
  initializeApp();
} catch (error) {
  // App already initialized, ignore
}

// ---------------------------------------------------------------------------
// LOAD ENVIRONMENT VARIABLES
// ---------------------------------------------------------------------------
import * as dotenv from "dotenv";
dotenv.config(); // Reads .env and populates process.env

const fbAppSecret = process.env.FACEBOOK_APP_SECRET;
if (!fbAppSecret) {
  console.warn("⚠️ FACEBOOK_APP_SECRET is not defined in .env or environment variables");
}

// ---------------------------------------------------------------------------
// IMPORT OTHER MODULES
// ---------------------------------------------------------------------------
import * as functions from "firebase-functions/v2";
import { setGlobalOptions } from "firebase-functions/v2";

import { paymobWebhook } from "./paymob/webhook";
import { autoRenewSubscriptions } from "./subscriptions/autoRenew";
import { facebookDataDeletion } from "./facebook/dataDeletion";
import { deleteExpiredAdsImages } from "./ads/deleteExpiredImages";
import { cleanupExpiredPendingPayments } from "./pendingPayments/cleanupExpired";

// ---------------------------------------------------------------------------
// GLOBAL OPTIONS
// ---------------------------------------------------------------------------
setGlobalOptions({
  maxInstances: 10,
  region: "europe-west1",
});

// ---------------------------------------------------------------------------
// PAYMOB WEBHOOK - Handles subscription renewals
// ---------------------------------------------------------------------------
export const paymobWebhookHandler = functions.https.onRequest(
  {
    cors: true,
    memory: "512MiB",
  },
  paymobWebhook
);

// ---------------------------------------------------------------------------
// SCHEDULED FUNCTIONS
// ---------------------------------------------------------------------------

export const autoRenewSubscriptionsScheduled = functions.scheduler.onSchedule(
  {
    schedule: "0 * * * *", // Every hour
    timeZone: "Africa/Cairo",
    memory: "512MiB",
  },
  autoRenewSubscriptions
);

export const deleteExpiredAdsImagesScheduled = functions.scheduler.onSchedule(
  {
    schedule: "0 2 * * *", // Every day at 2:00 AM
    timeZone: "Africa/Cairo",
    memory: "512MiB",
  },
  deleteExpiredAdsImages
);

export const cleanupExpiredPendingPaymentsScheduled =
  functions.scheduler.onSchedule(
    {
      schedule: "0 * * * *", // Every hour
      timeZone: "Africa/Cairo",
      memory: "512MiB",
    },
    cleanupExpiredPendingPayments
  );

// ---------------------------------------------------------------------------
// FACEBOOK DATA DELETION CALLBACK
// ---------------------------------------------------------------------------
export const facebookDataDeletionRequest = functions.https.onRequest(
  {
    cors: true,
    memory: "256MiB",
  },
  async (req, res) => {
    // تمرير secret من env للدالة
    await facebookDataDeletion(req, res, fbAppSecret as string);
  }
);
