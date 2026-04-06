// This service file is responsible for getting a spotify access token,
// caching it until it expires, and searching for tracks

const axios = require('axios');

// Token variables stored here so we don't need to request a new token every time
let spotifyAccessToken = null;
let tokenExpiresAt = 0;

// Permission step to get a token
async function getSpotifyAccessToken() {
  try {
    const now = Date.now();

    // Reuse token if it's still valid
    // Saves time, avoids rate limits 
    if (spotifyAccessToken && now < tokenExpiresAt) {
      return spotifyAccessToken;
    }

    // Case if environment variables are missing
    if (!process.env.SPOTIFY_CLIENT_ID || !process.env.SPOTIFY_CLIENT_SECRET) {
      throw new Error('Missing Spotify environment variables');
    }

    // Requst a new token, this is a post request to Spotify
    // This is POST since we're sending credentials
    const response = await axios.post( // Axios sends req -> gets response -> pares JSON -> gives it to us cleanly
      'https://accounts.spotify.com/api/token',
      new URLSearchParams({
        grant_type: 'client_credentials' // Tells Spotify that we are an app not a user, so we get an app level token
      }).toString(),
      { // Header to prove that we are the app we claim to be
        headers: {
          Authorization:
            'Basic ' +
            Buffer.from( // Encodes credentials into base64
              `${process.env.SPOTIFY_CLIENT_ID}:${process.env.SPOTIFY_CLIENT_SECRET}`
            ).toString('base64'),
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      }
    );

    // Save the token
    spotifyAccessToken = response.data.access_token;

    // expires_in is in seconds; subtract ~60 seconds as a safety buffer
    tokenExpiresAt = now + (response.data.expires_in - 60) * 1000;

    return spotifyAccessToken;
  } catch (error) {
    console.error(
      'Spotify token error:',
      error.response?.data || error.message
    );
    throw new Error('Failed to get Spotify access token');
  }
}

// Here we actually use the token 
async function searchTracks(query) {
  try {
    if (!query || !query.trim()) {
      throw new Error('Search query is required');
    }

    // Ensures we always have a valid token
    const token = await getSpotifyAccessToken();

    // Make search request
    const response = await axios.get('https://api.spotify.com/v1/search', {
      headers: {
        Authorization: `Bearer ${token}` // Authorization
      },
      params: { // Query parameters
        q: query.trim(),
        type: 'track',
        limit: 10
      }
    });


    // Clean up the response that Spotify sends you
    return response.data.tracks.items.map((track) => ({
      spotify_id: track.id,
      title: track.name,
      artist: track.artists.map((artist) => artist.name).join(', '),
      album_image: track.album.images?.[0]?.url || null,
      spotify_url: track.external_urls?.spotify || null,
      preview_url: track.preview_url || null
    }));
  } catch (error) {
    console.error(
      'Spotify search error:',
      error.response?.data || error.message
    );
    throw new Error('Failed to search Spotify tracks');
  }
}

module.exports = {
  getSpotifyAccessToken,
  searchTracks
};