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
        query = 'INSERT INTO comments (user_id, post_id, text) VALUES (?, ?, ?)';

        const [result] = await pool.execute(query, [userId, postId, text]);

        return this.findById(result.insertId); 
    }

    // helper function: find a comment by its id
    static async findById(id) {
        query = `
            SELECT c.*, u.username
            FROM comments c
            JOIN users u on c.user_id = u.id
            WHERE c.id = ?
            `;

        const [rows] = await pool.execute(query, [id]);

        return rows.length > 0 ? new Comment(rows[0]) : null;
    }

    // get all comments for a post with user info
    static async findByPostId(postId) {
        query = `
            SELECT c.*, u.username, u.username
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ?
            ORDER BY c.created_at ASC
            `;

        const [rows] = await pool.execute(query, [postId]);

        return rows.map(row => new Comment(row));
    }

    // helper function: checks if a user owns a comment (for deletion purposes)
    static async isOwner(commentId, userId) {
        query ='SELECT user_id from COMMENTS where id = ?';

        const [rows] = await pool.execute(query, [commentId]);

        return rows.length > 0 && rows[0].user_id === userId;
    }

    // remove a comment 
    static async deleteById(commentId) {
        query =  'DELETE FROM comments where id = ?';

        const [result] = await pool.execute(query,[commentId]);
        
        return result.affectedRows > 0;
    }

}

module.exports = Comment;