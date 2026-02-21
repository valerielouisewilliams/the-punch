const NotificationInbox = require("../models/NotificationInbox");

async function listInbox(req, res) {
  try {
    const userId = req.user.id;
    const limit = Math.min(parseInt(req.query.limit || "30", 10), 100);

    const items = await NotificationInbox.listForUser({ userId, limit });

    return res.json({ success: true, data: items });
  } catch (err) {
    console.error("listInbox error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch inbox" });
  }
}

async function unreadCount(req, res) {
  try {
    const userId = req.user.id;
    const count = await NotificationInbox.unreadCount(userId);

    return res.json({ success: true, data: { count } });
  } catch (err) {
    console.error("unreadCount error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch unread count" });
  }
}

async function markRead(req, res) {
  try {
    const userId = req.user.id;
    const notificationId = parseInt(req.params.id, 10);

    const ok = await NotificationInbox.markRead({ userId, notificationId });

    if (!ok) {
      return res.status(404).json({ success: false, message: "Notification not found" });
    }

    return res.json({ success: true });
  } catch (err) {
    console.error("markRead error:", err);
    return res.status(500).json({ success: false, message: "Failed to mark read" });
  }
}

async function markAllRead(req, res) {
  try {
    const userId = req.user.id;
    const updated = await NotificationInbox.markAllRead(userId);

    return res.json({ success: true, data: { updated } });
  } catch (err) {
    console.error("markAllRead error:", err);
    return res.status(500).json({ success: false, message: "Failed to mark all read" });
  }
}

module.exports = { listInbox, unreadCount, markRead, markAllRead };