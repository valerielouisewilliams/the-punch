const express = require('express');
const router = express.Router();
const {
  getUserByUsername,
  getUserById,
  getFollowers,
  getFollowing
} = require('../controllers/userController');

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

module.exports = router;