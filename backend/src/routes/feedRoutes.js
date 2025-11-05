const express = require('express');
const { getUserFeed, getUserPosts } = require('../controllers/feedController');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

// GET /api/feed - Get authenticated user's feed
router.get('/', authenticateToken, getUserFeed);

// GET /api/feed/user/:userId - Get specific user's posts
router.get('/user/:userId', authenticateToken, getUserPosts);

module.exports = router;