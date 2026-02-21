const { pool } = require("../config/database");

class NotificationInbox {
  static async create({
    recipientUserId,
    actorUserId = null,
    type,
    entityType = null,
    entityId = null,
    message = null
  }) {

    console.log("[notif] about to insert", {
      recipientUserId,
      actorUserId,
      type,
      entityType,
      entityId
    });

    const query = `
      INSERT INTO notifications
        (recipient_user_id, actor_user_id, type, entity_type, entity_id, message)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    // ⏱ start a timer
    const timer = setTimeout(() => {
      console.error("[notif] STILL waiting on DB after 8 seconds");
    }, 8000);

    try {
      const [result] = await pool.execute(query, [
        recipientUserId,
        actorUserId,
        type,
        entityType,
        entityId,
        message
      ]);

      clearTimeout(timer); // stop timer if query finishes

      console.log("[notif] insert finished", {
        insertId: result.insertId
      });

      return result.insertId;

    } catch (err) {
      clearTimeout(timer);

      console.error("[notif] insert error:", err);

      throw err; // re-throw so your controller can handle it
    }
  }

  static async listForUser({ userId, limit = 30 }) {
    const query = `
      SELECT *
      FROM notifications
      WHERE recipient_user_id = ?
        AND is_deleted = 0
      ORDER BY id DESC
      LIMIT ?
    `;

    const [rows] = await pool.execute(query, [userId, limit]);
    return rows;
  }

  static async unreadCount(userId) {
    const [rows] = await pool.execute(
      `SELECT COUNT(*) AS count
       FROM notifications
       WHERE recipient_user_id = ?
         AND read_at IS NULL
         AND is_deleted = 0`,
      [userId]
    );
    return rows[0].count;
  }

  static async markRead({ userId, notificationId }) {
    const [result] = await pool.execute(
      `UPDATE notifications
       SET read_at = NOW()
       WHERE id = ?
         AND recipient_user_id = ?
         AND read_at IS NULL`,
      [notificationId, userId]
    );

    return result.affectedRows > 0;
  }

  static async markAllRead(userId) {
    const [result] = await pool.execute(
      `UPDATE notifications
       SET read_at = NOW()
       WHERE recipient_user_id = ?
         AND read_at IS NULL`,
      [userId]
    );

    return result.affectedRows;
  }
}

module.exports = NotificationInbox;