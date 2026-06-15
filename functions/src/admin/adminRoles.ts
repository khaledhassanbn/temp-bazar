import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { verifyAdmin } from "../utils/auth";

type RoleKey = "super_admin" | "admin" | "moderator" | "support_agent";

const DEFAULT_PERMISSIONS: Record<RoleKey, Record<string, boolean>> = {
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

async function verifySuperAdmin(uid: string | undefined): Promise<void> {
  await verifyAdmin(uid);
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const db = getFirestore();
  const roleDoc = await db.collection("admin_roles").doc(uid).get();
  const role = roleDoc.data()?.role as string | undefined;

  if (role !== "super_admin") {
    const userDoc = await db.collection("users").doc(uid).get();
    const adminRole = userDoc.data()?.adminRole as string | undefined;
    if (adminRole !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "Only super admins can manage admin roles"
      );
    }
  }
}

async function verifyDeletePermission(uid: string | undefined): Promise<void> {
  await verifyAdmin(uid);
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const db = getFirestore();
  const roleDoc = await db.collection("admin_roles").doc(uid).get();
  if (!roleDoc.exists) return;

  const permissions = roleDoc.data()?.permissions as
    | Record<string, boolean>
    | undefined;
  const role = roleDoc.data()?.role as string | undefined;

  if (role === "super_admin") return;
  if (permissions?.delete_accounts === true) return;

  throw new HttpsError(
    "permission-denied",
    "You do not have permission to delete accounts"
  );
}

async function setAdminClaims(
  targetUid: string,
  role: RoleKey,
  name: string,
  email: string,
  permissions: Record<string, boolean>,
  createdBy: string
): Promise<void> {
  const db = getFirestore();

  await db.collection("admin_roles").doc(targetUid).set(
    {
      role,
      name,
      email,
      permissions,
      createdBy,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await db.collection("users").doc(targetUid).set(
    {
      status: "admin",
      adminRole: role,
      isDeleted: false,
    },
    { merge: true }
  );

  const auth = getAuth();
  await auth.setCustomUserClaims(targetUid, {
    role: "admin",
    userStatus: "admin",
    adminRole: role,
  });
}

export const assignAdminByEmail = onCall(
  { region: "europe-west1" },
  async (request) => {
    const callerUid = request.auth?.uid;
    await verifySuperAdmin(callerUid);

    const data = request.data as {
      email?: string;
      role?: RoleKey;
      permissions?: Record<string, boolean>;
      name?: string;
    };

    const email = data.email?.trim().toLowerCase();
    const role = data.role;
    if (!email || !role) {
      throw new HttpsError("invalid-argument", "email and role are required");
    }
    if (!DEFAULT_PERMISSIONS[role]) {
      throw new HttpsError("invalid-argument", "Invalid role");
    }

    const auth = getAuth();
    let targetUser;
    try {
      targetUser = await auth.getUserByEmail(email);
    } catch {
      throw new HttpsError(
        "not-found",
        "No account found with this email. User must register first."
      );
    }

    const permissions =
      data.permissions && Object.keys(data.permissions).length > 0
        ? data.permissions
        : DEFAULT_PERMISSIONS[role];

    const db = getFirestore();
    const userDoc = await db.collection("users").doc(targetUser.uid).get();
    const userData = userDoc.data() ?? {};
    const displayName =
      data.name?.trim() ||
      `${userData.firstName ?? ""} ${userData.lastName ?? ""}`.trim() ||
      targetUser.displayName ||
      email;

    await setAdminClaims(
      targetUser.uid,
      role,
      displayName,
      email,
      permissions,
      callerUid!
    );

    logger.info("assignAdminByEmail success", {
      targetUid: targetUser.uid,
      role,
      callerUid,
    });

    return { success: true, targetUid: targetUser.uid, role, email };
  }
);

export const setAdminRole = onCall({ region: "europe-west1" }, async (request) => {
  const callerUid = request.auth?.uid;
  await verifySuperAdmin(callerUid);

  const data = request.data as {
    targetUid?: string;
    role?: RoleKey;
    name?: string;
    email?: string;
    permissions?: Record<string, boolean>;
  };

  const { targetUid, role, name, email } = data;
  if (!targetUid || !role || !name || !email) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }
  if (!DEFAULT_PERMISSIONS[role]) {
    throw new HttpsError("invalid-argument", "Invalid role");
  }

  const permissions =
    data.permissions && Object.keys(data.permissions).length > 0
      ? data.permissions
      : DEFAULT_PERMISSIONS[role];

  await setAdminClaims(targetUid, role, name, email, permissions, callerUid!);

  logger.info("setAdminRole success", { targetUid, role, callerUid });
  return { success: true, targetUid, role };
});

export const removeAdminRole = onCall(
  { region: "europe-west1" },
  async (request) => {
    const callerUid = request.auth?.uid;
    await verifySuperAdmin(callerUid);

    const targetUid = request.data?.targetUid as string | undefined;
    if (!targetUid) {
      throw new HttpsError("invalid-argument", "targetUid is required");
    }
    if (targetUid === callerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot remove your own admin role"
      );
    }

    const db = getFirestore();
    await db.collection("admin_roles").doc(targetUid).delete();
    await db.collection("users").doc(targetUid).set(
      {
        status: "user",
        adminRole: FieldValue.delete(),
      },
      { merge: true }
    );

    const auth = getAuth();
    await auth.setCustomUserClaims(targetUid, {
      role: "user",
      userStatus: "user",
      adminRole: null,
    });

    logger.info("removeAdminRole success", { targetUid, callerUid });
    return { success: true, targetUid };
  }
);

