const express = require('express');
const router = express.Router();
const { updateUserProfile } = require('../controllers/userController');
const { authenticateToken } = require('../middleware/authMiddleware');
const {
  searchUsers,
  getUserByUsername,
  getUserById,
  getFollowers,
  getFollowing
} = require('../controllers/userController');

/**
 * @route GET /api/users/search?query=
 * @desc Search users by username or display name (partial + case-insensitive)
 * @access Public
 */
router.get('/search', require('../controllers/userController').searchUsers);

/**
 * @route   GET /api/users/:id
 * @desc    Get user profile by ID
 * @access  Public
 */
router.get('/:id', getUserById);

/**
 * @route   GET /api/users/username/:username
 * @desc    Get user profile by username
 * @access  Public
 */
router.get('/username/:username', getUserByUsername);

/**
 * @route   GET /api/users/:id/followers
 * @desc    Get user's followers
 * @access  Public
 */
router.get('/:id/followers', getFollowers);

/**
 * @route   GET /api/users/:id/following
 * @desc    Get users that this user is following
 * @access  Public
 */
router.get('/:id/following', getFollowing);

/**
 * @route PUT /api/users/me
 * @desc Update current user's profile
 * @access Private
 */
router.put('/me', authenticateToken, updateUserProfile);

module.exports = router;