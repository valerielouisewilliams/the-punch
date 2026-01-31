const express = require('express');
const router = express.Router();
const { register, login, getCurrentUser, session, completeProfile } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');

// new routes for Firebase testing
router.post('/session', session);
router.post('/complete-profile', completeProfile);
router.get('/me', authenticateToken, getCurrentUser);

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user and get token
 * @access  Public
 */
router.post('/login', login);

/**
 * @route   GET /api/auth/me
 * @desc    Get current authenticated user
 * @access  Private
 */
router.get('/me', authenticateToken, getCurrentUser);

module.exports = router;