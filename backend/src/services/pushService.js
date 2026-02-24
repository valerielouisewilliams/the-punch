const admin = require("../config/firebaseAdmin");
const DeviceToken = require("../models/DeviceToken");

const pushService = {
  async sendToUser(userId, { notification, data }) {
    const tokens = await DeviceToken.getActiveTokensByUserId(userId);

    if (!tokens || tokens.length === 0) {
      return { attempted: 0, successCount: 0, failureCount: 0, skipped: "no_tokens" };
    }

    const multicastMessage = {
      tokens,
      notification,
      data: data || {},
    };

    const resp = await admin.messaging().sendEachForMulticast(multicastMessage);
    console.log("FCM multicast:", {
      successCount: resp.successCount,
      failureCount: resp.failureCount,
      codes: resp.responses.map(r => r.success ? "ok" : r.error?.code),
    });
    // deactivate dead tokens
    const deadCodes = new Set([
      "messaging/registration-token-not-registered",
      "messaging/invalid-registration-token",
    ]);

    await Promise.all(
      resp.responses.map((r, i) => {
        if (!r.success && r.error?.code && deadCodes.has(r.error.code)) {
          return DeviceToken.deactivate(tokens[i]);
        }
        return null;
      })
    );

    return {
      attempted: tokens.length,
      successCount: resp.successCount,
      failureCount: resp.failureCount,
    };
  },
};

module.exports = pushService;
