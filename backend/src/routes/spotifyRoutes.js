// Import express, router, controller function
const express = require('express');
const router = express.Router();
const { searchTracks } = require('../controllers/spotifyController');

/**
 * @route   GET /api/spotify/search
 * @desc    Search Spotify tracks
 * @access  Public
 * @query   q - search term
 */
router.get('/search', searchTracks);

module.exports = router;