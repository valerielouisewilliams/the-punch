const express = require('express');
const router = express.Router();
const { reportPost } = require('../controllers/reportController');
const { authenticateToken } = require('../middleware/authMiddleware');

// POST /api/reports
router.post('/', authenticateToken, reportPost);

module.exports = router;