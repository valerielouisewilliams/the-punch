// defines how to work with comments in the database
const { pool } = require('../config/database');

class Comment {
    constructor(commentData) {
        this.id = commentData.id;
        this.post_id = commentData.post_id;
        this.user_id = commentData.user_id;
        this.text = commentData.text;
        this.created_at = commentData.created_at;
        this.is_deleted = commentData.is_deleted;
    }

    // add a comment
    static async create({ userId, postId, text}) {
        const [result] = await pool.execute(
            'INSERT INTO comments (user_id, post_id, text) VALUES (?, ?, ?)'
        );
        return this.findById(result.insertId); 
    }

    // helper function: find a comment by its id
    static async findById(id) {
        const [rows] = await pool.execute(`
            SELECT c.*, u.username
            FROM comments c
            JOIN users u on c.user_id = u.id
            WHERE c.id = ?
            `, [id]);

        return rows.length > 0 ? new Comment(rows[0]) : null;
    }

    // get all comments for a post with user info
    static async findByPostId(postId) {
        const [rows] = await pool.execute(`
            SELECT c.*, u.username, u.username
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ?
            ORDER BY c.created_at ASC
            `, [postId]);
        return rows.map(row => new Comment(row));
    }

    // helper function: checks if a user owns a comment (for deletion purposes)
    static async isOwner(commentId, userId) {
        const [rows] = await pool.execute(
            'SELECT user_id from COMMENTS where id = ?',
            [commentId]
        );
        return rows.length > 0 && rows[0].user_id === userId;
    }

    // remove a comment 
    static async deleteById(commentId) {
        const [result] = await pool.execute(
            'DELETE FROM comments where id = ?',
            [commentId]
        );
        return result.affectedRows > 0;
    }

}

module.exports = Comment;