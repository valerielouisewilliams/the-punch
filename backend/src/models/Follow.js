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
            if (followerId == followingId) {
                throw new Error('Cannot follow yourself');
            }

            const [result] = await pool.execute(
                'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)',
                [followerId, followingId]
            );
            return this.findById(result.insertId);
        } catch (error) {
            if (error.code == 'ER_DUP_ENTRY') {
                throw new Error('Already following this user')
            }
            throw error;
        }
    }

    // delete a follow
    static async deleteByUsers(followerId, followingId) {
        const [result] = await pool.execute(
        'DELETE FROM follows WHERE follower_id = ? AND following_id = ?',
        [followerId, followingId]
        );
        return result.affectedRows > 0;
    }

    // helper: Check if following
    static async exists(followerId, followingId) {
        const [rows] = await pool.execute(
        'SELECT id FROM follows WHERE follower_id = ? AND following_id = ?',
        [followerId, followingId]
        );
        return rows.length > 0;
    }

    // helper:  Find by ID
    static async findById(id) {
        const [rows] = await pool.execute(
        'SELECT * FROM follows WHERE id = ?',
        [id]
        );
        return rows.length > 0 ? new Follow(rows[0]) : null;
    }
}

module.exports = Follow;