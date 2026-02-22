const { pool } = require('../config/database');

class Notification {
  constructor(row) {
    Object.assign(this, row);
  }

  static _toInt(value, fallback) {
    const n = Number(value);
    return Number.isFinite(n) ? n : fallback;
  }

  static async findById(id) {
    const [rows] = await pool.query(
      `SELECT * FROM notifications WHERE id = ? LIMIT 1`,
      [this._toInt(id, 0)]
    );
    return rows.length ? new Notification(rows[0]) : null;
  }

  static async create({
    recipient_user_id,
    actor_user_id = null,
    type,
    entity_type = null,
    entity_id = null,
    message = null
  }) {
    const [result] = await pool.query(
      `
      INSERT INTO notifications
        (recipient_user_id, actor_user_id, type, entity_type, entity_id, message)
      VALUES (?, ?, ?, ?, ?, ?)
      `,
      [
        this._toInt(recipient_user_id, 0),
        actor_user_id === null ? null : this._toInt(actor_user_id, null),
        type,
        entity_type,
        entity_id === null ? null : this._toInt(entity_id, null),
        message
      ]
    );

    return this.findById(result.insertId);
  }

  /**
   * List inbox for a user.
   * @param {number} recipient_user_id
   * @param {{ limit?: number|string, offset?: number|string, unreadOnly?: boolean, includeDeleted?: boolean }} opts
   */
  static async listForUser(
    recipient_user_id,
    { limit = 50, offset = 0, unreadOnly = false, includeDeleted = false } = {}
  ) {
    const lim = Math.min(Math.max(this._toInt(limit, 50), 1), 200);
    const off = Math.max(this._toInt(offset, 0), 0);

    const where = [];
    const params = [];

    where.push('recipient_user_id = ?');
    params.push(this._toInt(recipient_user_id, 0));

    if (!includeDeleted) {
      where.push('is_deleted = 0');
    }

    if (unreadOnly) {
      where.push('read_at IS NULL');
    }

    const sql = `
      SELECT *
      FROM notifications
      WHERE ${where.join(' AND ')}
      ORDER BY id DESC
      LIMIT ? OFFSET ?
    `;

    params.push(lim, off);

    const [rows] = await pool.query(sql, params);
    return rows.map((r) => new Notification(r));
  }

  static async markRead(id, recipient_user_id) {
    const [result] = await pool.query(
      `
      UPDATE notifications
      SET read_at = COALESCE(read_at, CURRENT_TIMESTAMP)
      WHERE id = ?
        AND recipient_user_id = ?
        AND is_deleted = 0
      `,
      [this._toInt(id, 0), this._toInt(recipient_user_id, 0)]
    );
    return result.affectedRows > 0;
  }

  static async markAllRead(recipient_user_id) {
    const [result] = await pool.query(
      `
      UPDATE notifications
      SET read_at = CURRENT_TIMESTAMP
      WHERE recipient_user_id = ?
        AND is_deleted = 0
        AND read_at IS NULL
      `,
      [this._toInt(recipient_user_id, 0)]
    );
    return result.affectedRows; // count updated
  }

  static async softDelete(id, recipient_user_id) {
    const [result] = await pool.query(
      `
      UPDATE notifications
      SET is_deleted = 1
      WHERE id = ?
        AND recipient_user_id = ?
      `,
      [this._toInt(id, 0), this._toInt(recipient_user_id, 0)]
    );
    return result.affectedRows > 0;
  }
}

module.exports = Notification;