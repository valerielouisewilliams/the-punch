// backend/src/config/firebaseAdmin.js
const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

function initFirebaseAdmin() {
  if (admin.apps.length) return admin;

  // Put your file here. Based on your `ls`, you have one in /home/ec2-user/
  // We'll support either location.
  const candidates = [
    "/home/ec2-user/firebase-admin.json",
    path.join(process.cwd(), "firebase-admin.json"),
    path.join(process.cwd(), "src", "config", "firebase-admin.json"),
  ];

  const filePath = candidates.find((p) => fs.existsSync(p));
  if (!filePath) {
    throw new Error(
      `Missing firebase-admin.json. Looked in: ${candidates.join(", ")}`
    );
  }

  const serviceAccount = JSON.parse(fs.readFileSync(filePath, "utf8"));

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log("Firebase Admin initialized using " + filePath);
  return admin;
}

module.exports = initFirebaseAdmin();
