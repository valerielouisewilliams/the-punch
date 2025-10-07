// handles user registration and login
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// helper function to create JWT tokens
const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },                    // data to store in token
    process.env.JWT_SECRET,            // secret key from .env
    { expiresIn: process.env.JWT_EXPIRE } // token expires in 7 days
  );
};

// register new user
const register = async (req, res) => {
  try {
    const { username, email, password, display_name } = req.body;
    
    // Basic validation
    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide username, email and password'
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

    // create new user
    const user = await User.create({
      username,
      email,
      password,
      display_name
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

module.exports = { register, login };