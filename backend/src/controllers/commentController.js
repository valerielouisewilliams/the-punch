const Comment = require('../models/Comment');
const Post = require('../models/Post');
const pushService = require('../services/pushService');
const { pool } = require('../config/database');
const Notification = require('../models/Notification');

const commentController = {
  // Create a comment on a post
  async createComment(req, res) {
    try {
      const postId = Number(req.params.postId);
      const userId = req.user.id;
      const textRaw = req.body?.text ?? "";
      const text = String(textRaw).trim();

      if (!text) {
        return res.status(400).json({ error: 'Comment text is required' });
      }

      // Check if post exists (you already do this)
      const post = await Post.findById(postId);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      // Create comment
      const comment = await Comment.create({
        userId,
        postId,
        text
      });

      // --- PUSH (only if commenting on someone else's post) ---
      const [[postRow]] = await pool.execute(
        `SELECT user_id FROM posts WHERE id = ? LIMIT 1`,
        [postId]
      );

      const postOwnerId = postRow?.user_id;

      if (postOwnerId && Number(postOwnerId) !== Number(userId)) {
        await Notification.create({
          recipient_user_id: Number(postOwnerId),
          actor_user_id: Number(userId),
          type: 'comment',
          entity_type: 'post',
          entity_id: Number(postId),
          message: null
        });

        const [[commenter]] = await pool.execute(
          `SELECT username FROM users WHERE id = ? LIMIT 1`,
          [userId]
        );

        const username = commenter?.username || "Someone";
        const preview = text.length > 80 ? `${text.slice(0, 80)}…` : text;

        await pushService.sendToUser(postOwnerId, {
          notification: {
            title: "New comment 💬",
            body: `${username}: ${preview}`,
          },
          data: {
            type: "COMMENT",
            postId: String(postId),
            commentId: String(comment?.id ?? ""),
            fromUserId: String(userId),
          },
        });
      }
      // -------------------------------------------------------

      return res.status(201).json({
        message: 'Comment created successfully',
        comment
      });
    } catch (error) {
      console.error('Create comment error:', error);
      return res.status(500).json({
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