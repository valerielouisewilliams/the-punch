// // models/Follow.js
// const { pool } = require('../config/database');

// class Follow {
//   static async create(followerId, followingId) {
//     if (followerId == null || followingId == null) {
//       throw new Error('Follower or following ID missing');
//     }
//     if (Number.isNaN(+followerId) || Number.isNaN(+followingId)) {
//       throw new Error('Invalid user IDs');
//     }
//     if (+followerId === +followingId) {
//       throw new Error('Cannot follow yourself');
//     }

//     // Check for existing relation
//     const [exists] = await pool.execute(
//       'SELECT id FROM follows WHERE follower_id = ? AND following_id = ? LIMIT 1',
//       [followerId, followingId]
//     );
//     if (exists.length) {
//       throw new Error('Already following this user');
//     }

//     await pool.execute(
//       'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)',
//       [followerId, followingId]
//     );
//   }

//     static async isFollowing(followerId, followingId) {
//     const [[row]] = await pool.query(
//       `SELECT EXISTS(
//          SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ?
//        ) AS ok`,
//       [followerId, followingId]
//     );
//     return !!row.ok;
//   }

//   static async delete(followerId, followingId) {
//     if (followerId == null || followingId == null) {
//       throw new Error('Follower or following ID missing');
//     }
//     await pool.execute(
//       'DELETE FROM follows WHERE follower_id = ? AND following_id = ?',
//       [followerId, followingId]
//     );
//   }

//   static async isFollowing(followerId, followingId) {
//     const [rows] = await pool.execute(
//       'SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ? LIMIT 1',
//       [followerId, followingId]
//     );
//     return rows.length > 0;
//   }

//   static async getFollowers(userId) {
//     const [rows] = await pool.execute(
//       `SELECT u.id, u.username, u.display_name, u.bio, f.created_at AS followed_at
//        FROM follows f
//        JOIN users u ON f.follower_id = u.id
//        WHERE f.following_id = ? AND u.is_active = true
//        ORDER BY f.created_at DESC`,
//       [userId]
//     );
//     return rows;
//   }

//   static async getFollowing(userId) {
//     const [rows] = await pool.execute(
//       `SELECT u.id, u.username, u.display_name, u.bio, f.created_at AS followed_at
//        FROM follows f
//        JOIN users u ON f.following_id = u.id
//        WHERE f.follower_id = ? AND u.is_active = true
//        ORDER BY f.created_at DESC`,
//       [userId]
//     );
//     return rows;
//   }

//   // get all followers for a user
//   static async getFollowers(userId) {
//     const query = `
//       SELECT 
//         u.id, 
//         u.username, 
//         u.display_name, 
//         u.bio, 
//         f.created_at AS followed_at
//       FROM follows f
//       JOIN users u ON f.follower_id = u.id
//       WHERE f.following_id = ? AND u.is_active = true
//       ORDER BY f.created_at DESC
//     `;

//     const [rows] = await pool.execute(query, [userId]);
//     return rows;
//   }

//   // get all users that a user is following
//   static async getFollowing(userId) {
//     const query = `
//       SELECT 
//         u.id, 
//         u.username, 
//         u.display_name, 
//         u.bio, 
//         f.created_at AS followed_at
//       FROM follows f
//       JOIN users u ON f.following_id = u.id
//       WHERE f.follower_id = ? AND u.is_active = true
//       ORDER BY f.created_at DESC
//     `;

//     const [rows] = await pool.execute(query, [userId]);
//     return rows;
//   }

// }

// module.exports = Follow;

// models/Follow.js
const { pool } = require('../config/database');

class Follow {

  static async create(followerId, followingId) {
    if (followerId == null || followingId == null) {
      throw new Error('Follower or following ID missing');
    }
    if (Number.isNaN(+followerId) || Number.isNaN(+followingId)) {
      throw new Error('Invalid user IDs');
    }
    if (+followerId === +followingId) {
      throw new Error('Cannot follow yourself');
    }

    const [exists] = await pool.execute(
      'SELECT id FROM follows WHERE follower_id = ? AND following_id = ? LIMIT 1',
      [followerId, followingId]
    );
    if (exists.length) {
      throw new Error('Already following this user');
    }

    await pool.execute(
      'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)',
      [followerId, followingId]
    );
  }

  static async isFollowing(followerId, followingId) {
    const [[row]] = await pool.query(
      `SELECT EXISTS(
        SELECT 1 FROM follows WHERE follower_id = ? AND following_id = ?
      ) AS ok`,
      [followerId, followingId]
    );
    return !!row.ok;
  }

  static async delete(followerId, followingId) {
    if (followerId == null || followingId == null) {
      throw new Error('Follower or following ID missing');
    }
    await pool.execute(
      'DELETE FROM follows WHERE follower_id = ? AND following_id = ?',
      [followerId, followingId]
    );
  }

  // ------------ FOLLOWERS ------------
  static async getFollowers(userId) {
    const query = `
      SELECT 
        u.id,
        u.username,
        u.display_name,
        u.bio,
        u.avatar_url,     -- 👈 ADD THIS
        f.created_at AS followed_at
      FROM follows f
      JOIN users u ON f.follower_id = u.id
      WHERE f.following_id = ? AND u.is_active = true
      ORDER BY f.created_at DESC
    `;
    const [rows] = await pool.execute(query, [userId]);
    return rows;
  }

  // ------------ FOLLOWING ------------
  static async getFollowing(userId) {
    const query = `
      SELECT 
        u.id,
        u.username,
        u.display_name,
        u.bio,
        u.avatar_url,     -- 👈 ADD THIS
        f.created_at AS followed_at
      FROM follows f
      JOIN users u ON f.following_id = u.id
      WHERE f.follower_id = ? AND u.is_active = true
      ORDER BY f.created_at DESC
    `;
    const [rows] = await pool.execute(query, [userId]);
    return rows;
  }

}

module.exports = Follow;
