const admin = require("../config/firebaseAdmin");
const User = require("../models/User");

// Require auth AND require the Firebase user to be linked to a DB user row
async function authenticateToken(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: "Missing token" });

    const decoded = await admin.auth().verifyIdToken(token);

    //TESTING NORMALIZE
    req.user = {
      id: decoded.uid,        // normalize
      uid: decoded.uid,
      email: decoded.email,
    };


    // decoded.uid is the Firebase UID
    const dbUser = await User.findByFirebaseUid(decoded.uid);
    if (!dbUser) {
      return res.status(403).json({
        success: false,
        message: "User not linked. Call POST /api/auth/session first."
      });
    }

    req.user = { id: dbUser.id, firebase_uid: decoded.uid, email: decoded.email };
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: "Invalid token" });
  }
}

// Optional auth (don’t fail if missing token)
async function optionalAuth(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return next();

    const decoded = await admin.auth().verifyIdToken(token);
    const dbUser = await User.findByFirebaseUid(decoded.uid);
    if (dbUser) req.user = { id: dbUser.id, firebase_uid: decoded.uid, email: decoded.email };
    next();
  } catch {
    next();
  }
}

module.exports = { authenticateToken, optionalAuth };