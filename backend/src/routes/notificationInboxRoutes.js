const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const {
  listInbox,
  unreadCount,
  markRead,
  markAllRead
} = require("../controllers/notificationInboxController");

router.get("/", authenticateToken, listInbox);
router.get("/unread-count", authenticateToken, unreadCount);
router.patch("/read-all", authenticateToken, markAllRead);
router.patch("/:id/read", authenticateToken, markRead);

module.exports = router;