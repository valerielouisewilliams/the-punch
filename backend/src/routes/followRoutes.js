const express = require('express');
const router = express.Router();
const {
  followUser,
  unfollowUser,
  checkIfFollowing
} = require('../controllers/followController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/follows/user/:userId
 * @desc    Follow a user
 * @access  Private
 */
router.post('/user/:userId', authenticateToken, followUser);

/**
 * @route   DELETE /api/follows/user/:userId
 * @desc    Unfollow a user
 * @access  Private
 */
router.delete('/user/:userId', authenticateToken, unfollowUser);

/**
 * @route   GET /api/follows/user/:userId/check
 * @desc    Check if current user is following another user
 * @access  Private
 */
router.get('/user/:userId/check', authenticateToken, checkIfFollowing);

module.exports = router;