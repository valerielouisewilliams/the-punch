const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { pool } = require('./config/database');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test for deployment
app.get("/test-db", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT 1");
    res.json({ success: true, rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: err.message });
  }
});


// Request logging middleware (optional)
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Import routes
const routes = require('./routes');

// Mount all routes under /api
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to the Social Media API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      users: '/api/users',
      posts: '/api/posts',
      comments: '/api/comments',
      likes: '/api/likes',
      follows: '/api/follows'
    }
  });
});

app.get('/api/test-db', async (req, res) => {
  console.log('DB_USER:', process.env.DB_USER)

  try {
    const { pool } = require('../config/database');
    
    // Try a simple query
    const [rows] = await pool.execute('SELECT 1 + 1 AS result');
    
    res.json({
      success: true,
      message: '✅ Database connection working!',
      test_query_result: rows[0].result,
      database_type: 'MySQL'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: '❌ Database connection failed',
      error: error.message
    });
  }
});

// 404 handler - THIS MUST BE AFTER ALL OTHER ROUTES
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handling middleware - THIS MUST BE LAST
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

// Start server with database initialization
const { initDatabase } = require('./config/database');
const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await initDatabase();
    
    app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server is running on http://0.0.0.0:${PORT}`);
    console.log(`API available at http://0.0.0.0:${PORT}/api`);
  });

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = app;