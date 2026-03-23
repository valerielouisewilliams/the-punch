const express = require('express');
const router = express.Router();
const {
  sendPunch,
  getReceivedPunches,
  getSentPunches
} = require('../controllers/punchController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/punches/user/:userId
 * @desc    Send a punch to a user
 * @access  Private
 */
router.post('/user/:userId', authenticateToken, sendPunch);

/**
 * @route   GET /api/punches/received
 * @desc    Get punches received by current user
 * @access  Private
 */
router.get('/received', authenticateToken, getReceivedPunches);

/**
 * @route   GET /api/punches/sent
 * @desc    Get punches sent by current user
 * @access  Private
 */
router.get('/sent', authenticateToken, getSentPunches);

module.exports = router;