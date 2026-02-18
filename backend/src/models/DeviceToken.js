const { pool } = require('../config/database');

class DeviceToken {
  static async upsert({ userId, token, platform = "ios" }) {
    const sql = `
      INSERT INTO device_tokens (user_id, token, platform, is_active, last_seen_at)
      VALUES (?, ?, ?, TRUE, NOW())
      ON DUPLICATE KEY UPDATE
        user_id = VALUES(user_id),
        platform = VALUES(platform),
        is_active = TRUE,
        last_seen_at = NOW()
    `;
    await pool.execute(sql, [userId, token, platform]);
  }

  static async getActiveTokensByUserId(userId) {
    const sql = `
      SELECT token
      FROM device_tokens
      WHERE user_id = ? AND is_active = TRUE
    `;
    const [rows] = await pool.execute(sql, [userId]);
    return rows.map(r => r.token);
  }

  static async deactivate(token) {
    const sql = `UPDATE device_tokens SET is_active = FALSE WHERE token = ?`;
    await pool.execute(sql, [token]);
  }
}

module.exports = DeviceToken;
