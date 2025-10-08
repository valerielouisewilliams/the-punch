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

            query = 'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)';

            const [result] = await pool.execute(query, [followerId, followingId]);

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
        query =  'DELETE FROM follows WHERE follower_id = ? AND following_id = ?';

        const [result] = await pool.execute(query, [followerId, followingId]);

        return result.affectedRows > 0;
    }

    // helper: Check if following
    static async exists(followerId, followingId) {
        query =  'SELECT id FROM follows WHERE follower_id = ? AND following_id = ?';

        const [rows] = await pool.execute(query, [followerId, followingId]);

        return rows.length > 0;
    }

    // helper:  Find by ID
    static async findById(id) {
        query =  'SELECT * FROM follows WHERE id = ?'

        const [rows] = await pool.execute(query, [id]);
        
        return rows.length > 0 ? new Follow(rows[0]) : null;
    }
}

module.exports = Follow;