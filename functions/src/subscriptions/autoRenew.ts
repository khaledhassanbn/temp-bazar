import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { ScheduledEvent } from "firebase-functions/v2/scheduler";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const BATCH_SIZE = 150;

export async function autoRenewSubscriptions(
  event: ScheduledEvent
): Promise<void> {
  logger.info("autoRenewSubscriptions: start");
  const in24h = Timestamp.fromDate(
    new Date(Date.now() + 24 * 60 * 60 * 1000)
  );

  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let processed = 0;
  let renewed = 0;
  let insufficient = 0;

  while (true) {
    let query = db
      .collection("markets")
      .where("licenseAutoRenew", "==", true)
      .where("expiryDate", "<=", in24h)
      .limit(BATCH_SIZE);

    if (lastDoc) query = query.startAfter(lastDoc);
    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const doc of snapshot.docs) {
      processed++;
      const data = doc.data();
      const ownerId = data.ownerId as string | undefined;
      const packageId = (data.currentPackageId as string | undefined) ||
        (data.subscription?.packageId as string | undefined);

      if (!ownerId || !packageId) {
        logger.warn("autoRenew: skip store without owner/package", {
          storeId: doc.id,
        });
        continue;
      }

      try {
        await db.runTransaction(async (txn) => {
          const userRef = db.collection("users").doc(ownerId);
          const pkgRef = db.collection("packages").doc(packageId);

          const [userSnap, pkgSnap, storeSnap] = await Promise.all([
            txn.get(userRef),
            txn.get(pkgRef),
            txn.get(doc.ref),
          ]);

          if (!pkgSnap.exists) {
            throw new Error("package not found");
          }

          const pkg = pkgSnap.data()!;
          const price = (pkg.price as number) ?? 0;
          const days = (pkg.days as number) ?? 0;

          const walletBalance =
            ((userSnap.data()?.walletBalance as number) ?? 0) as number;
          if (walletBalance < price) {
            throw new Error("insufficient_balance");
          }

          const storeData = storeSnap.data() ?? {};
          const nowTs = Timestamp.now();
          const currentEnd =
            (storeData.licenseEndAt as Timestamp | undefined) ??
            (storeData.expiryDate as Timestamp | undefined) ??
            nowTs;
          const baseDate = currentEnd.toDate() > new Date()
            ? currentEnd.toDate()
            : new Date();
          const newEnd = Timestamp.fromDate(
            new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000)
          );

          txn.update(userRef, {
            walletBalance: FieldValue.increment(-price),
          });

          txn.update(doc.ref, {
            licenseEndAt: newEnd,
            expiryDate: newEnd,
            licenseLastRenewedAt: nowTs,
            licenseDurationDays: days,
            currentPackageId: packageId,
            currentPackageName: pkg.name,
            subscription: {
              packageId,
              packageName: pkg.name,
              startDate: nowTs,
              endDate: newEnd,
              durationDays: days,
            },
            isActive: true,
            canAddProducts: true,
            canReceiveOrders: true,
            status: "active",
          });
        });

        renewed++;
      } catch (error: any) {
        if (error?.message === "insufficient_balance") {
          insufficient++;
          await doc.ref.set(
            {
              licenseRenewalFailedAt: Timestamp.now(),
              licenseRenewalFailedReason: "insufficient_balance",
            },
            { merge: true }
          );
        } else {
          logger.error("autoRenew error", {
            storeId: doc.id,
            error: error?.message ?? error,
          });
        }
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < BATCH_SIZE) break;
  }

  logger.info("autoRenewSubscriptions: done", {
    processed,
    renewed,
    insufficient,
  });
}


