const express = require('express');
const {
    createPost,
    getAllPosts,
    getPostById,
    updatePost,
    deletePost,
    getPostsByUserId
} = require('../controllers/postController');

const router = express.Router();

// Public routes (anyone can view posts)
router.get('/', getAllPosts); // GET /api/posts
router.get('/:id', getPostById); // GET /api/posts/123
router.get('/user/:user_id', getPostsByUserId); // GET /api/posts/user/123

// Protected routes
router.post('/', createPost); // POST /api/posts
router.put('/:id', updatePost); // PUT /api/posts/123
router.delete('/:id', deletePost); // DELETE /api/posts/123

module.exports = router;

