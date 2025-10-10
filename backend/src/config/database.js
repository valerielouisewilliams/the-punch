// handles connecting to MySQL database
const mysql = require('mysql2/promise');
require('dotenv').config({ path: __dirname + '/.env' });

console.log('Loaded .env values:', {
  DB_HOST: process.env.DB_HOST,
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD ? '(hidden)' : 'undefined',
  DB_NAME: process.env.DB_NAME
});


// database configuration using environment variables
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
  charset: 'utf8mb4' // For emoji support
};

// create a connection pool
const pool = mysql.createPool(dbConfig);

// test if database connection works
const initDatabase = async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
    return pool;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('Check your .env file settings!');
    process.exit(1);
  }
};

module.exports = { pool, initDatabase };