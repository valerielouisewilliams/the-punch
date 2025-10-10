// defines how to work with comments in the database
const { pool } = require('../config/database');

class Comment {
    constructor(commentData) {
        this.id = commentData.id;
        this.post_id = commentData.post_id;
        this.user_id = commentData.user_id;
        this.text = commentData.text;
        this.created_at = commentData.created_at;
        this.updated_at = commentData.updated_at;
        this.is_deleted = commentData.is_deleted;
    }

    // add a comment
    static async create({ userId, postId, text }) {
        const query = 'INSERT INTO comments (user_id, post_id, text) VALUES (?, ?, ?)';

        const [result] = await pool.execute(query, [userId, postId, text]);

        return this.findById(result.insertId); 
    }

    // helper function: find a comment by its id
    static async findById(id) {
        const query = `
            SELECT c.*, u.username
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.id = ? AND c.is_deleted = 0
        `;

        const [rows] = await pool.execute(query, [id]);

        return rows.length > 0 ? new Comment(rows[0]) : null;
    }

    // get all comments for a post with user info
    static async findByPostId(postId) {
        const query = `
            SELECT c.*, u.username, u.display_name
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ? AND c.is_deleted = 0
            ORDER BY c.created_at ASC
        `;

        const [rows] = await pool.execute(query, [postId]);

        return rows.map(row => new Comment(row));
    }

    // helper function: checks if a user owns a comment (for deletion purposes)
    static async isOwner(commentId, userId) {
        const query = 'SELECT user_id FROM comments WHERE id = ?';

        const [rows] = await pool.execute(query, [commentId]);

        return rows.length > 0 && rows[0].user_id === userId;
    }

    // remove a comment (soft delete)
    static async softDelete(commentId) {
        const query = 'UPDATE comments SET is_deleted = 1, updated_at = NOW() WHERE id = ?';

        const [result] = await pool.execute(query, [commentId]);
        
        return result.affectedRows > 0;
    }

    // hard delete a comment (if needed)
    static async deleteById(commentId) {
        const query = 'DELETE FROM comments WHERE id = ?';

        const [result] = await pool.execute(query, [commentId]);
        
        return result.affectedRows > 0;
    }
}

module.exports = Comment;