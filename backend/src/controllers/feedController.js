// src/controllers/feedController.js
const Feed = require('../models/Feed');

// GET /api/feed  (auth required)
const getUserFeed = async (req, res) => {
  try {
    const { limit = 20, offset = 0, includeOwn = false } = req.query;

    const validLimit  = Math.min(Math.max(1, parseInt(limit, 10)  || 20), 100);
    const validOffset = Math.max(0, parseInt(offset, 10) || 0);
    const includeOwnB = includeOwn === 'true' || includeOwn === '1' || includeOwn === true;

    const posts = await Feed.getUserFeed(
      req.user.id,     // viewer user id (number from auth middleware)
      validLimit,
      validOffset,
      includeOwnB
    );

    res.status(200).json({
      success: true,
      data: {
        posts,
        pagination: {
          limit: validLimit,
          offset: validOffset,
          hasMore: posts.length === validLimit
        },
        filters: {
          timeWindow: 'last_24h',
          includesOwnPosts: includeOwnB
        }
      }
    });
  } catch (error) {
    console.error('Feed fetch error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch feed' });
  }
};

// GET /api/feed/user/:userId  (auth optional)
const getUserPosts = async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    const validLimit  = Math.min(Math.max(1, parseInt(limit, 10)  || 20), 100);
    const validOffset = Math.max(0, parseInt(offset, 10) || 0);
    const viewerId = req.user?.id ?? null; // optional auth, affect user_has_liked

    const posts = await Feed.getPostsByUser(
      Number(userId),
      viewerId,
      validLimit,
      validOffset
    );

    res.status(200).json({
      success: true,
      data: {
        posts,
        pagination: {
          limit: validLimit,
          offset: validOffset,
          hasMore: posts.length === validLimit
        }
      }
    });
  } catch (error) {
    console.error('Get user posts error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch user posts' });
  }
};

module.exports = { getUserFeed, getUserPosts };