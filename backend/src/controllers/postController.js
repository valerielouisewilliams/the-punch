const Post = require('../models/Post');
const Comment = require('../models/Comment');
const Like = require('../models/Like');

const postController = {
  // Create a new post
  async createPost(req, res) {
    try {
      const { text, feeling_emoji } = req.body;
      const user_id = req.user.id;

      // Validate required fields
      if (!text || text.trim().length === 0) {
        return res.status(400).json({ error: 'Post text is required' });
      }

      const post = await Post.create({ 
        user_id, 
        text: text.trim(), 
        feeling_emoji 
      });

      res.status(201).json({
        message: 'Post created successfully',
        post
      });
    } catch (error) {
      console.error('Create post error:', error);
      res.status(500).json({ 
        error: 'Failed to create post',
        details: error.message 
      });
    }
  },

  // Get a single post by ID
  async getPostById(req, res) {
    try {
      const { id } = req.params;

      const post = await Post.findById(id);

      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      // Get comments and likes for this post
      const comments = await Comment.findByPostId(id);
      const likeCount = await Like.countByPostId(id);

      res.json({
        post,
        comments,
        likes: likeCount
      });
    } catch (error) {
      console.error('Get post error:', error);
      res.status(500).json({ 
        error: 'Failed to get post',
        details: error.message 
      });
    }
  },

  // Get all posts by a specific user
  async getPostsByUser(req, res) {
    try {
      const { userId } = req.params;

      const posts = await Post.findAllByUser(userId);

      res.json({
        count: posts.length,
        posts
      });
    } catch (error) {
      console.error('Get user posts error:', error);
      res.status(500).json({ 
        error: 'Failed to get user posts',
        details: error.message 
      });
    }
  },

  // Update a post
  async updatePost(req, res) {
    try {
      const { id } = req.params;
      const { text, feeling_emoji } = req.body;
      const userId = req.user.id;

      // Check if post exists
      const post = await Post.findById(id);
      if (!post) {
        return res.status(404).json({ error: 'Post not found' });
      }

      // Check if user owns this post
      const isOwner = await Post.isOwner(id, userId);
      if (!isOwner) {
        return res.status(403).json({ error: 'Not authorized to update this post' });
      }

      // Validate required fields
      if (!text || text.trim().length === 0) {
        return res.status(400).json({ error: 'Post text is required' });
      }

      const updatedPost = await Post.update(id, { 
        text: text.trim(), 
        feeling_emoji 
      });

      res.json({
        message: 'Post updated successfully',
        post: updatedPost
      });
    } catch (error) {
      console.error('Update post error:', error);
      res.status(500).json({ 
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
        return res.status(404).json({ error: 'Post not found' });
      }

      // Check if user owns this post
      const isOwner = await Post.isOwner(id, userId);
      if (!isOwner) {
        return res.status(403).json({ error: 'Not authorized to delete this post' });
      }

      const deleted = await Post.softDelete(id);

      if (!deleted) {
        return res.status(500).json({ error: 'Failed to delete post' });
      }

      res.json({
        message: 'Post deleted successfully'
      });
    } catch (error) {
      console.error('Delete post error:', error);
      res.status(500).json({ 
        error: 'Failed to delete post',
        details: error.message 
      });
    }
  },

  // retrieving all posts (with pagination support)
  async getAllPosts(req, res) {
    try {
      const { pool } = require('../config/database'); 
      let { limit = 50, offset = 0 } = req.query;

      limit = Number.isFinite(Number(limit)) && Number(limit) > 0 ? Number(limit) : 50;
      offset = Number.isFinite(Number(offset)) && Number(offset) >= 0 ? Number(offset) : 0;

      const [rows] = await pool.query(
        'SELECT * FROM posts WHERE is_deleted = 0 ORDER BY created_at DESC LIMIT ? OFFSET ?',
        [parseInt(limit), parseInt(offset)]
      );

      const posts = rows.map(row => new Post(row));

      res.json({
        success: true,
        data: posts,
        count: posts.length
      });
    } catch (error) {
      console.error('Get posts error:', error);
      res.status(500).json({
        success: false,
        message: 'Could not retrieve posts'
      });
    }
  },

  // get posts made by a specific user
  async getPostsByUserId(req, res) {
    try {
      const { user_id } = req.params;

      if (isNaN(user_id)) {
        return res.status(400).json({
          success: false,
          message: 'User ID must be a valid number'
        });
      }

      const posts = await Post.findAllByUser(parseInt(user_id));

      res.json({
        success: true,
        data: posts,
        count: posts.length
      });

    } catch (error) {
      console.error('Get user posts error:', error);
      res.status(500).json({
        success: false,
        message: 'Could not retrieve user posts'
      });
    }
  }
};

module.exports = postController;