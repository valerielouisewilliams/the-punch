// defines how to work with likes in the database
const { pool } = require('../config/database');

// like constructor
class Like {
  constructor(likeData) {
    this.id = likeData.id;
    this.post_id = likeData.post_id;
    this.user_id = likeData.user_id;
    this.created_at = likeData.created_at;
  }

  // create a new like
  static async create({ post_id, user_id }) {
    try {
      const query = `INSERT INTO likes (post_id, user_id) VALUES (?, ?)`;

      const [result] = await pool.execute(query, [post_id, user_id]);

      return this.findById(result.insertId);
    } catch (error) {
      // Handle duplicate likes (if unique constraint exists)
      if (error.code === 'ER_DUP_ENTRY' || error.code === 'SQLITE_CONSTRAINT') {
        throw new Error('Already liked this post');
      }
      throw error;
    }
  }

  // find a like by ID
  static async findById(id) {
    const query = 'SELECT * FROM likes WHERE id = ?';

    const [rows] = await pool.execute(query, [id]);

    return rows.length > 0 ? new Like(rows[0]) : null;
  }

  // check if a user has liked a post
  static async exists(post_id, user_id) {
    const query = 'SELECT id FROM likes WHERE post_id = ? AND user_id = ?';

    const [rows] = await pool.execute(query, [post_id, user_id]);

    return rows.length > 0;
  }

  // get all likes for a post
  static async findByPostId(post_id) {
    const query = `
      SELECT l.*, u.username, u.display_name
      FROM likes l
      JOIN users u ON l.user_id = u.id
      WHERE l.post_id = ?
      ORDER BY l.created_at DESC
    `;

    const [rows] = await pool.execute(query, [post_id]);

    return rows.map(row => new Like(row));
  }

  // get like count for a post
  static async countByPostId(post_id) {
    const query = 'SELECT COUNT(*) as count FROM likes WHERE post_id = ?';

    const [rows] = await pool.execute(query, [post_id]);

    return rows[0].count;
  }

  // delete a like (unlike)
  static async delete(post_id, user_id) {
    const query = 'DELETE FROM likes WHERE post_id = ? AND user_id = ?';

    const [result] = await pool.execute(query, [post_id, user_id]);

    return result.affectedRows > 0;
  }
}

module.exports = Like;