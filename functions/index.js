/**
 * Firebase Functions — Roblox RTDB Proxy
 *
 * Exposes two HTTP endpoints that Roblox's HttpService calls:
 *
 *   POST /rbxLog   — write a structured log entry to RTDB /logs/<category>
 *   GET  /rbxFlags — read feature flags from RTDB /config/featureFlags
 *
 * Both endpoints require the header:
 *   x-roblox-secret: <value of ROBLOX_SECRET environment variable>
 *
 * To set the secret (one-time setup):
 *   firebase functions:secrets:set ROBLOX_SECRET
 *   (then type any strong random string when prompted)
 *
 * Deploy:
 *   npm install  (inside the functions/ directory)
 *   cd ..
 *   firebase deploy --only functions
 *
 * RTDB rules are set to deny all direct access — only this proxy
 * (running as Admin SDK) can read/write.
 */

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getDatabase } = require("firebase-admin/database");

initializeApp();

// Pull the shared secret from Secret Manager (set via: firebase functions:secrets:set ROBLOX_SECRET)
const ROBLOX_SECRET = defineSecret("ROBLOX_SECRET");

/**
 * Validates the x-roblox-secret header.
 * Returns true if valid, sends 403 and returns false if not.
 */
function checkSecret(req, res, secret) {
  const header = req.headers["x-roblox-secret"];
  if (!header || header !== secret) {
    console.warn("[rbx-proxy] Unauthorized request from", req.ip);
    res.status(403).json({ error: "Forbidden" });
    return false;
  }
  return true;
}

/**
 * POST /rbxLog
 * Body (JSON): { category: string, entry: object }
 * Pushes the entry to RTDB at /logs/<category>/<auto-id>
 */
exports.rbxLog = onRequest(
  { secrets: [ROBLOX_SECRET], cors: false },
  async (req, res) => {
    if (!checkSecret(req, res, ROBLOX_SECRET.value())) return;

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method Not Allowed" });
    }

    const { category, entry } = req.body ?? {};

    if (typeof category !== "string" || !category || !entry) {
      return res.status(400).json({ error: "Missing or invalid category / entry" });
    }

    // Sanitize: strip keys that start with . (Firebase reserved)
    const safeCategory = category.replace(/[.#$\[\]]/g, "_").substring(0, 64);

    try {
      const db = getDatabase();
      await db.ref(`logs/${safeCategory}`).push(entry);
      res.json({ ok: true });
    } catch (err) {
      console.error("[rbxLog] write failed:", err);
      res.status(500).json({ error: "Internal error" });
    }
  }
);

/**
 * GET /rbxFlags
 * Returns the current feature flags object from RTDB /config/featureFlags
 * Returns {} if the path doesn't exist yet.
 */
exports.rbxFlags = onRequest(
  { secrets: [ROBLOX_SECRET], cors: false },
  async (req, res) => {
    if (!checkSecret(req, res, ROBLOX_SECRET.value())) return;

    if (req.method !== "GET") {
      return res.status(405).json({ error: "Method Not Allowed" });
    }

    try {
      const db = getDatabase();
      const snapshot = await db.ref("config/featureFlags").once("value");
      res.json(snapshot.val() ?? {});
    } catch (err) {
      console.error("[rbxFlags] read failed:", err);
      res.status(500).json({ error: "Internal error" });
    }
  }
);
