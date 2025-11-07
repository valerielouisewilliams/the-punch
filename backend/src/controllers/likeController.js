const Like = require('../models/Like');
const Post = require('../models/Post');
const { pool } = require('../config/database');

const likeController = {
  // Like a post
  async likePost(req, res) {
    const postId = Number(req.params.postId);
    const userId = req.user.id;
    
    const sql = `INSERT IGNORE INTO likes (post_id, user_id, created_at)
                VALUES (?, ?, NOW())`;
    
    const [result] = await pool.execute(sql, [postId, userId]);
    const already = result.affectedRows === 0; // duplicate
    
    return res.json({
      message: already ? "Already liked" : "Post liked successfully",
      like: already ? null : { 
        id: result.insertId, 
        post_id: postId, 
        user_id: userId, 
        created_at: new Date().toISOString() 
      }
    });
  },

// Unlike a post
  async unlikePost(req, res) {
    const postId = Number(req.params.postId);
    const userId = req.user.id;
    
    const sql = `DELETE FROM likes 
                WHERE post_id = ? AND user_id = ?`;
    
    const [result] = await pool.execute(sql, [postId, userId]);
    
    const wasDeleted = result.affectedRows > 0;
    
    return res.json({
      message: wasDeleted ? "Post unliked successfully" : "Like not found",
      like: null
    });
  },

  // Get all likes for a post
  async getLikesByPost(req, res) {
    try {
      const { postId } = req.params;

      // Check if post exists
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      const likes = await Like.findByPostId(postId);
      const count = await Like.countByPostId(postId);

      res.json({
        count,
        likes
      });
    } catch (error) {
      console.error('Get likes error:', error);
      res.status(500).json({ 
        error: 'Failed to get likes',
        details: error.message 
      });
    }
  },

  // Check if current user liked a post
  async checkIfLiked(req, res) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      const liked = await Like.exists(postId, userId);

      res.json({
        liked
      });
    } catch (error) {
      console.error('Check like error:', error);
      res.status(500).json({ 
        error: 'Failed to check like status',
        details: error.message 
      });
    }
  }
};

module.exports = likeController;