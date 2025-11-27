// defines how to work with users in the database
const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  constructor(userData) {
    this.id = userData.id;
    this.username = userData.username;
    this.email = userData.email;
    this.password_hash = userData.password_hash;
    this.display_name = userData.display_name;
    this.bio = userData.bio;
    this.created_at = userData.created_at;
    this.avatar_url = userData.avatar_url;
  }

  // create a new user
  static async create({ username, email, password, display_name }) {
    // hash the password for security
    const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    const query = `INSERT INTO users (username, email, password_hash, display_name) 
       VALUES (?, ?, ?, ?)`;
    
    const [result] = await pool.execute(
      query,
      [username, email, password_hash, display_name || username]
    );
    
    // Return the new user (without password)
    return this.findById(result.insertId);
  }

  // find user by ID
  static async findById(id) {
    const query = 'SELECT * FROM users WHERE id = ? AND is_active = true';

    const [rows] = await pool.execute(query, [id]);
    
    return rows.length > 0 ? new User(rows[0]) : null;
  }

  // find user by email (for auth)
  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = ? AND is_active = true';

    const [rows] = await pool.execute(query, [email]);
    
    return rows.length > 0 ? new User(rows[0]) : null;
  }

  // check if password is correct
  async checkPassword(password) {
    return bcrypt.compare(password, this.password_hash);
  }

  // get followers/following stats for the profile by userId
  static async findByIdWithStats(userId) {
    const query = `
      SELECT u.*,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count
      FROM users u
      WHERE u.id = ? AND u.is_active = true
    `;

    const [rows] = await pool.execute(query, [userId]);

    if (rows.length === 0) return null;

    const user = new User(rows[0]);
    user.follower_count = parseInt(rows[0].follower_count);
    user.following_count = parseInt(rows[0].following_count);
      
    return user;
  }

  // find user by username
  static async findByUsername(username) {
    const query = 'SELECT id, username, display_name, bio, created_at FROM users WHERE username = ? AND is_active = true';

    const [rows] = await pool.execute(query, [username]);

    if (rows.length === 0) return null; 

    return new User(rows[0]);
  }

static async getUserFeed(
  currentUserId,
  days,          // e.g., req.query.days
  limit,
  offset,
  includeOwn     // e.g., req.query.includeOwn === 'true'
) {
    const userId     = Number(currentUserId);
  const pageLimit  = Number.isFinite(Number(limit))  ? Number(limit)  : 20;
  const pageOffset = Number.isFinite(Number(offset)) ? Number(offset) : 0;

  if (!Number.isFinite(userId)) throw new Error('currentUserId must be a number');

  let sql = `
    SELECT
      p.id, p.user_id, p.text, p.feeling_emoji, p.created_at, p.updated_at,
      u.username, u.display_name, u.avatar_url,
      (SELECT COUNT(*) FROM likes    WHERE post_id = p.id)                              AS like_count,
      (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0)           AS comment_count,
      EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?)                  AS user_has_liked
    FROM posts p
    INNER JOIN users u   ON p.user_id = u.id
    INNER JOIN follows f ON p.user_id = f.following_id
    WHERE
      (f.follower_id = ? ${includeOwn === 'true' || includeOwn === true ? 'OR p.user_id = ?' : ''})
      AND p.is_deleted = 0
      AND u.is_active = 1
      AND p.created_at >= (NOW() - INTERVAL 1 DAY)     -- <- only fetch posts from last 24 hours
    ORDER BY p.created_at DESC
    LIMIT CAST(? AS UNSIGNED) OFFSET CAST(? AS UNSIGNED)
  `;

  const params = [userId, userId];
  if (includeOwn === 'true' || includeOwn === true) params.push(userId);
  params.push(pageLimit, pageOffset);

  // Optional one-time debug:
  // console.log('PARAMS:', params, params.map(x => typeof x));

  const [rows] = await pool.execute(sql, params);
  return rows;
}


//   static async getUserFeed(userId, limit = 20, offset = 0, daysBack = 2) {
//   try {
//     // Query to get posts from users that the current user follows
//     // within the specified time period (default: last 2 days)
//     const [posts] = await pool.execute(
//       `SELECT 
//         p.id,
//         p.user_id,
//         p.text,
//         p.feeling_emoji,
//         p.created_at,
//         p.updated_at,
//         u.username,
//         u.display_name,
//         u.avatar_url,
//         -- Count likes for each post
//         (SELECT COUNT(*) FROM likes WHERE post_id = p.id) AS like_count,
//         -- Count comments for each post  
//         (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0) AS comment_count,
//         -- Check if current user liked this post
//         EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?) AS user_has_liked
//       FROM posts p
//       INNER JOIN users u ON p.user_id = u.id
//       INNER JOIN follows f ON p.user_id = f.following_id
//       WHERE 
//         f.follower_id = ?
//         AND p.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
//         AND p.is_deleted = 0
//         AND u.is_active = 1
//       ORDER BY p.created_at DESC
//       LIMIT ? OFFSET ?`,
//       [userId, userId, daysBack, limit, offset]
//     );

