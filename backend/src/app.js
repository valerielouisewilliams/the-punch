// import required packages
const express = require('express');
const cors = require('cors');
require('dotenv').config();

// import our db connection
const { testConnection } = require('./config/database');
const authRoutes = require('./routes/auth');
const postRoutes = require('./routes/posts');

// create Express application
const app = express();

// middleware (filters that process requests)
app.use(cors()); // Allows SwiftUI app to connect
app.use(express.json()); // Allows reading JSON from requests

// test route
app.get('/health', (req, res) => {
    res.json({
        message: 'API is working! 🚀',
        timestamp: new Date().toISOString()
    });
});

// mounting routes
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);

// another test route that shows environment variables work
app.get('/info', (req, res) => {
    res.json({
        environment: process.env.NODE_ENV,
        database: process.env.DB_NAME
        // never send passwords or secrets in responses!
    });
});

// 404 handler for routes that don't exist
app.use((req, res) => {
  res.status(404).json({
    error: `Route ${req.originalUrl} not found`
  });
});

// test database connection when app starts
testConnection();

module.exports = app;