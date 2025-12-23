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
exports.autoRenewSubscriptions = autoRenewSubscriptions;
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const BATCH_SIZE = 150;
async function autoRenewSubscriptions(event) {
    logger.info("autoRenewSubscriptions: start");
    const in24h = firestore_1.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));
    let lastDoc = null;
    let processed = 0;
    let renewed = 0;
    let insufficient = 0;
    while (true) {
        let query = db
            .collection("markets")
            .where("licenseAutoRenew", "==", true)
            .where("expiryDate", "<=", in24h)
            .limit(BATCH_SIZE);
        if (lastDoc)
            query = query.startAfter(lastDoc);
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        for (const doc of snapshot.docs) {
            processed++;
            const data = doc.data();
            const ownerId = data.ownerId;
            const packageId = data.currentPackageId ||
                data.subscription?.packageId;
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
                    const pkg = pkgSnap.data();
                    const price = pkg.price ?? 0;
                    const days = pkg.days ?? 0;
                    const walletBalance = (userSnap.data()?.walletBalance ?? 0);
                    if (walletBalance < price) {
                        throw new Error("insufficient_balance");
                    }
                    const storeData = storeSnap.data() ?? {};
                    const nowTs = firestore_1.Timestamp.now();
                    const currentEnd = storeData.licenseEndAt ??
                        storeData.expiryDate ??
                        nowTs;
                    const baseDate = currentEnd.toDate() > new Date()
                        ? currentEnd.toDate()
                        : new Date();
                    const newEnd = firestore_1.Timestamp.fromDate(new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000));
                    txn.update(userRef, {
                        walletBalance: firestore_1.FieldValue.increment(-price),
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
            }
            catch (error) {
                if (error?.message === "insufficient_balance") {
                    insufficient++;
                    await doc.ref.set({
                        licenseRenewalFailedAt: firestore_1.Timestamp.now(),
                        licenseRenewalFailedReason: "insufficient_balance",
                    }, { merge: true });
                }
                else {
                    logger.error("autoRenew error", {
                        storeId: doc.id,
                        error: error?.message ?? error,
                    });
                }
            }
        }
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.size < BATCH_SIZE)
            break;
    }
    logger.info("autoRenewSubscriptions: done", {
        processed,
        renewed,
        insufficient,
    });
}
//# sourceMappingURL=autoRenew.js.map