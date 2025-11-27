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

  static async getFeedForUser(currentUserId, { limit = 50, offset = 0 } = {}) {
  // Include followed users + self
    const query = `
      SELECT 
        p.*,
        u.username AS author_username,
        u.display_name AS author_display_name,
        u.avatar_url AS author_avatar_url
      FROM posts p
      INNER JOIN users u ON u.id = p.user_id
      WHERE 
        p.is_deleted = 0
        AND p.user_id IN (
          SELECT following_id FROM follows WHERE follower_id = ?
          UNION SELECT ? -- include own posts
        )
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?;
    `;

    const [rows] = await pool.execute(query, [currentUserId, currentUserId, Number(limit), Number(offset)]);
    return rows.map(r => new Post(r));
  }


  // create a new post
  static async create({ user_id, text, feeling_emoji, feeling_name }) {
    // set up query
    const query = `INSERT INTO posts (user_id, text, feeling_emoji, feeling_name) 
       VALUES (?, ?, ?, ?)`;

    // insert into database
    const [result] = await pool.execute(
      query,
      [user_id, text, feeling_emoji, feeling_name]
    );

    // return the new post
    return this.findById(result.insertId);
  }

  // find post by ID
  static async findById(id) {
    // set up query
    const query = 'SELECT * FROM posts WHERE id = ? AND is_deleted = 0';

    // execute the query
    const [rows] = await pool.execute(query, [id]);

    // return the data
    return rows.length > 0 ? new Post(rows[0]) : null;
  }

  // fetches all posts for a user
  static async findAllByUser(userId) {
    // set up the query
    const query = 'SELECT * FROM posts WHERE user_id = ? AND is_deleted = 0 ORDER BY created_at DESC';

    // execute the query
    const [rows] = await pool.execute(query, [userId]);

    // return the data
    return rows.map(row => new Post(row));
  }

  // update a post
  static async update(id, { text, feeling_emoji }) {
    // set up the query
    const query = 'UPDATE posts SET text = ?, feeling_emoji = ?, updated_at = NOW() WHERE id = ?';

    // execute the query
    const [result] = await pool.execute(query, [text, feeling_emoji, id]);

    // return the data
    return this.findById(id);
  }

  // delete a post by ID
  static async softDelete(id) {
    // set up the query
    const query = 'UPDATE posts SET is_deleted = 1, updated_at = NOW() WHERE id = ?';

    // execute the query
    const [result] = await pool.execute(query, [id]);

    // return true if a row was updated, false otherwise
    return result.affectedRows > 0;
  }

  // check if user owns this post
  static async isOwner(postId, userId) {
    const query = 'SELECT user_id FROM posts WHERE id = ?';
    const [rows] = await pool.execute(query, [postId]);
    
    return rows.length > 0 && rows[0].user_id === userId;
  }
}

module.exports = Post;