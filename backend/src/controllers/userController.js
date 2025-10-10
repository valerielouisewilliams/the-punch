const User = require('../models/User');
const Follow = require('../models/Follow');

// get user profile by username
const getUserByUsername = async (req, res) => {
  try {
    const { username } = req.params;

    if (!username || username.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Username is required'
      });
    }

    const user = await User.findByUsername(username.trim());

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get full stats
    const userWithStats = await User.findByIdWithStats(user.id);

    res.json({
      success: true,
      data: userWithStats.getPublicProfile()
    });
  } catch (error) {
    console.error('Get user by username error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve user'
    });
  }
};

// get user profile by ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    if (isNaN(id)) {
      return res.status(400).json({
        success: false,
        message: 'User ID must be a valid number'
      });
    }

    const user = await User.findByIdWithStats(parseInt(id));

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user.getPublicProfile()
    });
  } catch (error) {
    console.error('Get user by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve user'
    });
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

module.exports = {
  getUserByUsername,
  getUserById,
  getFollowers,
  getFollowing
};