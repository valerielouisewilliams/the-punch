const Like = require('../models/Like');
const Post = require('../models/Post');

const likeController = {
  // Like a post
  async likePost(req, res) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      // Check if post exists
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      // Check if already liked
      const alreadyLiked = await Like.exists(postId, userId);
      if (alreadyLiked) {
        return res.status(400).json({ error: 'Already liked this post' });
      }

      const like = await Like.create({
        post_id: postId,
        user_id: userId
      });

      res.status(201).json({
        message: 'Post liked successfully',
        like
      });
    } catch (error) {
      console.error('Like post error:', error);
      
      if (error.message === 'Already liked this post') {
        return res.status(400).json({ error: error.message });
      }

      res.status(500).json({ 
        error: 'Failed to like post',
        details: error.message 
      });
    }
  },

  // Unlike a post
  async unlikePost(req, res) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      // Check if post exists
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      // Check if like exists
      const liked = await Like.exists(postId, userId);
      if (!liked) {
        return res.status(400).json({ error: 'Post not liked yet' });
      }

      const deleted = await Like.delete(postId, userId);

      if (!deleted) {
        return res.status(500).json({ error: 'Failed to unlike post' });
      }

      res.json({
        message: 'Post unliked successfully'
      });
    } catch (error) {
      console.error('Unlike post error:', error);
      res.status(500).json({ 
        error: 'Failed to unlike post',
        details: error.message 
      });
    }
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