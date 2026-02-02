const { pool } = require('../config/database');
const User = require('../models/User');
const Follow = require('../models/Follow');

// get user profile by username
// controllers/userController.js
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    if (isNaN(id)) {
      return res.status(400).json({ success: false, message: 'User ID must be a valid number' });
    }

    const viewerId = req.user?.id ? parseInt(req.user.id, 10) : null;

    let user;
    if (viewerId) {
      // only compute relationship if we know who the viewer is
      user = await User.findByIdWithStatsAndRelationship(parseInt(id, 10), viewerId);
    } else {
      // fallback that does NOT touch relationship logic
      user = await User.findByIdWithStats(parseInt(id, 10));
      if (user) user.is_following = false; // explicit & safe default
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.json({ success: true, data: user.getPublicProfile() });
  } catch (error) {
    console.error('Get user by ID error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Could not retrieve user' });
  }
};

const getUserByUsername = async (req, res) => {
  try {
    const { username } = req.params;
    if (!username || username.trim() === '') {
      return res.status(400).json({ success: false, message: 'Username is required' });
    }

    const base = await User.findByUsername(username.trim());
    if (!base) return res.status(404).json({ success: false, message: 'User not found' });

    const viewerId = req.user?.id ? parseInt(req.user.id, 10) : null;

    let user;
    if (viewerId) {
      user = await User.findByIdWithStatsAndRelationship(base.id, viewerId);
    } else {
      user = await User.findByIdWithStats(base.id);
      if (user) user.is_following = false;
    }

    return res.json({ success: true, data: user.getPublicProfile() });
  } catch (error) {
    console.error('Get user by username error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Could not retrieve user' });
  }
};



// get user's followers
const getFollowers = async (req, res) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'User ID must be a valid number'
      });
    }

    // Check if user exists
    const user = await User.findById(parseInt(id));
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const followers = await Follow.getFollowers(parseInt(id));

    res.json({
      success: true,
      count: followers.length,
      data: followers
    });
  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve followers'
    });
  }
};

// get users that this user is following
const getFollowing = async (req, res) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'User ID must be a valid number'
      });
    }

    // Check if user exists
    const user = await User.findById(parseInt(id));
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const following = await Follow.getFollowing(parseInt(id));

    res.json({
      success: true,
      count: following.length,
      data: following
    });
  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve following list'
    });
  }
};

const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    const { display_name, bio, avatar_url } = req.body;

    const updated = await User.updateProfile(userId, {
      display_name,
      bio,
      avatar_url
    });

    return res.json({
      success: true,
      data: updated.getPublicProfile()
    });

  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Could not update profile'
    });
  }
};

const searchUsers = async (req, res) => {
  try {
    const query = req.query.query;

    if (!query || query.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Search query is required"
      });
    }

    const searchTerm = `%${query.toLowerCase()}%`;

    const [rows] = await pool.execute(
      `
      SELECT 
        id,
        username,
        display_name,
        bio,
        avatar_url
      FROM users
      WHERE is_active = 1
        AND (
          LOWER(username) LIKE ?
          OR LOWER(display_name) LIKE ?
        )
      ORDER BY 
        CASE 
          WHEN LOWER(username) LIKE ? THEN 1
          WHEN LOWER(display_name) LIKE ? THEN 2
          ELSE 3
        END
      LIMIT 20
      `,
      [searchTerm, searchTerm, `${query.toLowerCase()}%`, `${query.toLowerCase()}%`]
    );

    return res.json({
      success: true,
      count: rows.length,
      data: rows.map(u => ({
        id: u.id,
        username: u.username,
        displayName: u.display_name,
        bio: u.bio,
        avatarUrl: u.avatar_url
      }))
    });

  } catch (error) {
    console.error("Search users error:", error);
    return res.status(500).json({
      success: false,
      message: "Could not perform search"
    });
  }
};

const updateMyAvatar = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    const { avatar_url } = req.body;
    if (!avatar_url || typeof avatar_url !== "string") {
      return res.status(400).json({ success: false, message: "avatar_url (string) is required" });
    }

    const updated = await User.updateAvatarUrl(userId, avatar_url);

    return res.json({
      success: true,
      message: "Avatar updated",
      data: updated.getPublicProfile()
    });
  } catch (e) {
    console.error("updateMyAvatar error:", e);
    return res.status(500).json({ success: false, message: "Could not update avatar" });
  }
};


module.exports = {
  getUserByUsername,
  getUserById,
  getFollowers,
  getFollowing,
  updateUserProfile,
  searchUsers,
  updateMyAvatar
};