const { pool } = require('../config/database');

class Punch {
  constructor(punchData) {
    this.id = punchData.id;
    this.sender_id = punchData.sender_id;
    this.receiver_id = punchData.receiver_id;
    this.created_at = punchData.created_at;

    // optional joined fields
    this.sender_username = punchData.sender_username;
    this.sender_display_name = punchData.sender_display_name;
    this.receiver_username = punchData.receiver_username;
    this.receiver_display_name = punchData.receiver_display_name;
  }

  static async create({ sender_id, receiver_id }) {
    const query = `
      INSERT INTO punches (sender_id, receiver_id)
      VALUES (?, ?)
    `;

    const [result] = await pool.execute(query, [sender_id, receiver_id]);
    return this.findById(result.insertId);
  }

  static async findById(id) {
    const query = `
      SELECT 
        p.*,
        sender.username AS sender_username,
        sender.display_name AS sender_display_name,
        receiver.username AS receiver_username,
        receiver.display_name AS receiver_display_name
      FROM punches p
      JOIN users sender ON p.sender_id = sender.id
      JOIN users receiver ON p.receiver_id = receiver.id
      WHERE p.id = ?
      LIMIT 1
    `;

    const [rows] = await pool.execute(query, [id]);
    return rows.length ? new Punch(rows[0]) : null;
  }

  static async findReceivedByUser(userId, limit = 20, offset = 0) {
    const query = `
      SELECT 
        p.*,
        sender.username AS sender_username,
        sender.display_name AS sender_display_name
      FROM punches p
      JOIN users sender ON p.sender_id = sender.id
      WHERE p.receiver_id = ?
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const [rows] = await pool.execute(query, [userId, Number(limit), Number(offset)]);
    return rows.map(row => new Punch(row));
  }

  static async findSentByUser(userId, limit = 20, offset = 0) {
    const query = `
      SELECT 
        p.*,
        receiver.username AS receiver_username,
        receiver.display_name AS receiver_display_name
      FROM punches p
      JOIN users receiver ON p.receiver_id = receiver.id
      WHERE p.sender_id = ?
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const [rows] = await pool.execute(query, [userId, Number(limit), Number(offset)]);
    return rows.map(row => new Punch(row));
  }

  static async countRecentBetweenUsers(senderId, receiverId, minutes = 10) {
    const query = `
      SELECT COUNT(*) AS count
      FROM punches
      WHERE sender_id = ?
        AND receiver_id = ?
        AND created_at >= (NOW() - INTERVAL ? MINUTE)
    `;

    const [rows] = await pool.execute(query, [senderId, receiverId, minutes]);
    return rows[0].count;
  }
}

module.exports = Punch;