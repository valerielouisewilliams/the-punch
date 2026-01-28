// const express = require('express');
// const router = express.Router();
// const { register, login, getCurrentUser } = require('../controllers/authController');
// const { authenticateToken } = require('../middleware/authMiddleware');

// /**
//  * @route   POST /api/auth/register
//  * @desc    Register a new user
//  * @access  Public
//  */
// router.post('/register', register);

// /**
//  * @route   POST /api/auth/login
//  * @desc    Login user and get token
//  * @access  Public
//  */
// router.post('/login', login);

// /**
//  * @route   GET /api/auth/me
//  * @desc    Get current authenticated user
//  * @access  Private
//  */
// router.get('/me', authenticateToken, getCurrentUser);

// // In your auth routes (e.g., routes/authRoutes.js)
// router.post('/register-firebase', async (req, res) => {
//   try {
//     const { email, username, firebaseUid } = req.body;

//     // Check if user already exists
//     const [existing] = await pool.execute(
//       'SELECT id FROM users WHERE email = ? OR firebase_uid = ?',
//       [email, firebaseUid]
//     );

//     if (existing.length > 0) {
//       return res.status(400).json({ 
//         success: false, 
//         error: 'User already exists' 
//       });
//     }

//     // Create user in MySQL
//     const [result] = await pool.execute(
//       'INSERT INTO users (email, username, firebase_uid, created_at) VALUES (?, ?, ?, NOW())',
//       [email, username, firebaseUid]
//     );

//     const [newUser] = await pool.execute(
//       'SELECT id, email, username, firebase_uid FROM users WHERE id = ?',
//       [result.insertId]
//     );

//     res.json({
//       success: true,
//       data: newUser[0]
//     });

//   } catch (error) {
//     console.error('Registration error:', error);
//     res.status(500).json({ 
//       success: false, 
//       error: 'Registration failed' 
//     });
//   }
// });

// module.exports = router;

const express = require('express');
const router = express.Router();
const { register, login, getCurrentUser } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user (handles both JWT and Firebase)
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