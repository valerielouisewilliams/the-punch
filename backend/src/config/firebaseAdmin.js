// firebaseAdmin.js
const admin = require("firebase-admin");

function initFirebaseAdmin() {
  if (admin.apps.length) return admin;

  // export FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON");

  const serviceAccount = JSON.parse(json);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  return admin;
}

module.exports = initFirebaseAdmin();