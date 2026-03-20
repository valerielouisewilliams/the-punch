// Import the service file which gives us access to all our functions
const spotifyService = require('../services/spotifyService');

// Create a controller object
const spotifyController = {
  // Search Spotify tracks
  async searchTracks(req, res) {
    try {
      const { q } = req.query; // Read the query parameter

      // Validate query
      if (!q || q.trim().length === 0) {
        return res.status(400).json({
          error: 'Search query is required'
        });
      }

      // Call the service
      const tracks = await spotifyService.searchTracks(q.trim());

      // Return the JSON data
      res.json({
        message: 'Spotify tracks retrieved successfully',
        count: tracks.length,
        tracks
      });
    } catch (error) { // Error handling
      console.error('Spotify controller search error:', error);

      res.status(500).json({
        error: 'Failed to search Spotify tracks',
        details: error.message
      });
    }
  }
};

module.exports = spotifyController;