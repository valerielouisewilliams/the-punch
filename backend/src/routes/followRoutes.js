const express = require('express');
const router = express.Router();
const {
  followUser,
  unfollowUser,
  checkIfFollowing,
  getFollowers,
  getFollowing
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

/**
 * @route   GET /api/follows/user/:userId/followers
 * @desc    Get list of followers for a user
 * @access  Private (or Public, up to you)
 */
router.get('/user/:userId/followers', authenticateToken, getFollowers);

/**
 * @route   GET /api/follows/user/:userId/following
 * @desc    Get list of users that a user is following
 * @access  Private (or Public, up to you)
 */
router.get('/user/:userId/following', authenticateToken, getFollowing);

module.exports = router;