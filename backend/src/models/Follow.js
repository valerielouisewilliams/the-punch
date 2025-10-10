// defines how to work with follows in the database
const { pool } = require('../config/database');

class Follow {
    constructor(followData) {
        this.id = followData.id;
        this.follower_id = followData.follower_id;
        this.following_id = followData.following_id;
        this.created_at = followData.created_at;
    }

    // create a follow
    static async create(followerId, followingId) {
        try {
            // users cannot follow themselves
            if (followerId === followingId) {
                throw new Error('Cannot follow yourself');
            }

            const query = 'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)';

            const [result] = await pool.execute(query, [followerId, followingId]);

            return this.findById(result.insertId);
        } catch (error) {
            if (error.code === 'ER_DUP_ENTRY' || error.code === 'SQLITE_CONSTRAINT') {
                throw new Error('Already following this user');
            }
            throw error;
        }
    }

    // delete a follow (unfollow)
    static async deleteByUsers(followerId, followingId) {
        const query = 'DELETE FROM follows WHERE follower_id = ? AND following_id = ?';

        const [result] = await pool.execute(query, [followerId, followingId]);

        return result.affectedRows > 0;
    }

    // helper: Check if following
    static async exists(followerId, followingId) {
        const query = 'SELECT id FROM follows WHERE follower_id = ? AND following_id = ?';

        const [rows] = await pool.execute(query, [followerId, followingId]);

        return rows.length > 0;
    }

    // helper: Find by ID
    static async findById(id) {
        const query = 'SELECT * FROM follows WHERE id = ?';

        const [rows] = await pool.execute(query, [id]);
        
        return rows.length > 0 ? new Follow(rows[0]) : null;
    }

    // get all followers for a user
    static async getFollowers(userId) {
        const query = `
            SELECT u.id, u.username, u.display_name, u.bio, f.created_at as followed_at
            FROM follows f
            JOIN users u ON f.follower_id = u.id
            WHERE f.following_id = ? AND u.is_active = true
            ORDER BY f.created_at DESC
        `;

        const [rows] = await pool.execute(query, [userId]);

        return rows;
    }

    // get all users that a user is following
    static async getFollowing(userId) {
        const query = `
            SELECT u.id, u.username, u.display_name, u.bio, f.created_at as followed_at
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