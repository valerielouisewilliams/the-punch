// src/utils/postFormatter.js
const { pool } = require('../config/database');

class PostFormatter {
  /**
   * Format a single post with all necessary data
   * This ensures EVERY post returned from ANY endpoint has the same structure
   */
  static async formatPost(post, viewerId = null) {
    // Debug logging
    console.log('Formatting post:', {
        postId: post.id,
        viewerId: viewerId,
        raw_user_has_liked: post.user_has_liked,
        boolean_user_has_liked: Boolean(post.user_has_liked)
    });
    
    // If we already have stats (from a JOIN query), use them
    if (post.like_count !== undefined) {
      return {
        id: post.id,
        text: post.text,
        feelingEmoji: post.feeling_emoji || post.feelingEmoji,
        feelingName: post.feeling_name || post.feelingName || null,
        createdAt: post.created_at || post.createdAt,
        updatedAt: post.updated_at || post.updatedAt,
        
        author: {
          id: post.user_id || post.userId,
          username: post.username || post.author_username || 'unknown',
          displayName: post.display_name || post.displayName || post.author_display_name || null,
          avatarUrl: post.avatar_url || post.avatarUrl || post.author_avatar_url || null
        },
        
        stats: {
          likeCount: parseInt(post.like_count) || 0,
          commentCount: parseInt(post.comment_count) || 0,
          userHasLiked: Boolean(post.user_has_liked)
        }
      };
    }
    
    // Otherwise, fetch the stats separately
    const [[stats]] = await pool.execute(
      `SELECT 
        (SELECT COUNT(*) FROM likes WHERE post_id = ?) as like_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = ? AND is_deleted = 0) as comment_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = ? AND user_id = ?) as user_has_liked`,
      [post.id, post.id, post.id, viewerId]
    );
    
    // Fetch user info if not present
    let userInfo = {};
    if (!post.username) {
      const [[user]] = await pool.execute(
        'SELECT username, display_name, avatar_url FROM users WHERE id = ?',
        [post.user_id]
      );
      userInfo = user || {};
    }
    
    return {
      id: post.id,
      text: post.text,
      feelingEmoji: post.feeling_emoji,
      feelingName: post.feeling_name || null,
      createdAt: post.created_at,
      updatedAt: post.updated_at,
      
      author: {
        id: post.user_id,
        username: post.username || userInfo.username || 'unknown',
        displayName: post.display_name || userInfo.display_name || null,
        avatarUrl: post.avatar_url || userInfo.avatar_url || null
      },
      
      stats: {
        likeCount: parseInt(stats.like_count) || 0,
        commentCount: parseInt(stats.comment_count) || 0,
        userHasLiked: Boolean(stats.user_has_liked)
      }
    };
  }
  
  /**
   * Format multiple posts
   */
  static async formatPosts(posts, viewerId = null) {
    return Promise.all(posts.map(post => this.formatPost(post, viewerId)));
  }
  
  /**
   * Get posts with stats in a single query (more efficient)
   */
  static async getPostsWithStats(whereClause, params, viewerId = null) {
  const query = `
    SELECT 
      p.*,
      u.username,
      u.display_name,
      u.avatar_url,
      (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as like_count,
      (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = 0) as comment_count,
      EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = ?) as user_has_liked
    FROM posts p
    INNER JOIN users u ON p.user_id = u.id
    WHERE ${whereClause}
    ORDER BY p.created_at DESC
  `;

  const [rows] = await pool.execute(query, [viewerId, ...params]);

  // wait all the async formatters
  return await Promise.all(rows.map(row => this.formatPost(row, viewerId)));
}

}

module.exports = PostFormatter;