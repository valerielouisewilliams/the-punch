const express = require("express");
const router = express.Router();

const { authenticateToken } = require("../middleware/authMiddleware");
const { listInbox } = require("../controllers/notificationInboxController");
router.get("/", authenticateToken, listInbox);

module.exports = router;