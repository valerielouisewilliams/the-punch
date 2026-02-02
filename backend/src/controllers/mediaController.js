const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { v4: uuidv4 } = require("uuid");

const s3 = new S3Client({ region: process.env.AWS_REGION });

const presignAvatarUpload = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    const allowed = ["image/jpeg", "image/png", "image/webp"];
    const contentType = req.body?.contentType || "image/jpeg";
    if (!allowed.includes(contentType)) {
      return res.status(400).json({
        success: false,
        message: "Invalid contentType. Use image/jpeg, image/png, or image/webp."
      });
    }

    const ext =
      contentType === "image/png" ? "png" :
      contentType === "image/webp" ? "webp" :
      "jpg";

    const key = `profile-pictures/user_${userId}_${uuidv4()}.${ext}`;

    const cmd = new PutObjectCommand({
      Bucket: process.env.S3_BUCKET,
      Key: key,
      ContentType: contentType
    });

    const uploadUrl = await getSignedUrl(s3, cmd, { expiresIn: 60 });

    // Public S3 URL (works if bucket allows GetObject for profile-pictures/*)
    const publicUrl = `https://${process.env.S3_BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;

    res.json({ success: true, data: { uploadUrl, publicUrl, key } });
  } catch (e) {
    console.error("presignAvatarUpload error:", e);
    res.status(500).json({ success: false, message: "Could not create upload URL" });
  }
};

module.exports = { presignAvatarUpload };