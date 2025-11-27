const Comment = require('../models/Comment');
const Post = require('../models/Post');

const commentController = {
  // Create a comment on a post
  async createComment(req, res) {
    try {
      const { postId } = req.params;
      const { text } = req.body;
      const userId = req.user.id;

      // Validate required fields
      if (!text || text.trim().length === 0) {
        return res.status(400).json({ error: 'Comment text is required' });
      }

      // Check if post exists
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      const comment = await Comment.create({
        userId,
        postId,
        text: text.trim()
      });

      res.status(201).json({
        message: 'Comment created successfully',
        comment
      });
    } catch (error) {
      console.error('Create comment error:', error);
      res.status(500).json({ 
        error: 'Failed to create comment',
        details: error.message 
      });
    }
  },

  // Get all comments for a post
  async getCommentsByPost(req, res) {
    try {
      const { postId } = req.params;

      // Check if post exists
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      const comments = await Comment.findByPostId(postId);

      res.json({
        count: comments.length,
        comments
      });
    } catch (error) {
      console.error('Get comments error:', error);
      res.status(500).json({ 
        error: 'Failed to get comments',
        details: error.message 
      });
    }
  },

  // Get a single comment by ID
  async getCommentById(req, res) {
    try {
      const { id } = req.params;

      const comment = await Comment.findById(id);

      if (!comment) {
        return res.status(404).json({ error: 'Comment not found' });
      }

      res.json({
        comment
      });
    } catch (error) {
      console.error('Get comment error:', error);
      res.status(500).json({ 
        error: 'Failed to get comment',
        details: error.message 
      });
    }
  },

  // Delete a comment
  async deleteComment(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // Check if comment exists
      const comment = await Comment.findById(id);
      if (!comment) {
        return res.status(404).json({ error: 'Comment not found' });
      }

      // Check if user owns this comment
      const isOwner = await Comment.isOwner(id, userId);
      if (!isOwner) {
        return res.status(403).json({ 
          error: 'Not authorized to delete this comment' 
        });
      }

      const deleted = await Comment.softDelete(id);

      if (!deleted) {
        return res.status(500).json({ error: 'Failed to delete comment' });
      }

      res.json({
        message: 'Comment deleted successfully'
      });
    } catch (error) {
      console.error('Delete comment error:', error);
      res.status(500).json({ 
        error: 'Failed to delete comment',
        details: error.message 
      });
    }
  }
};

module.exports = commentController;