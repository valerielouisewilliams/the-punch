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
    const [result] = await pool.execute(
        'INSERT INTO comments (user_id, post_id, text, created_at) VALUES (?, ?, ?, NOW())',
        [userId, postId, text]
    );
    
    // Fetch the created comment with user info
    const [[comment]] = await pool.execute(`
        SELECT 
        c.*,
        u.username,
        u.display_name,
        u.avatar_url
        FROM comments c
        INNER JOIN users u ON c.user_id = u.id
        WHERE c.id = ?
    `, [result.insertId]);
    
    return {
        id: comment.id,
        postId: comment.post_id,
        userId: comment.user_id,
        text: comment.text,
        createdAt: comment.created_at,
        user: {
        id: comment.user_id,
        username: comment.username,
        displayName: comment.display_name,
        avatarUrl: comment.avatar_url
        }
    };
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
    // In your Comment model
    static async findByPostId(postId) {
        const query = `
            SELECT 
            c.*,
            u.username,
            u.display_name,
            u.avatar_url
            FROM comments c
            INNER JOIN users u ON c.user_id = u.id
            WHERE c.post_id = ? AND c.is_deleted = 0
            ORDER BY c.created_at DESC
        `;
        
        const [rows] = await pool.execute(query, [postId]);
        
        // Format the response to include user object
        return rows.map(row => ({
            id: row.id,
            postId: row.post_id,
            userId: row.user_id,
            text: row.text,
            createdAt: row.created_at,
            user: {
            id: row.user_id,
            username: row.username,
            displayName: row.display_name,
            avatarUrl: row.avatar_url
            }
        }));
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