export const softDeleteAccount = onCall(
  { region: "europe-west1" },
  async (request) => {
    const callerUid = request.auth?.uid;
    await verifyDeletePermission(callerUid);

    const data = request.data as {
      targetUid?: string;
      targetType?: string;
    };
    const targetUid = data.targetUid;
    const targetType = data.targetType ?? "user";

    if (!targetUid) {
      throw new HttpsError("invalid-argument", "targetUid is required");
    }
    if (targetUid === callerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot delete your own account"
      );
    }

    const db = getFirestore();
    const deletePayload = {
      isDeleted: true,
      deletedAt: FieldValue.serverTimestamp(),
      deletedBy: callerUid,
    };

    await db.collection("users").doc(targetUid).set(deletePayload, {
      merge: true,
    });

    if (targetType === "craftsman") {
      await db.collection("craftsmen").doc(targetUid).set(
        {
          ...deletePayload,
          visibility: "hidden",
          accountStatus: "deleted",
        },
        { merge: true }
      );
    } else if (targetType === "store") {
      const stores = await db
        .collection("markets")
        .where("ownerUid", "==", targetUid)
        .get();
      for (const doc of stores.docs) {
        await doc.ref.set(
          {
            ...deletePayload,
            isVisible: false,
            isActive: false,
            accountStatus: "deleted",
          },
          { merge: true }
        );
      }
    } else if (targetType === "courier") {
      await db.collection("courier_requests").doc(targetUid).set(
        {
          ...deletePayload,
          status: "deleted",
          accountStatus: "deleted",
        },
        { merge: true }
      );
    }

    logger.info("softDeleteAccount success", {
      targetUid,
      targetType,
      callerUid,
    });
    return { success: true, targetUid, targetType };
  }
);

export const restoreAccount = onCall(
  { region: "europe-west1" },
  async (request) => {
    const callerUid = request.auth?.uid;
    await verifyDeletePermission(callerUid);

    const data = request.data as {
      targetUid?: string;
      targetType?: string;
    };
    const targetUid = data.targetUid;
    const targetType = data.targetType ?? "user";

    if (!targetUid) {
      throw new HttpsError("invalid-argument", "targetUid is required");
    }

    const db = getFirestore();
    const restorePayload = {
      isDeleted: false,
      deletedAt: FieldValue.delete(),
      deletedBy: FieldValue.delete(),
      restoredAt: FieldValue.serverTimestamp(),
      restoredBy: callerUid,
    };

    await db.collection("users").doc(targetUid).set(restorePayload, {
      merge: true,
    });

    if (targetType === "craftsman") {
      await db.collection("craftsmen").doc(targetUid).set(
        {
          isDeleted: false,
          deletedAt: FieldValue.delete(),
          deletedBy: FieldValue.delete(),
          visibility: "public",
          accountStatus: "active",
        },
        { merge: true }
      );
    } else if (targetType === "store") {
      const stores = await db
        .collection("markets")
        .where("ownerUid", "==", targetUid)
        .get();
      for (const doc of stores.docs) {
        await doc.ref.set(
          {
            isDeleted: false,
            deletedAt: FieldValue.delete(),
            deletedBy: FieldValue.delete(),
            accountStatus: "active",
          },
          { merge: true }
        );
      }
    } else if (targetType === "courier") {
      await db.collection("courier_requests").doc(targetUid).set(
        {
          isDeleted: false,
          deletedAt: FieldValue.delete(),
          deletedBy: FieldValue.delete(),
          accountStatus: "active",
        },
        { merge: true }
      );
    }

    logger.info("restoreAccount success", { targetUid, targetType, callerUid });
    return { success: true, targetUid, targetType };
  }
);
