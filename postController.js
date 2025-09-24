// importing things we need
const Post = require('../models/Post');
const jwt = require('jsonwebtoken')

//TODO: need to remove this when we add a FindAll() in post model file
const { pool } = require('../config/database');

// helper function to get user from token
const getUserFromToken = req => {
    // get a token from the authorization header
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) return null; // no token means a user is not signed in

    try {
        // verify the token, get user info
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch {
        return null; // invalid token, cannot log in
    }
};

// helper to validate emojis
const isValidEmoji = (str) => {
    // check for emoji unicode ranges
    const emojiRegex = /^(?:[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1F018}-\u{1F270}]|[\u{238C}-\u{2454}]|[\u{20D0}-\u{20FF}]|[\u{FE00}-\u{FE0F}]|[\u{1F200}-\u{1F2FF}]|[\u{1F700}-\u{1F77F}]|[\u{1F780}-\u{1F7FF}]|[\u{1F800}-\u{1F8FF}]|[\u{1FAB0}-\u{1FABF}]|[\u{1FAC0}-\u{1FAFF}]|[\u{1FAD0}-\u{1FAFF}]|[\u{1FB00}-\u{1FBFF}])+$/u;
    return emojiRegex.test(str);
};

// creating a post 
const createPost = async (req, res) => {
    try {
        // check authentication for user
        const user = getUserFromToken(req);
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required to create a post'
            });
        }

        // get data from request
        const { text, feeling_emoji } = req.body;

        // validate required fields
        if (!text || text.trim() == '') {
            return res.status(400).json({
                success: false,
                message: 'Post text is required and cannot be empty'
            });
        }

        if (text.trim().length > 180) {
            return res.status(400).json({
                success: false,
                message: 'Post text cannot exceed 180 characters'
            });
        }

        if (!feeling_emoji || !isValidEmoji(feeling_emoji)) {
            return res.status(400).json({
                success: false,
                message: 'Valid emoji is required'
            });
        }

        // create the most using Post.js model
        const postData = {
            user_id: user.id,
            text: text.trim(),
            feeling_emoji: feeling_emoji
        }

        const post = await Post.create(postData);

        // return a success response
        res.status(201).json({
            success: true,
            message: 'Post created successfuly',
            data: post
        });

    } catch (error) {
        console.error('Create post error:', error);
        res.status(500).json({
            success: false,
            message: 'Something went wrong creating the post'
        });
    }
};

// retrieving all posts
const getAllPosts = async (req, res) => {
    try {
        //TODO: add a findAll() in Post.js so we dont have to query directly
        const[rows] = await pool.execute(
            'SELECT * FROM posts WHERE is_deleted = 0 ORDER BY created_at DESC'
        );
        const posts = rows.map(row => new Post(row));

        res.json({
            success: true,
            data: posts,
            count: posts.length
        });
    } catch (error) {
        console.error('Get posts error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not retrieve posts'
        });
    }
};

const getPostById = async (req, res) => {
    try {
        const { id } = req.params;

        if (isNaN(id)) {
            return res.status(400).json({
                success: false,
                message: 'Post ID must be a valid number'
            });
        }

        const post = await Post.findById(parseInt(id));

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found'
            });
        }

        res.json({
            success: true,
            data: post
        });

    } catch (error) {
        console.error('Get post error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not retrieve post'
        });
    }
};

const updatePost = async (req, res) => {
    try {
        const user = getUserFromToken(req);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { id } = req.params;
        const{ text, feeling_emoji }= req.body;

        // validate the post ID
        if (isNaN(id)) {
            return res.status(400).json({
                success: false,
                message: 'Post ID must be a valid number'
            });
        }

        // find the post
        const post = await Post.findById(parseInt(id));

        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found'
            });
        }

        // check if user owns this post
        if (post.user_id != user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only edit your own posts'
            });
        }

        // validate new data if it's provided
        if (text != undefined) {
            if (!text || text.trim() == '') {
                return res.status(400).json({
                    success: false,
                    message: 'Post text cannot be empty'
                });
            }

            if (text.trim().length > 180) {
                return res.status(400).json({
                    success: false,
                    message: 'Post text cannot exceed 180 characters'
                });
            }
        }

        if (feeling_emoji != undefined && feeling_emoji && !isValidEmoji(feeling_emoji)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid emoji format'
            })
        }

        // update the post
        const updateData = {};
        if (text != undefined) updateData.text = text.trim();
        if (feeling_emoji != undefined) updateData.feeling_emoji = feeling_emoji;

        const updatedPost = await Post.update(parseInt(id), updateData);

    } catch (error) {
        console.error('Update post error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not update post'
        });
    }
};

// deleting a post
const deletePost = async (req, res) => {
    try {
        // validate the user first
        const user = getUserFromToken(req);
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { id } = req.params;

        if (isNaN(id)) {
            return res.status(400).json({
                success: false,
                message: 'Post ID must be a valid number'
            });
        }

        const post = await Post.fidndById(parseInt(id));
        if (!post) {
            return res.status(404).json({
                success: false,
                message: 'Post not found'
            });
        }

        // check for ownership of post
        if (post.user_id != user.id) {
            return res.status(403).json({
                success: false,
                message: 'You can only delete your own posts'
            });
        }

        // soft delete the post (set is_deleted = true)
        await Post.softDelete(parseInt(id));

        res.json({
            success: true,
            message: 'Post deleted successfuly'
        });

    } catch (error) {
        console.error('Delete post error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not delete post'
        });
    }
};

// get posts made by a specific user
const getPostsByUserId = async (req, res) => {
    try {
        const { user_id } = req.params;

        if (isNaN(user_id)) {
            return res.status(400).json({
                success: false,
                message: 'User ID must be a valid number'
            });
        }

        const posts = await Post.findAllByUser(parseInt(user_id));

        res.json({
            success: true,
            data: posts,
            count: posts.length
        });

    } catch (error) {
        console.error('Get user posts error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not retrieve user posts'
        });
    }
};

module.exports = {
    createPost,
    getAllPosts,
    getPostById,
    updatePost,
    deletePost,
    getPostsByUserId
};