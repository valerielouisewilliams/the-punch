const Notification = require('../models/Notification');

const notificationInboxController = {
  // GET /api/inbox?limit=50&offset=0&unreadOnly=true
  async listInbox(req, res) {
    try {
      const userId = req.user.id;

      let { limit = 50, offset = 0, unreadOnly = 'false' } = req.query;
      const unread = String(unreadOnly).toLowerCase() === 'true';

      const items = await Notification.listForUser(userId, {
        limit,
        offset,
        unreadOnly: unread
      });

      res.json({
        success: true,
        data: items,
        count: items.length
      });
    } catch (error) {
      console.error('listInbox error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch inbox'
      });
    }
  },

  // PATCH /api/inbox/:id/read
  async markRead(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const ok = await Notification.markRead(id, userId);
      if (!ok) {
        return res.status(404).json({ success: false, message: 'Notification not found' });
      }

      res.json({ success: true, message: 'Marked as read' });
    } catch (error) {
      console.error('markRead error:', error);
      res.status(500).json({ success: false, message: 'Failed to mark read' });
    }
  },

  // PATCH /api/inbox/read-all
  async markAllRead(req, res) {
    try {
      const userId = req.user.id;
      const updated = await Notification.markAllRead(userId);
      res.json({ success: true, message: 'Marked all as read', updated });
    } catch (error) {
      console.error('markAllRead error:', error);
      res.status(500).json({ success: false, message: 'Failed to mark all read' });
    }
  },

  // DELETE /api/inbox/:id  (soft delete)
  async deleteNotification(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const ok = await Notification.softDelete(id, userId);
      if (!ok) {
        return res.status(404).json({ success: false, message: 'Notification not found' });
      }

      res.json({ success: true, message: 'Deleted' });
    } catch (error) {
      console.error('deleteNotification error:', error);
      res.status(500).json({ success: false, message: 'Failed to delete' });
    }
  }
};

module.exports = notificationInboxController;