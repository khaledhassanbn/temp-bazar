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
exports.setAdminRole = void 0;
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
    const db = (0, firestore_1.getFirestore)();
    const permissions = DEFAULT_PERMISSIONS[role];
    await db.collection("admin_roles").doc(targetUid).set({
        role,
        name,
        email,
        permissions,
        createdBy: callerUid,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection("users").doc(targetUid).set({
        status: "admin",
        adminRole: role,
    }, { merge: true });
    const auth = (0, auth_1.getAuth)();
    await auth.setCustomUserClaims(targetUid, {
        role: "admin",
        userStatus: "admin",
        adminRole: role,
    });
    logger.info("setAdminRole success", { targetUid, role, callerUid });
    return { success: true, targetUid, role };
});
//# sourceMappingURL=setAdminRole.js.map