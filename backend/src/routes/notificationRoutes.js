const express = require("express");
const router = express.Router();

const { authenticateToken } = require("../middleware/authMiddleware");
const { registerDeviceToken, testPush } = require("../controllers/notificationController");

router.post("/device-token", authenticateToken, registerDeviceToken);
router.post("/test", authenticateToken, testPush);

module.exports = router;
