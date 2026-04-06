// handles connecting to MySQL database
const mysql = require('mysql2/promise');
require('dotenv').config({ path: __dirname + '/.env' });

// create a connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  charset: 'utf8mb4',
  ssl: {
    rejectUnauthorized: false  // Aiven fix
  }
});


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
