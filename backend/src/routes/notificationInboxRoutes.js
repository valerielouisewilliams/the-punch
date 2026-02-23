const express = require('express');
const router = express.Router();

const notificationInboxController = require('../controllers/notificationInboxController');
const { authenticateToken } = require('../middleware/authMiddleware');

// List inbox
router.get('/', authenticateToken, notificationInboxController.listInbox);

// Unread count
router.get('/unread-count', authenticateToken, notificationInboxController.unreadCount);

// Mark one as read
router.patch('/:id/read', authenticateToken, notificationInboxController.markRead);

// Mark all as read
router.patch('/read-all', authenticateToken, notificationInboxController.markAllRead);

// Soft delete
router.delete('/:id', authenticateToken, notificationInboxController.deleteNotification);


module.exports = router;