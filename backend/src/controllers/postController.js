// src/controllers/postController.js - UPDATED VERSION
const Post = require('../models/Post');
const Comment = require('../models/Comment');
const Like = require('../models/Like');
const PostFormatter = require('../utils/postFormatter');

const postController = {
  // Create a new post
  async createPost(req, res) {
    try {
      const { text } = req.body;
      const feelingEmoji = req.body.feeling_emoji || null;
      const feelingName  = req.body.feeling_name  || null;
      const user_id = req.user.id;

      //DEBUG
      console.log("BODY:", req.body);
      console.log("snake:", req.body.feeling_emoji, req.body.feeling_name);
      console.log("camel:", req.body.feelingEmoji, req.body.feelingName);

      // Validate required fields
      if (!text || text.trim().length === 0) {
        return res.status(400).json({ error: 'Post text is required' });
      }
      
      const post = await Post.create({ 
        user_id, 
        text: text.trim(), 
        feeling_emoji: feelingEmoji,
        feeling_name: feelingName
      });

      // Format the post with stats
      const formattedPost = await PostFormatter.formatPost(post, user_id);

      res.status(201).json({
        success: true,
        message: 'Post created successfully',
        data: formattedPost
      });
    } catch (error) {
      console.error('Create post error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to create post',
        details: error.message 
      });
    }
  },

  // Get a single post by ID with full details
  async getPostById(req, res) {
    try {
      const { id } = req.params;
      const viewerId = req.user?.id ?? 0;   // 0 = safe non-null fallback

      const post = await Post.findById(id);

      if (!post) {
        return res.status(404).json({ 
          success: false,
          error: 'Post not found' 
        });
      }

      // Format with stats
      const formattedPost = await PostFormatter.formatPost(post, viewerId);

      // Get comments separately if needed
      const comments = await Comment.findByPostId(id);

      res.json({
        success: true,
        data: {
          ...formattedPost,
          comments // Add comments for detail view
        }
      });
    } catch (error) {
      console.error('Get post error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to get post',
        details: error.message 
      });
    }
  },

  // Get posts by user ID - NOW WITH STATS!
  async getPostsByUserId(req, res) {
    try {
      const { user_id } = req.params;
      const viewerId = req.user?.id || null;

      if (isNaN(user_id)) {
        return res.status(400).json({
          success: false,
          message: 'User ID must be a valid number'
        });
      }

      // Use the efficient query with stats
      const formattedPosts = await PostFormatter.getPostsWithStats(
        'p.user_id = ? AND p.is_deleted = 0',
        [parseInt(user_id)],
        viewerId
      );

      res.json({
        success: true,
        data: formattedPosts,
        count: formattedPosts.length
      });

    } catch (error) {
      console.error('Get user posts error:', error);
      res.status(500).json({
        success: false,
        message: 'Could not retrieve user posts'
      });
    }
  },

  // Get all posts (with pagination)
async getAllPosts(req, res) {
  try {
    // Extract from query FIRST
    let { limit = 50, offset = 0 } = req.query;
    const viewerId = req.user?.id || 0; // safe fallback for EXISTS()

    // Sanitize them as numbers
    limit = Math.min(Math.max(1, parseInt(limit) || 50), 100);
    offset = Math.max(0, parseInt(offset) || 0);

    const { pool } = require('../config/database');

    // Inline limit + offset, bind only viewerId
    const sql = `
      SELECT 
        p.*,
        u.username,
        u.display_name,
        u.avatar_url,
        (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as like_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0) as comment_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?) as user_has_liked
      FROM posts p
      INNER JOIN users u ON p.user_id = u.id
      WHERE p.is_deleted = 0
      ORDER BY p.created_at DESC
      LIMIT ${limit} OFFSET ${offset};
    `;

    const [rows] = await pool.execute(sql, [viewerId]);

    // Important: resolve async formatPost calls
    const formatted = await Promise.all(rows.map(row => PostFormatter.formatPost(row, viewerId)));

    res.json({
      success: true,
      data: formatted,
      count: formatted.length,
      pagination: {
        limit,
        offset,
        hasMore: formatted.length === limit
      }
    });

  } catch (error) {
    console.error('Get posts error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve posts'
    });
  }
},

  // Update a post
  async updatePost(req, res) {
    try {
      const { id } = req.params;
      const { text, feeling_emoji, feeling_name } = req.body;
      const userId = req.user.id;

      // Check if post exists
      const post = await Post.findById(id);
      if (!post) {
        return res.status(404).json({ 
          success: false,
          error: 'Post not found' 
        });
      }

      // Check if user owns this post
      const isOwner = await Post.isOwner(id, userId);
      if (!isOwner) {
        return res.status(403).json({ 
          success: false,
          error: 'Not authorized to update this post' 
        });
      }

      // Validate required fields
      if (!text || text.trim().length === 0) {
        return res.status(400).json({ 
          success: false,
          error: 'Post text is required' 
        });
      }

      const updatedPost = await Post.update(id, { 
        text: text.trim(), 
        feeling_emoji,
        feeling_name 
      });

      // Format with stats
      const formattedPost = await PostFormatter.formatPost(updatedPost, userId);

      res.json({
        success: true,
        message: 'Post updated successfully',
        data: formattedPost
      });
    } catch (error) {
      console.error('Update post error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to update post',
        details: error.message 
      });
    }
  },

  // Delete a post (soft delete)
  async deletePost(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // Check if post exists
      const post = await Post.findById(id);
      if (!post) {
        return res.status(404).json({ 
          success: false,
          error: 'Post not found' 
        });
      }

      // Check if user owns this post
      const isOwner = await Post.isOwner(id, userId);
      if (!isOwner) {
        return res.status(403).json({ 
          success: false,
          error: 'Not authorized to delete this post' 
        });
      }

      const deleted = await Post.softDelete(id);

      if (!deleted) {
        return res.status(500).json({ 
          success: false,
          error: 'Failed to delete post' 
        });
      }

      res.json({
        success: true,
        message: 'Post deleted successfully'
      });
    } catch (error) {
      console.error('Delete post error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Failed to delete post',
        details: error.message 
      });
    }
  }
};

module.exports = postController;