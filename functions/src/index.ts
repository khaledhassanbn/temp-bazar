/**
 * Firebase Cloud Functions - Store Subscription System
 * 
 * This module provides:
 * - Paymob webhook integration for subscription renewals
 * - Scheduled function to check and disable expired subscriptions
 * - Store status checking API
 * - Package management (CRUD) for admin users
 * - Facebook Data Deletion callback
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
import { onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

import { paymobWebhook } from "./paymob/webhook";
import { checkExpiredSubscriptions } from "./subscriptions/checkExpired";
import { checkStoreStatus } from "./subscriptions/checkStatus";
import { renewStoreSubscription } from "./subscriptions/renewSubscription";
import { createPackage, updatePackage, deletePackage } from "./packages/crud";
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
// SCHEDULED FUNCTION - Checks and disables expired subscriptions
// ---------------------------------------------------------------------------
export const checkExpiredSubscriptionsScheduled = functions.scheduler.onSchedule(
  {
    schedule: "0 * * * *", // Every hour
    timeZone: "Africa/Cairo",
    memory: "512MiB",
  },
  checkExpiredSubscriptions
);

// ---------------------------------------------------------------------------
// SCHEDULED FUNCTION - Deletes images of expired ads
// ---------------------------------------------------------------------------
export const deleteExpiredAdsImagesScheduled = functions.scheduler.onSchedule(
  {
    schedule: "0 2 * * *", // Every day at 2:00 AM
    timeZone: "Africa/Cairo",
    memory: "512MiB",
  },
  deleteExpiredAdsImages
);

// ---------------------------------------------------------------------------
// SCHEDULED FUNCTION - Cleans up expired pending payments (24 hours)
// ---------------------------------------------------------------------------
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
// CALLABLE FUNCTION - Check store subscription status
// ---------------------------------------------------------------------------
export const checkStoreStatusCallable = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    return await checkStoreStatus(request);
  }
);

// ---------------------------------------------------------------------------
// SUBSCRIPTION RENEWAL (Admin Only)
// ---------------------------------------------------------------------------
export const renewStoreSubscriptionCallable = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    return await renewStoreSubscription(request);
  }
);

// ---------------------------------------------------------------------------
// PACKAGE MANAGEMENT (Admin Only)
// ---------------------------------------------------------------------------
export const createPackageCallable = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    return await createPackage(request);
  }
);

export const updatePackageCallable = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    return await updatePackage(request);
  }
);

export const deletePackageCallable = onCall(
  {
    memory: "256MiB",
  },
  async (request) => {
    return await deletePackage(request);
  }
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
