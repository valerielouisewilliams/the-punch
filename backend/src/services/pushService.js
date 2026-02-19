// backend/src/services/pushService.js
const admin = require("../config/firebaseAdmin");
const DeviceToken = require("../models/DeviceToken");

/**
 * Send a push notification to ALL active device tokens for a user.
 * Handles deactivating dead tokens.
 *
 * payload = {
 *   title: string,
 *   body: string,
 *   data?: { [key: string]: string } // FCM requires strings
 * }
 */
async function sendToUser(userId, payload) {
  if (!userId) return { attempted: 0, successCount: 0, failureCount: 0 };

  const tokens = await DeviceToken.getActiveTokensByUserId(userId);

  if (!tokens || tokens.length === 0) {
    return { attempted: 0, successCount: 0, failureCount: 0 };
  }

  return sendToTokens(tokens, payload);
}

async function sendToTokens(tokens, payload) {
  const cleanTokens = (tokens || []).filter(Boolean);
  if (cleanTokens.length === 0) {
    return { attempted: 0, successCount: 0, failureCount: 0 };
  }

  // FCM "data" must be string:string
  const data = {};
  if (payload?.data) {
    for (const [k, v] of Object.entries(payload.data)) {
      data[k] = String(v);
    }
  }

  const multicastMessage = {
    tokens: cleanTokens,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data,
  };

  const resp = await admin.messaging().sendEachForMulticast(multicastMessage);

  // deactivate dead tokens
  const deadCodes = new Set([
    "messaging/registration-token-not-registered",
    "messaging/invalid-registration-token",
  ]);

  await Promise.all(
    resp.responses.map((r, i) => {
      if (!r.success && r.error?.code && deadCodes.has(r.error.code)) {
        return DeviceToken.deactivate(cleanTokens[i]);
      }
      return null;
    })
  );

  return {
    attempted: cleanTokens.length,
    successCount: resp.successCount,
    failureCount: resp.failureCount,
  };
}

module.exports = {
  sendToUser,
  sendToTokens,
};
