const User = require('../models/User');
const jwt = require('jsonwebtoken');

const getUserByUsername = (req, res) => {
    try {
        const { username } = req.params;

        if (username == null) {
                return res.status(400).json({
                success: false,
                message: 'Username must be a valid string'
            });
        }

        //TODO
    } catch (error) {
        console.error('Get post error:', error);
        res.status(500).json({
            success: false,
            message: 'Could not retrieve user'
        });
    }
}



