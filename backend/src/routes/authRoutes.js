const express = require('express');
const router = express.Router();
const { getCurrentUser, session, completeProfile, updateAccountInformation } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');

// new routes for Firebase testing
router.post('/session', session);
router.post('/complete-profile', completeProfile);
router.get('/me', authenticateToken, getCurrentUser);
router.patch('/me/account-info', authenticateToken, updateAccountInformation);

module.exports = router;