//     // Format the posts to include user info and engagement metrics
//     const formattedPosts = posts.map(post => ({
//       id: post.id,
//       text: post.text,
//       feelingEmoji: post.feeling_emoji,
//       createdAt: post.created_at,
//       updatedAt: post.updated_at,
//       user: {
//         id: post.user_id,
//         username: post.username,
//         displayName: post.display_name,
//         avatarUrl: post.avatar_url
//       },
//       engagement: {
//         likeCount: post.like_count,
//         commentCount: post.comment_count,
//         userHasLiked: Boolean(post.user_has_liked)
//       }
//     }));

//     return formattedPosts;
//   } catch (error) {
//     console.error('Error fetching user feed:', error);
//     throw error;
//   }
// }

// Alternative: Instance method version (call on a user object)
async getFeed(limit = 20, offset = 0, daysBack = 2) {
  return User.getUserFeed(this.id, limit, offset, daysBack);
}

// BONUS: Get feed including user's own posts
static async getUserFeedWithOwnPosts(userId, limit = 20, offset = 0, daysBack = 2) {
  try {
    const [posts] = await pool.execute(
      `SELECT 
        p.id,
        p.user_id,
        p.text,
        p.feeling_emoji,
        p.created_at,
        p.updated_at,
        u.username,
        u.display_name,
        u.avatar_url,
        (SELECT COUNT(*) FROM likes WHERE post_id = p.id) AS like_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0) AS comment_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?) AS user_has_liked
      FROM posts p
      INNER JOIN users u ON p.user_id = u.id
      LEFT JOIN follows f ON p.user_id = f.following_id AND f.follower_id = ?
      WHERE 
        (f.follower_id = ? OR p.user_id = ?)
        AND p.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        AND p.is_deleted = 0
        AND u.is_active = 1
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?`,
      [userId, userId, userId, userId, daysBack, limit, offset]
    );

    const formattedPosts = posts.map(post => ({
      id: post.id,
      text: post.text,
      feelingEmoji: post.feeling_emoji,
      createdAt: post.created_at,
      updatedAt: post.updated_at,
      isOwnPost: post.user_id === userId, // Flag to identify user's own posts
      user: {
        id: post.user_id,
        username: post.username,
        displayName: post.display_name,
        avatarUrl: post.avatar_url
      },
      engagement: {
        likeCount: post.like_count,
        commentCount: post.comment_count,
        userHasLiked: Boolean(post.user_has_liked)
      }
    }));

    return formattedPosts;
  } catch (error) {
    console.error('Error fetching user feed with own posts:', error);
    throw error;
  }
}

static async findByIdWithStatsAndRelationship(targetId, viewerId = null) {
    const [[row]] = await pool.query(
      `
      SELECT
        u.id, u.username, u.email, u.password_hash, u.display_name, u.bio, u.created_at,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id  = u.id) AS following_count,
        CASE
          WHEN ? IS NULL THEN NULL                                  -- unauthenticated viewer
          WHEN ? = u.id THEN NULL                                   -- viewing own profile
          ELSE EXISTS(
            SELECT 1 FROM follows f WHERE f.follower_id = ? AND f.following_id = u.id
          )
        END AS is_following
      FROM users u
      WHERE u.id = ?
      LIMIT 1
      `,
      [viewerId, viewerId, viewerId, targetId]
    );

    if (!row) return null;

    const user = new User(row);
    user.follower_count  = Number(row.follower_count || 0);
    user.following_count = Number(row.following_count || 0);
    // IMPORTANT: preserve tri-state — null means "not applicable"
    user.is_following = (row.is_following === null) ? null : !!row.is_following;
    return user;
  }

  static async updateProfile(id, { display_name, bio, avatar_url }) {
  const query = `
    UPDATE users
    SET display_name = ?, bio = ?, avatar_url = ?
    WHERE id = ? AND is_active = true
  `;

  await pool.execute(query, [
    display_name,
    bio,
    avatar_url,
    id
  ]);

  return this.findByIdWithStats(id);
}


  getPublicProfile() {
    return {
      id: this.id,
      username: this.username,
      display_name: this.display_name,
      bio: this.bio,
      created_at: this.created_at,
      follower_count: this.follower_count ?? 0,
      following_count: this.following_count ?? 0,
      avatar_url: this.avatar_url,
      // include is_following (true/false) or null if not applicable
      is_following: (this.is_following === undefined) ? null : this.is_following,
    };
  }
}

module.exports = User;