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
exports.restoreAccount = exports.softDeleteAccount = exports.removeAdminRole = exports.setAdminRole = exports.assignAdminByEmail = void 0;
const https_1 = require("firebase-functions/v2/https");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const auth_2 = require("../utils/auth");
const DEFAULT_PERMISSIONS = {
    super_admin: {
        manage_craftsmen: true,
        manage_stores: true,
        manage_couriers: true,
        manage_reports: true,
        manage_media: true,
        manage_verification: true,
        view_analytics: true,
        manage_admins: true,
        delete_accounts: true,
        ban_accounts: true,
        view_logs: true,
    },
    admin: {
        manage_craftsmen: true,
        manage_stores: true,
        manage_couriers: true,
        manage_reports: true,
        manage_media: true,
        manage_verification: true,
        view_analytics: true,
        manage_admins: false,
        delete_accounts: true,
        ban_accounts: true,
        view_logs: true,
    },
    moderator: {
        manage_craftsmen: false,
        manage_stores: false,
        manage_couriers: false,
        manage_reports: true,
        manage_media: true,
        manage_verification: false,
        view_analytics: true,
        manage_admins: false,
        delete_accounts: false,
        ban_accounts: false,
        view_logs: false,
    },
    support_agent: {
        manage_craftsmen: false,
        manage_stores: false,
        manage_couriers: false,
        manage_reports: true,
        manage_media: false,
        manage_verification: false,
        view_analytics: true,
        manage_admins: false,
        delete_accounts: false,
        ban_accounts: false,
        view_logs: false,
    },
};
async function verifySuperAdmin(uid) {
    await (0, auth_2.verifyAdmin)(uid);
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = (0, firestore_1.getFirestore)();
    const roleDoc = await db.collection("admin_roles").doc(uid).get();
    const role = roleDoc.data()?.role;
    if (role !== "super_admin") {
        const userDoc = await db.collection("users").doc(uid).get();
        const adminRole = userDoc.data()?.adminRole;
        if (adminRole !== "super_admin") {
            throw new https_1.HttpsError("permission-denied", "Only super admins can manage admin roles");
        }
    }
}
async function verifyDeletePermission(uid) {
    await (0, auth_2.verifyAdmin)(uid);
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = (0, firestore_1.getFirestore)();
    const roleDoc = await db.collection("admin_roles").doc(uid).get();
    if (!roleDoc.exists)
        return;
    const permissions = roleDoc.data()?.permissions;
    const role = roleDoc.data()?.role;
    if (role === "super_admin")
        return;
    if (permissions?.delete_accounts === true)
        return;
    throw new https_1.HttpsError("permission-denied", "You do not have permission to delete accounts");
}
async function setAdminClaims(targetUid, role, name, email, permissions, createdBy) {
    const db = (0, firestore_1.getFirestore)();
    await db.collection("admin_roles").doc(targetUid).set({
        role,
        name,
        email,
        permissions,
        createdBy,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection("users").doc(targetUid).set({
        status: "admin",
        adminRole: role,
        isDeleted: false,
    }, { merge: true });
    const auth = (0, auth_1.getAuth)();
    await auth.setCustomUserClaims(targetUid, {
        role: "admin",
        userStatus: "admin",
        adminRole: role,
    });
}
exports.assignAdminByEmail = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    const callerUid = request.auth?.uid;
    await verifySuperAdmin(callerUid);
    const data = request.data;
    const email = data.email?.trim().toLowerCase();
    const role = data.role;
    if (!email || !role) {
        throw new https_1.HttpsError("invalid-argument", "email and role are required");
    }
    if (!DEFAULT_PERMISSIONS[role]) {
        throw new https_1.HttpsError("invalid-argument", "Invalid role");
    }
    const auth = (0, auth_1.getAuth)();
    let targetUser;
    try {
        targetUser = await auth.getUserByEmail(email);
    }
    catch {
        throw new https_1.HttpsError("not-found", "No account found with this email. User must register first.");
    }
    const permissions = data.permissions && Object.keys(data.permissions).length > 0
        ? data.permissions
        : DEFAULT_PERMISSIONS[role];
    const db = (0, firestore_1.getFirestore)();
    const userDoc = await db.collection("users").doc(targetUser.uid).get();
    const userData = userDoc.data() ?? {};
    const displayName = data.name?.trim() ||
        `${userData.firstName ?? ""} ${userData.lastName ?? ""}`.trim() ||
        targetUser.displayName ||
        email;
    await setAdminClaims(targetUser.uid, role, displayName, email, permissions, callerUid);
    logger.info("assignAdminByEmail success", {
        targetUid: targetUser.uid,
        role,
        callerUid,
    });
    return { success: true, targetUid: targetUser.uid, role, email };
});
exports.setAdminRole = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    const callerUid = request.auth?.uid;
    await verifySuperAdmin(callerUid);
    const data = request.data;
    const { targetUid, role, name, email } = data;
    if (!targetUid || !role || !name || !email) {
        throw new https_1.HttpsError("invalid-argument", "Missing required fields");
    }
    if (!DEFAULT_PERMISSIONS[role]) {
        throw new https_1.HttpsError("invalid-argument", "Invalid role");
    }
    const permissions = data.permissions && Object.keys(data.permissions).length > 0
        ? data.permissions
        : DEFAULT_PERMISSIONS[role];
    await setAdminClaims(targetUid, role, name, email, permissions, callerUid);
    logger.info("setAdminRole success", { targetUid, role, callerUid });
    return { success: true, targetUid, role };
});
exports.removeAdminRole = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    const callerUid = request.auth?.uid;
    await verifySuperAdmin(callerUid);
    const targetUid = request.data?.targetUid;
    if (!targetUid) {
        throw new https_1.HttpsError("invalid-argument", "targetUid is required");
    }
    if (targetUid === callerUid) {
        throw new https_1.HttpsError("failed-precondition", "Cannot remove your own admin role");
    }
    const db = (0, firestore_1.getFirestore)();
    await db.collection("admin_roles").doc(targetUid).delete();
    await db.collection("users").doc(targetUid).set({
        status: "user",
        adminRole: firestore_1.FieldValue.delete(),
    }, { merge: true });
    const auth = (0, auth_1.getAuth)();
    await auth.setCustomUserClaims(targetUid, {
        role: "user",
        userStatus: "user",
        adminRole: null,
    });
    logger.info("removeAdminRole success", { targetUid, callerUid });
    return { success: true, targetUid };
});
exports.softDeleteAccount = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    const callerUid = request.auth?.uid;
    await verifyDeletePermission(callerUid);
    const data = request.data;
    const targetUid = data.targetUid;
    const targetType = data.targetType ?? "user";
    if (!targetUid) {
        throw new https_1.HttpsError("invalid-argument", "targetUid is required");
    }
    if (targetUid === callerUid) {
        throw new https_1.HttpsError("failed-precondition", "Cannot delete your own account");
    }
    const db = (0, firestore_1.getFirestore)();
    const deletePayload = {
        isDeleted: true,
        deletedAt: firestore_1.FieldValue.serverTimestamp(),
        deletedBy: callerUid,
    };
    await db.collection("users").doc(targetUid).set(deletePayload, {
        merge: true,
    });
    if (targetType === "craftsman") {
        await db.collection("craftsmen").doc(targetUid).set({
            ...deletePayload,
            visibility: "hidden",
            accountStatus: "deleted",
        }, { merge: true });
    }
    else if (targetType === "store") {
        const stores = await db
            .collection("markets")
            .where("ownerUid", "==", targetUid)
            .get();
        for (const doc of stores.docs) {
            await doc.ref.set({
                ...deletePayload,
                isVisible: false,
                isActive: false,
                accountStatus: "deleted",
            }, { merge: true });
        }
    }
    else if (targetType === "courier") {
        await db.collection("courier_requests").doc(targetUid).set({
            ...deletePayload,
            status: "deleted",
            accountStatus: "deleted",
        }, { merge: true });
    }
    logger.info("softDeleteAccount success", {
        targetUid,
        targetType,
        callerUid,
    });
    return { success: true, targetUid, targetType };
});
exports.restoreAccount = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    const callerUid = request.auth?.uid;
    await verifyDeletePermission(callerUid);
    const data = request.data;
    const targetUid = data.targetUid;
    const targetType = data.targetType ?? "user";
    if (!targetUid) {
        throw new https_1.HttpsError("invalid-argument", "targetUid is required");
    }
    const db = (0, firestore_1.getFirestore)();
    const restorePayload = {
        isDeleted: false,
        deletedAt: firestore_1.FieldValue.delete(),
        deletedBy: firestore_1.FieldValue.delete(),
        restoredAt: firestore_1.FieldValue.serverTimestamp(),
        restoredBy: callerUid,
    };
    await db.collection("users").doc(targetUid).set(restorePayload, {
        merge: true,
    });
    if (targetType === "craftsman") {
        await db.collection("craftsmen").doc(targetUid).set({
            isDeleted: false,
            deletedAt: firestore_1.FieldValue.delete(),
            deletedBy: firestore_1.FieldValue.delete(),
            visibility: "public",
            accountStatus: "active",
        }, { merge: true });
    }
    else if (targetType === "store") {
        const stores = await db
            .collection("markets")
            .where("ownerUid", "==", targetUid)
            .get();
        for (const doc of stores.docs) {
            await doc.ref.set({
                isDeleted: false,
                deletedAt: firestore_1.FieldValue.delete(),
                deletedBy: firestore_1.FieldValue.delete(),
                accountStatus: "active",
            }, { merge: true });
        }
    }
    else if (targetType === "courier") {
        await db.collection("courier_requests").doc(targetUid).set({
            isDeleted: false,
            deletedAt: firestore_1.FieldValue.delete(),
            deletedBy: firestore_1.FieldValue.delete(),
            accountStatus: "active",
        }, { merge: true });
    }
    logger.info("restoreAccount success", { targetUid, targetType, callerUid });
    return { success: true, targetUid, targetType };
});
//# sourceMappingURL=adminRoles.js.map