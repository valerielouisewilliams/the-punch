const express = require('express');
const router = express.Router();
const {
  createPost,
  getAllPosts,
  getPostById,
  updatePost,
  deletePost,
  getPostsByUserId
} = require('../controllers/postController');
const { authenticateToken, optionalAuth } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/posts
 * @desc    Create a new post
 * @access  Private
 */
router.post('/', authenticateToken, createPost);

/**
 * @route   GET /api/posts
 * @desc    Get all posts (with pagination)
 * @access  Public
 * @query   limit - number of posts to return (default: 50)
 * @query   offset - number of posts to skip (default: 0)
 */
router.get('/', getAllPosts);

/**
 * @route   GET /api/posts/:id
 * @desc    Get single post by ID with comments and likes
 * @access  Public
 */
router.get('/:id', getPostById);

/**
 * @route   GET /api/posts/user/:user_id
 * @desc    Get all posts by a specific user
 * @access  Public
 */
router.get('/user/:user_id', getPostsByUserId);

/**
 * @route   PUT /api/posts/:id
 * @desc    Update a post
 * @access  Private (owner only)
 */
router.put('/:id', authenticateToken, updatePost);

/**
 * @route   DELETE /api/posts/:id
 * @desc    Delete a post (soft delete)
 * @access  Private (owner only)
 */
router.delete('/:id', authenticateToken, deletePost);

module.exports = router;