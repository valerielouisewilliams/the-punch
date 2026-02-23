const express = require('express');
const router = express.Router();

// Import all route modules
const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const postRoutes = require('./postRoutes');
const commentRoutes = require('./commentRoutes');
const likeRoutes = require('./likeRoutes');
const followRoutes = require('./followRoutes');
const feedRoutes = require('./feedRoutes')
const mediaRoutes = require('./mediaRoutes');
const notificationRoutes = require("./notificationRoutes");
const notificationInboxRoutes = require('./routes/notificationInboxRoutes'); // adjust path to match your project

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/posts', postRoutes);
router.use('/comments', commentRoutes);
router.use('/likes', likeRoutes);
router.use('/follows', followRoutes);
router.use('/feed', feedRoutes);
router.use('/media', mediaRoutes);
router.use("/notifications", notificationRoutes);
router.use('/inbox', notificationInboxRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;