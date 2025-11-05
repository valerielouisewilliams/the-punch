// src/models/Feed.js
const { pool } = require('../config/database');

class Feed {
  static async getUserFeed(userId, limit, offset, includeOwn = false) {
    const uid = Number(userId);
    if (!Number.isFinite(uid)) throw new Error(`currentUserId must be a number (got: ${userId})`);

    const pageLimit  = Number.isFinite(Number(limit))  ? Number(limit)  : 20;
    const pageOffset = Number.isFinite(Number(offset)) ? Number(offset) : 0;
    const includeOwnBool =
      includeOwn === true || includeOwn === 'true' || includeOwn === 1 || includeOwn === '1';

    // last 24h
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const sql = `
      SELECT
        p.id,
        p.user_id,
        p.text,
        p.feeling_emoji,
        p.created_at,
        p.updated_at,
        u.username,
        u.display_name,
        u.avatar_url,
        (SELECT COUNT(*) FROM likes    WHERE post_id = p.id)                      AS like_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0)   AS comment_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?)          AS user_has_liked
      FROM posts p
      INNER JOIN users   u ON p.user_id = u.id
      INNER JOIN follows f ON p.user_id = f.following_id
      WHERE
        (f.follower_id = ? ${includeOwnBool ? 'OR p.user_id = ?' : ''})
        AND p.is_deleted = 0
        AND u.is_active = 1
        AND p.created_at >= ?
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const params = [uid, uid];
    if (includeOwnBool) params.push(uid);
    params.push(cutoff, pageLimit, pageOffset);

    const [rows] = await pool.query(sql, params);
    return rows.map(r => ({
      id: r.id,
      text: r.text,
      feelingEmoji: r.feeling_emoji,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
      user: {
        id: r.user_id,
        username: r.username,
        displayName: r.display_name,
        avatarUrl: r.avatar_url
      },
      engagement: {
        likeCount: r.like_count,
        commentCount: r.comment_count,
        userHasLiked: Boolean(r.user_has_liked)
      }
    }));
  }
}

module.exports = Feed;