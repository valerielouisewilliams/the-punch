const express = require("express");
const router = express.Router();

const { presignAvatarUpload } = require("../controllers/mediaController");
const { authenticateToken } = require("../middleware/authMiddleware");

router.post("/presign/avatar", authenticateToken, presignAvatarUpload);

module.exports = router;