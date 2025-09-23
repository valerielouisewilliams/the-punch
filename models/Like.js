// defines how to work with posts in the database
const { pool } = require('../config/database');

// like constructor
class Like {
  constructor(likeData) {
    this.id = postData.id;
    this.user_id = postData.user_id;
    this.text = postData.text;
    this.feeling_emoji = postData.feeling_emoji; // stored as unicode symbol
    this.created_at = postData.created_at;
    this.updated_at = postData.updated_at;
    this.is_deleted = postData.is_deleted;
  }

  // create a new like
  static async create({post_id, user_id}) {
    // insert into database
    const [result] = await pool.execute(
      `INSERT INTO likes (post_id, user_id, created_at = NOW()) 
       VALUES (?, ?)`,
      [post_id, user_id]
    );
    return result.affectedRows > 0;
  }

  // delete a like 
  static async delete({post_id}) {
    // delete from database
    const [result] = await pool.execute(
      'DELETE FROM likes WHERE id = ?',
      [id]
    );
    return result.affectedRows > 0;
  }
}