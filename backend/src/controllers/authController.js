const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');

// helper function to create JWT tokens (for old system)
const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// OLD REGISTRATION (JWT-based) - Keep for backwards compatibility
const register = async (req, res) => {
  // LOG EVERYTHING
  console.log('\n========================================');
  console.log('📥 REGISTRATION REQUEST RECEIVED');
  console.log('========================================');
  console.log('Request body:', JSON.stringify(req.body, null, 2));
  console.log('Fields:');
  console.log('  email:', req.body.email);
  console.log('  username:', req.body.username);
  console.log('  firebaseUid:', req.body.firebaseUid);
  console.log('  password:', req.body.password);
  console.log('========================================\n');
  
  try {
    // CHECK IF THIS IS A FIREBASE REQUEST
    if (req.body.firebaseUid) {
      console.log('🔥 Firebase registration detected - redirecting...');
      return registerFirebase(req, res);
    }
    
    // OLD JWT REGISTRATION
    console.log('🔑 JWT registration - checking for password...');
    const { username, email, password, display_name } = req.body;
    
    if (!username || !email || !password) {
      console.log('❌ Missing username/email/password for JWT registration');
      return res.status(400).json({
        success: false,
        message: 'Please provide username, email and password'
      });
    }

    // ... rest of your JWT registration code
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    const user = await User.create({
      username,
      email,
      password,
      display_name
    });

    const token = generateToken(user.id);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: user.getPublicProfile(),
        token: token
      }
    });

  } catch (error) {
    console.error('❌ Registration error:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Something went wrong during registration'
    });
  }
};

// NEW FIREBASE REGISTRATION
const registerFirebase = async (req, res) => {
  const { pool } = require('../config/database');
  
  try {
    const { email, username, firebaseUid } = req.body;
    
    console.log('📝 Firebase registration details:');
    console.log('   Email:', email);
    console.log('   Username:', username);
    console.log('   Firebase UID:', firebaseUid);

    if (!email || !username || !firebaseUid) {
      console.log('❌ Missing required Firebase fields');
      return res.status(400).json({ 
        success: false, 
        error: 'Email, username, and firebaseUid are required' 
      });
    }

    // Check if user exists
    console.log('🔍 Checking for existing user...');
    const [existing] = await pool.execute(
      'SELECT id FROM users WHERE email = ? OR firebase_uid = ?',
      [email, firebaseUid]
    );

    if (existing.length > 0) {
      console.log('❌ User already exists:', existing[0]);
      return res.status(400).json({ 
        success: false, 
        error: 'User already exists' 
      });
    }

    // Create user
    console.log('💾 Creating user in database...');
    const [result] = await pool.execute(
      `INSERT INTO users (email, username, firebase_uid, display_name, bio, created_at) 
       VALUES (?, ?, ?, ?, '', NOW())`,
      [email, username, firebaseUid, username]
    );

    console.log('✅ User inserted with ID:', result.insertId);

    // Fetch created user
    const [newUser] = await pool.execute(
      'SELECT id, email, username, display_name, bio, created_at FROM users WHERE id = ?',
      [result.insertId]
    );

    console.log('✅ User created successfully:', newUser[0]);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: newUser[0]
    });

  } catch (error) {
    console.error('❌ Firebase registration error:', error);
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed: ' + error.message 
    });
  }
};

// login user (JWT-based - not needed for Firebase)
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

// get current user (works with BOTH JWT and Firebase tokens)
const getCurrentUser = async (req, res) => {
  try {
    console.log('👤 getCurrentUser called');
    console.log('   req.user:', req.user);
    
    // req.user is set by middleware (either JWT or Firebase)
    if (!req.user || !req.user.id) {
      console.log('❌ No user in request');
      return res.status(401).json({
        success: false,
        error: 'Unauthorized'
      });
    }

    // For Firebase auth, we need to query directly since we're not using the User model
    const [rows] = await pool.execute(
      `SELECT 
        id, 
        email, 
        username, 
        display_name,
        bio, 
        avatar_url,
        created_at,
        (SELECT COUNT(*) FROM follows WHERE follower_id = users.id) as following_count,
        (SELECT COUNT(*) FROM follows WHERE following_id = users.id) as follower_count
      FROM users 
      WHERE id = ?`,
      [req.user.id]
    );

    if (rows.length === 0) {
      console.log('❌ User not found in database');
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('✅ User profile fetched:', rows[0].username);

    res.json({
      success: true,
      data: rows[0]
    });

  } catch (error) {
    console.error('❌ Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Could not retrieve user profile'
    });
  }
};

module.exports = { register, registerFirebase, login, getCurrentUser };