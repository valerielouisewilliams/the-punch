// src/controllers/feedController.js
const PostFormatter = require('../utils/postFormatter');
const { pool } = require('../config/database');

const feedController = {
  // GET /api/feed
  async getFeed(req, res) {
    try {
      // query params with sane defaults
      let { limit = 20, offset = 0, days = 2, includeOwn = '0' } = req.query;
      const viewerId = req.user?.id || 0;

      // sanitize
      limit = Math.min(Math.max(1, parseInt(limit) || 20), 100);
      offset = Math.max(0, parseInt(offset) || 0);
      days = Math.max(1, parseInt(days) || 2);
      const includeSelf = includeOwn === '1' || includeOwn === 'true';

      // WHERE clause for posts from people I follow (+ me if includeOwn)
      const whereClause = `
        p.is_deleted = 0
        AND p.created_at >= NOW() - INTERVAL ? DAY
        AND (
          p.user_id IN (SELECT following_id FROM follows WHERE follower_id = ?)
          ${includeSelf ? ' OR p.user_id = ?' : ''}
        )
      `;

      // params that match placeholders in whereClause (PostFormatter will prepend viewerId)
      const params = includeSelf
        ? [days, viewerId, viewerId]
        : [days, viewerId];

      // Use the shared formatter to guarantee canonical shape
      const posts = await PostFormatter.getPostsWithStats(whereClause, params, viewerId);

      // Simple pagination (offset is already applied via LIMIT/OFFSET inside getPostsWithStats’s SELECT)
      res.json({
        success: true,
        data: {
          posts,
          pagination: {
            limit,
            offset,
            hasMore: posts.length === limit
          },
          filters: {
            timeWindow: `last_${days}d`,
            includesOwnPosts: includeSelf
          }
        }
      });
    } catch (err) {
      console.error('Feed error:', err);
      res.status(500).json({ success: false, message: 'Failed to load feed' });
    }
  }
};

module.exports = feedController;
