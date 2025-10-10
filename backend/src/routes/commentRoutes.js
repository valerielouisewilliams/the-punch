const express = require('express');
const router = express.Router();
const {
  createComment,
  getCommentsByPost,
  getCommentById,
  deleteComment
} = require('../controllers/commentController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/comments/post/:postId
 * @desc    Create a comment on a post
 * @access  Private
 */
router.post('/post/:postId', authenticateToken, createComment);

/**
 * @route   GET /api/comments/post/:postId
 * @desc    Get all comments for a post
 * @access  Public
 */
router.get('/post/:postId', getCommentsByPost);

/**
 * @route   GET /api/comments/:id
 * @desc    Get a single comment by ID
 * @access  Public
 */
router.get('/:id', getCommentById);

/**
 * @route   DELETE /api/comments/:id
 * @desc    Delete a comment (soft delete)
 * @access  Private (owner only)
 */
router.delete('/:id', authenticateToken, deleteComment);

module.exports = router;