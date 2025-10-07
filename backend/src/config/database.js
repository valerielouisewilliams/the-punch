// handles connecting to MySQL database
const mysql = require('mysql2/promise');
require('dotenv').config();

// database configuration using environment variables
const dbConfig = {
    host: process.env.DB_HOST, // localhost
    user: process.env.DB_USER, // root
    password: process.env.DB_PASSWORD, // MySQL password
    database: process.env.DB_NAME, // social_media_db
    port: process.env.DB_PORT, // 3306
    charset: 'utf8mb4' // For emoji support
};

// create a connection pool (handle multiple requests)
const pool = mysql.createPool(dbConfig);

// test if database connection works
const testConnection = async () => {
    try {
        const connection = await pool.getConnection();
        console.log('✅ Database connected successfully');
        connection.release(); // release connections back to the pool
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        console.error('Check your .env file settings!');
        process.exit(1); // stop the app if db doesn't work
    }
};

// export so other files can use
module.exports = { pool, testConnection };