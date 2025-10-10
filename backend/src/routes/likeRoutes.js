const express = require('express');
const router = express.Router();
const {
  likePost,
  unlikePost,
  getLikesByPost,
  checkIfLiked
} = require('../controllers/likeController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/likes/post/:postId
 * @desc    Like a post
 * @access  Private
 */
router.post('/post/:postId', authenticateToken, likePost);

/**
 * @route   DELETE /api/likes/post/:postId
 * @desc    Unlike a post
 * @access  Private
 */
router.delete('/post/:postId', authenticateToken, unlikePost);

/**
 * @route   GET /api/likes/post/:postId
 * @desc    Get all likes for a post
 * @access  Public
 */
router.get('/post/:postId', getLikesByPost);

/**
 * @route   GET /api/likes/post/:postId/check
 * @desc    Check if current user liked a post
 * @access  Private
 */
router.get('/post/:postId/check', authenticateToken, checkIfLiked);

module.exports = router;