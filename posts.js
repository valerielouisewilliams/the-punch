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
router.get('/id:', getPostById); // GET /api/posts/123
router.get('/user/:user_id', getPostsByUserId); // GET /api/posts/user/123

//TODO: finish this!

