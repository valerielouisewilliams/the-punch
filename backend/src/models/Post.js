// defines how to work with posts in the database
const { pool } = require('../config/database');

// post constructor
class Post {
  constructor(postData) {
    this.id = postData.id;
    this.user_id = postData.user_id;
    this.text = postData.text;
    this.feeling_emoji = postData.feeling_emoji; // stored as unicode symbol
    this.created_at = postData.created_at;
    this.updated_at = postData.updated_at;
    this.is_deleted = postData.is_deleted;
  }

  // create a new post
  static async create({ user_id, text, feeling_emoji }) {
    // Insert into database
    const [result] = await pool.execute(
      `INSERT INTO posts (user_id, text, feeling_emoji) 
       VALUES (?, ?, ?)`,
      [user_id, text, feeling_emoji]
    );

    // return the new post
    return this.findById(result.insertId);
  }

  // find post by ID
  static async findById(id) {
    const [rows] = await pool.execute(
      'SELECT * FROM posts WHERE id = ?',
      [id]
    );

    return rows.length > 0 ? new Post(rows[0]) : null;
  }

  // fetches all posts for a user
  static async findAllByUser(userId) {
    const [rows] = await pool.execute(
        'SELECT * FROM posts WHERE user_id = ? and is_deleted = 0',
        [userId]
    );

    return rows.map(row => new Post(row));
  }

  // update a post
  static async update(id, { text, feeling_emoji}) {
    const [result] = await pool.execute(
        'UPDATE posts SET text = ?, feeling_emoji = ?, updated_at = NOW() WHERE id = ?',
        [text, feeling_emoji, id]
    );
    return this.findById(id);
  }

  // delete a post by ID
  static async softDelete(id) {
    const [result] = await pool.execute(
        'UPDATE posts SET is_deleted = 1, updated_at = NOW() where id = ?',
        [id]
    );
    // return true if a row was updated, false otherwise
    return result.affectedRows > 0;
  }
}

module.exports = Post;
