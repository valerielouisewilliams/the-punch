const express = require('express');
const { getFeed } = require('../controllers/feedController');
const { authenticateToken } = require('../middleware/authMiddleware');

const router = express.Router();

// GET /api/feed - Get authenticated user's feed
router.get('/', authenticateToken, getFeed);

module.exports = router;