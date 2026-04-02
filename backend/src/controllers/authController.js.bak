// handles user registration and login
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const admin = require("../config/firebaseAdmin");

// POST /api/auth/session
// Verifies Firebase token and ensures there is a linked DB user.
// Returns your normal public user payload.
const session = async (req, res) => {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: "Missing token" });

    const decoded = await admin.auth().verifyIdToken(token);

    let user = await User.findByFirebaseUid(decoded.uid);
    if (!user) {
      user = await User.createFromFirebase({ firebase_uid: decoded.uid, email: decoded.email });
    }

    return res.status(200).json({
      success: true,
      data: user.getPublicProfile()
    });
  } catch (err) {
    console.error("Session error:", err);
    return res.status(401).json({ success: false, message: "Invalid token" });
  }
};

// POST /api/auth/complete-profile
// Called after Firebase account creation to set username/display_name.
const completeProfile = async (req, res) => {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: "Missing token" });

    const decoded = await admin.auth().verifyIdToken(token);

    const { username, display_name, phone_number, discoverable_by_phone } = req.body;
    if (!username) {
      return res.status(400).json({ success: false, message: "username is required" });
    }
    if (!phone_number || !String(phone_number).trim()) {
      return res.status(400).json({ success: false, message: "phone_number is required" });
    }

    if (phone_number) {
      const existingPhoneUser = await User.findByPhoneNumber(phone_number);
      if (existingPhoneUser && existingPhoneUser.firebase_uid !== decoded.uid) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone number already exists'
        });
      }
    }

    // Ensure a user row exists
    let user = await User.findByFirebaseUid(decoded.uid);
    if (!user) user = await User.createFromFirebase({ firebase_uid: decoded.uid, email: decoded.email });

    // Update profile fields
    const updated = await User.updateProfileByFirebaseUid(decoded.uid, {
      username,
      display_name: display_name || username,
      phone_number,
      discoverable_by_phone
    });

    return res.status(200).json({ success: true, data: updated.getPublicProfile() });
  } catch (err) {
    console.error("Complete profile error:", err);
    if (err?.message === 'Invalid phone number format') {
      return res.status(400).json({ success: false, message: err.message });
    }
    if (typeof err?.code === 'string' && err.code.startsWith('auth/')) {
      return res.status(401).json({ success: false, message: "Invalid token" });
    }
    return res.status(500).json({ success: false, message: "Could not complete profile" });
  }
};

// helper function to create JWT tokens
const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// register new user
const register = async (req, res) => {
  try {
    const { username, email, password, display_name, phone_number, discoverable_by_phone } = req.body;
    // Basic validation
    if (!username || !email || !password || !phone_number || !String(phone_number).trim()) {
      return res.status(400).json({
        success: false,
        message: 'Please provide username, email, password, and phone number'
      });
    }

    // check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    if (phone_number) {
        const existingPhoneUser = await User.findByPhoneNumber(phone_number);
        if (existingPhoneUser) {
          return res.status(409).json({
            success: false,
            message: 'User with this phone number already exists'
          });
        }
    }

    // create new user
    const user = await User.create({
      username,
      email,
      password,
      display_name,
      phone_number,
      discoverable_by_phone
    });

    // generate token
    const token = generateToken(user.id);

    // send response (never send password!)
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: user.getPublicProfile(),
        token: token
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    console.error('Error details:', error.message);           // ADD THIS
    console.error('Error stack:', error.stack);               // ADD THIS
    if (error?.message === 'Invalid phone number format') {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    res.status(500).json({
      success: false,
      message: 'Something went wrong during registration'
    });
  }
};

// login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // find user
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // check password
    const isPasswordCorrect = await user.checkPassword(password);
    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // generate token
    const token = generateToken(user.id);

    // send response
    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.getPublicProfile(),
        token: token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Something went wrong during login'
    });
  }
};

// get current user (from token)
const getCurrentUser = async (req, res) => {
  try {
    const user = await User.findByIdWithStats(req.user.id);

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
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve user profile'
    });
  }
};

const updateAccountInformation = async (req, res) => {
  try {
    const { phone_number } = req.body;
    const userId = req.user.id;

    if (phone_number) {
      const existingPhoneUser = await User.findByPhoneNumber(phone_number);
      if (existingPhoneUser && existingPhoneUser.id !== userId) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone number already exists'
        });
      }
    }

    const updatedUser = await User.updateAccountInformation(userId, {
      phone_number
    });

    return res.status(200).json({
      success: true,
      data: updatedUser.getPublicProfile()
    });
  } catch (error) {
    console.error('Update account information error:', error);

    if (error?.message === 'Invalid phone number format') {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Could not update account information'
    });
  }
};

module.exports = { register, login, getCurrentUser, session, completeProfile };
