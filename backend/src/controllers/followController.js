const Follow = require('../models/Follow');

const followController = {
  // POST /api/follows/user/:userId
  async followUser(req, res) {
    try {
      const targetParam = req.params.userId;
      const followerId = req.user?.id;

      if (!followerId) {
        return res.status(401).json({ error: 'Follower ID is missing - authentication issue' });
      }
      if (!targetParam) {
        return res.status(400).json({ error: 'Target userId parameter is required' });
      }

      const followingId = Number.parseInt(targetParam, 10);
      const followerIdNum = Number.parseInt(followerId, 10);

      if (Number.isNaN(followingId) || Number.isNaN(followerIdNum)) {
        return res.status(400).json({ error: 'Invalid user IDs' });
      }
      if (followerIdNum === followingId) {
        return res.status(400).json({ error: 'Cannot follow yourself' });
      }

      await Follow.create(followerIdNum, followingId);

      return res.status(201).json({
        success: true,
        message: 'Followed successfully'
      });

    } catch (error) {
      if (error.message === 'Already following this user' || error.message === 'Cannot follow yourself') {
        return res.status(400).json({ error: error.message });
      }
      console.error('Follow user error:', error);
      return res.status(500).json({
        error: 'Failed to follow user',
        details: error.message
      });
    }
  },

  // DELETE /api/follows/user/:userId
  async unfollowUser(req, res) {
    try {
      const targetParam = req.params.userId;
      const followerId = req.user?.id;

      if (!followerId) {
        return res.status(401).json({ error: 'Follower ID is missing - authentication issue' });
      }
      if (!targetParam) {
        return res.status(400).json({ error: 'Target userId parameter is required' });
      }

      const followingId = Number.parseInt(targetParam, 10);
      const followerIdNum = Number.parseInt(followerId, 10);

      if (Number.isNaN(followingId) || Number.isNaN(followerIdNum)) {
        return res.status(400).json({ error: 'Invalid user IDs' });
      }

      await Follow.delete(followerIdNum, followingId);

      return res.json({
        success: true,
        message: 'Unfollowed successfully'
      });

    } catch (error) {
      console.error('Unfollow user error:', error);
      return res.status(500).json({
        error: 'Failed to unfollow user',
        details: error.message
      });
    }
  },

  // GET /api/follows/user/:userId/check
  async checkIfFollowing(req, res) {
    try {
      const targetParam = req.params.userId;
      const followerId = req.user?.id;

      if (!followerId) {
        return res.status(401).json({ error: 'Follower ID is missing - authentication issue' });
      }
      if (!targetParam) {
        return res.status(400).json({ error: 'Target userId parameter is required' });
      }

      const followingId = Number.parseInt(targetParam, 10);
      const followerIdNum = Number.parseInt(followerId, 10);

      if (Number.isNaN(followingId) || Number.isNaN(followerIdNum)) {
        return res.status(400).json({ error: 'Invalid user IDs' });
      }

      const isFollowing = await Follow.isFollowing(followerIdNum, followingId);

      return res.json({ following: isFollowing });

    } catch (error) {
      console.error('Check follow error:', error);
      return res.status(500).json({
        error: 'Failed to check follow status',
        details: error.message
      });
    }
  },

  // GET followers
  async getFollowers(req, res) {
    try {
      const { userId } = req.params;
      const userIdNum = parseInt(userId, 10);

      if (isNaN(userIdNum)) {
        return res.status(400).json({ error: `Invalid user ID: ${userId}` });
      }

      const followers = await Follow.getFollowers(userIdNum);

      return res.json({
        userId: userIdNum,
        count: followers.length,
        followers: followers.map(u => ({
          id: u.id,
          username: u.username,
          displayName: u.display_name,
          bio: u.bio,
          followedAt: u.followed_at,
          avatarUrl: u.avatar_url
        }))
      });

    } catch (error) {
      console.error('Get followers error:', error);
      return res.status(500).json({
        error: 'Failed to fetch followers',
        details: error.message
      });
    }
  },

  // GET following
  async getFollowing(req, res) {
    try {
      const { userId } = req.params;
      const userIdNum = parseInt(userId, 10);

      if (isNaN(userIdNum)) {
        return res.status(400).json({ error: `Invalid user ID: ${userId}` });
      }

      const following = await Follow.getFollowing(userIdNum);

      return res.json({
        userId: userIdNum,
        count: following.length,
        following: following.map(u => ({
          id: u.id,
          username: u.username,
          displayName: u.display_name,
          bio: u.bio,
          followedAt: u.followed_at,
          avatarUrl: u.avatar_url
        }))
      });

    } catch (error) {
      console.error('Get following error:', error);
      return res.status(500).json({
        error: 'Failed to fetch following list',
        details: error.message
      });
    }
  }
};

module.exports = followController;
