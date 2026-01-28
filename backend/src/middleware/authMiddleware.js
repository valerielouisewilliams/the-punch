// // // middleware/authMiddleware.js
// // const jwt = require('jsonwebtoken');

// // function authenticateToken(req, res, next) {
// //   const auth = req.headers['authorization'] || '';
// //   const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
// //   if (!token) return res.status(401).json({ success: false, error: 'Unauthorized' });

// //   try {
// //     const decoded = jwt.verify(token, process.env.JWT_SECRET);
// //     req.user = { id: decoded.id };
// //     next();
// //   } catch {
// //     return res.status(401).json({ success: false, error: 'Unauthorized' });
// //   }
// // }

// // function optionalAuth(req, res, next) {
// //   const auth = req.headers['authorization'] || '';
// //   const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
// //   if (token) {
// //     try {
// //       const decoded = jwt.verify(token, process.env.JWT_SECRET);
// //       req.user = { id: decoded.id };
// //     } catch {/* ignore */}
// //   }
// //   next();
// // }

// // module.exports = { authenticateToken, optionalAuth };

// const admin = require('firebase-admin');
// const { pool } = require('../config/database');

// async function authenticateToken(req, res, next) {
//   console.log('--- Auth Debug ---');
//   console.log('Path:', req.path);
//   console.log('Token Header:', req.headers['authorization']);

//   const auth = req.headers['authorization'] || '';
//   console.log('Incoming Auth Header:', auth); // <--- Add this
//   const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;

//   if (!token) return res.status(401).json({ success: false, error: 'Unauthorized' });

//   try {
//     // 1. Verify the token with Firebase
//     const decodedToken = await admin.auth().verifyIdToken(token);
//     const firebaseUid = decodedToken.uid;

//     // 2. Look up the user in MySQL using the column you just created
//     const [rows] = await pool.execute(
//       'SELECT id, email, username FROM users WHERE firebase_uid = ?',
//       [firebaseUid]
//     );

//     if (rows.length === 0) {
//       return res.status(401).json({ success: false, error: 'User not found' });
//     }

//     // 3. Attach the REAL database user to the request
//     req.user = rows[0]; 
//     next();
//   } catch (error) {
//     console.error('Firebase Auth Error:', error.message);
//     return res.status(401).json({ success: false, error: 'Unauthorized' });
//   }
// }

// // // Optional Auth follows the same logic but doesn't block the request if it fails
// // async function optionalAuth(req, res, next) {
// //   const auth = req.headers['authorization'] || '';
// //   const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  
// //   if (token) {
// //     try {
// //       const decodedToken = await admin.auth().verifyIdToken(token);
// //       const [rows] = await pool.execute(
// //         'SELECT id, email, username FROM users WHERE firebase_uid = ?',
// //         [decodedToken.uid]
// //       );
// //       if (rows.length > 0) req.user = rows[0];
// //     } catch { /* ignore */ }
// //   }
// //   next();
// // }

// module.exports = { authenticateToken, optionalAuth };


// middleware/authMiddleware.js
const admin = require('firebase-admin');
const { pool } = require('../config/database');

async function authenticateToken(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;

  if (!token) {
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }

  try {
    // 1. Verify the token with Firebase
    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log('🔐 AUTH MIDDLEWARE STARTED');
    console.log('   Headers:', req.headers.authorization);
    console.log('   Token preview:', token?.substring(0, 20));
    console.log('✅ Firebase UID detected:', decodedToken.uid);
    console.log('🔍 Database query result:', rows);

    // 2. Look up the user in MySQL
    const [rows] = await pool.execute(
      'SELECT id, username, email FROM users WHERE firebase_uid = ?',
      [decodedToken.uid]
    );

    console.log('🔍 Database matches found:', rows.length);

    if (rows.length === 0) {
      console.log('❌ UID NOT FOUND IN DB. Check your firebase_uid column!');
      return res.status(401).json({ success: false, error: 'User not found' });
    }

    // 3. Attach user to request
    req.user = rows[0]; 
    next();
  } catch (error) {
    console.error('❌ AUTH ERROR:', error.message);
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }
}

// Optional auth - doesn't block if no token or invalid token
async function optionalAuth(req, res, next) {
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  
  // If there's a token, try to authenticate
  if (token) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      const [rows] = await pool.execute(
        'SELECT id, username, email FROM users WHERE firebase_uid = ?',
        [decodedToken.uid]
      );
      
      // If user found, attach to request
      if (rows.length > 0) {
        req.user = rows[0];
      }
    } catch (error) {
      // Silently fail - this is optional auth
      console.log('Optional auth failed (non-blocking):', error.message);
    }
  }
  
  // Always continue to next middleware/route
  next();
}

module.exports = { authenticateToken, optionalAuth };