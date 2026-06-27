const auth = require("firebase-tools/lib/auth");
const scopes = require("firebase-tools/lib/scopes");
const https = require("https");

function httpReq(url, token, method, bodyObj) {
  return new Promise((resolve, reject) => {
    const body = bodyObj ? JSON.stringify(bodyObj) : null;
    const headers = { Authorization: `Bearer ${token}` };
    if (body) {
      headers["Content-Type"] = "application/json";
      headers["Content-Length"] = Buffer.byteLength(body);
    }
    const req = https.request(url, { method, headers }, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => resolve({ status: res.statusCode, body: data }));
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

const project = "bazar-suez-app";
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;

function boolField(v) {
  return { booleanValue: v };
}

(async () => {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error("Not logged in to Firebase CLI");
  const tok = await auth.getAccessToken(account.tokens.refresh_token, [
    scopes.CLOUD_PLATFORM,
  ]);
  const token = tok.access_token;

  let pageToken = null;
  let updated = 0;
  let skipped = 0;
  let total = 0;

  do {
    const listUrl =
      `${base}/markets?pageSize=100` + (pageToken ? `&pageToken=${pageToken}` : "");
    const listRes = await httpReq(listUrl, token, "GET");
    if (listRes.status !== 200) {
      console.error("LIST FAILED:", listRes.status, listRes.body);
      process.exit(1);
    }
    const listObj = JSON.parse(listRes.body);
    const docs = listObj.documents || [];
    pageToken = listObj.nextPageToken || null;

    for (const doc of docs) {
      total++;
      const fields = doc.fields || {};
      const id = doc.name.split("/").pop();
      const current = fields.licenseAutoRenew;

      if (current && current.booleanValue === true) {
        skipped++;
        continue;
      }

      const patchUrl = `${base}/markets/${id}?updateMask.fieldPaths=licenseAutoRenew`;
      const patchRes = await httpReq(patchUrl, token, "PATCH", {
        fields: { licenseAutoRenew: boolField(true) },
      });

      if (patchRes.status === 200) {
        updated++;
        console.log(`updated ${id}`);
      } else {
        console.error(`failed ${id}:`, patchRes.status, patchRes.body);
      }
    }
  } while (pageToken);

  console.log(`\nDone. total=${total} updated=${updated} skipped=${skipped}`);
})().catch((e) => {
  console.error("ERROR:", e.message || e);
  process.exit(1);
});
