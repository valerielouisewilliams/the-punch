const admin = require("../config/firebaseAdmin");
const DeviceToken = require("../models/DeviceToken");

async function registerDeviceToken(req, res) {
  try {
    const userId = req.user.id;
    const { token, platform } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: "token is required" });
    }

    await DeviceToken.upsert({ userId, token, platform: platform || "ios" });

    return res.json({ success: true, message: "Device token saved" });
  } catch (err) {
    console.error("registerDeviceToken error:", err);
    return res.status(500).json({ success: false, message: "Could not save device token" });
  }
}

async function testPush(req, res) {
  try {
    const userId = req.user.id;
    const tokens = await DeviceToken.getActiveTokensByUserId(userId);

    if (tokens.length === 0) {
      return res.status(404).json({ success: false, message: "No active device tokens for user" });
    }

    const multicastMessage = {
      tokens,
      notification: {
        title: "Test Punch 🥊",
        body: "If you see this, push is working 💥",
      },
      data: {
        type: "TEST",
      },
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
          return DeviceToken.deactivate(tokens[i]);
        }
        return null;
      })
    );

    return res.json({
      success: true,
      message: "Test push sent (attempted)",
      data: {
        attempted: tokens.length,
        successCount: resp.successCount,
        failureCount: resp.failureCount,
      },
    });
  } catch (err) {
    console.error("testPush error:", err);
    return res.status(500).json({ success: false, message: "Could not send test push" });
  }
}

module.exports = { registerDeviceToken, testPush };
