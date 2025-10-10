const Follow = require('../models/Follow');
const User = require('../models/User');

const followController = {
  // Follow a user
  async followUser(req, res) {
    try {
      const { userId } = req.params;
      const followerId = req.user.userId;

      // Check if trying to follow yourself
      if (followerId === parseInt(userId)) {
        return res.status(400).json({ error: 'Cannot follow yourself' });
      }

      // Check if user to follow exists
      const userToFollow = await User.findById(userId);
      if (!userToFollow) {
        return res.status(404).json({ error: 'User not found' });
      }

      // Check if already following
      const alreadyFollowing = await Follow.exists(followerId, userId);
      if (alreadyFollowing) {
        return res.status(400).json({ error: 'Already following this user' });
      }

      const follow = await Follow.create(followerId, userId);

      res.status(201).json({
        message: 'User followed successfully',
        follow
      });
    } catch (error) {
      console.error('Follow user error:', error);

      if (error.message === 'Cannot follow yourself' || 
          error.message === 'Already following this user') {
        return res.status(400).json({ error: error.message });
      }

      res.status(500).json({ 
        error: 'Failed to follow user',
        details: error.message 
      });
    }
  },

  // Unfollow a user
  async unfollowUser(req, res) {
    try {
      const { userId } = req.params;
      const followerId = req.user.userId;

      // Check if user exists
      const userToUnfollow = await User.findById(userId);
      if (!userToUnfollow) {
        return res.status(404).json({ error: 'User not found' });
      }

      // Check if actually following
      const isFollowing = await Follow.exists(followerId, userId);
      if (!isFollowing) {
        return res.status(400).json({ error: 'Not following this user' });
      }

      const deleted = await Follow.deleteByUsers(followerId, userId);

      if (!deleted) {
        return res.status(500).json({ error: 'Failed to unfollow user' });
      }

      res.json({
        message: 'User unfollowed successfully'
      });
    } catch (error) {
      console.error('Unfollow user error:', error);
      res.status(500).json({ 
        error: 'Failed to unfollow user',
        details: error.message 
      });
    }
  },

  // Check if current user is following another user
  async checkIfFollowing(req, res) {
    try {
      const { userId } = req.params;
      const followerId = req.user.userId;

      const isFollowing = await Follow.exists(followerId, userId);

      res.json({
        following: isFollowing
      });
    } catch (error) {
      console.error('Check follow error:', error);
      res.status(500).json({ 
        error: 'Failed to check follow status',
        details: error.message 
      });
    }
  }
};

module.exports = followController;