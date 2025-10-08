// defines how to work with users in the database
const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  constructor(userData) {
    this.id = userData.id;
    this.username = userData.username;
    this.email = userData.email;
    this.password_hash = userData.password_hash;
    this.display_name = userData.display_name;
    this.bio = userData.bio;
    this.created_at = userData.created_at;
  }

  // create a new user
  static async create({ username, email, password, display_name }) {
    // hash the password for security
    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS);
    const password_hash = await bcrypt.hash(password, saltRounds);

    // set up query
    query = `INSERT INTO users (username, email, password_hash, display_name) 
       VALUES (?, ?, ?, ?)`;
    
    // insert into database
    const [result] = await pool.execute(
      query,
      [username, email, password_hash, display_name || username]
    );
    
    // Return the new user (without password)
    return this.findById(result.insertId);
  }

  // find user by ID
  static async findById(id) {
    // set up query
    query = 'SELECT * FROM users WHERE id = ? AND is_active = true';

    // execute the query
    const [rows] = await pool.execute(
      query,
      [id]
    );
    
    // return the data
    return rows.length > 0 ? new User(rows[0]) : null;
  }

  // find user by email (for autb)
  static async findByEmail(email) {
    query = 'SELECT * FROM users WHERE email = ? AND is_active = true';

    const [rows] = await pool.execute(
      query,
      [email]
    );
    
    return rows.length > 0 ? new User(rows[0]) : null;
  }

  // check if password is correct
  async checkPassword(password) {
    return bcrypt.compare(password, this.password_hash);
  }

  // get followers/following stats for the profile by userId
  static async findByIdWithStats(userId) {
    const query = `
      SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id - u.id) as following_count
      FROM users u
      WHERE u.id = ? and u.is_active = true
    `;

    const[rows] = await pool.execute(query, [userId]);

    if (rows.length == 0) return null;

    const user = new User(rows[0]);
    user.follower_count = parseInt(rows[0].follower_count);
    user.following_count = parseInt(rows[0].following_count);
      
    return user;
  }

  static async findByUsername(username) {
    // create the query as a string
    const query = ' SELECT id, username, display_name, bio, created_at FROM users WHERE username = ?';

    // run it against the db
    const[rows] = await pool.execute(query, [username]);

    // no user found by this name
    if (rows.length == 0) return null; 

    // return the found user
    return new User(rows[0]);

  }

  // get safe user data (no password)
  getPublicProfile() {
    return {
      id: this.id,
      username: this.username,
      display_name: this.display_name,
      bio: this.bio,
      created_at: this.created_at,
      follower_count: this.follower_count,
      following_count: this.following_count
    };
  }
}

module.exports = User;