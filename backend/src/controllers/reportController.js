const nodemailer = require('nodemailer');
const Post = require('../models/Post');
const User = require('../models/User');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.HQ_EMAIL,
    pass: process.env.HQ_EMAIL_PASSWORD
  }
});

const reportPost = async (req, res) => {
  try {
    const { post_id, reason } = req.body;
    const reporterId = req.user.id;

    if (!post_id || !reason) {
      return res.status(400).json({ success: false, message: 'post_id and reason are required' });
    }

    const post = await Post.findById(post_id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found' });
    }

    // Fetch both users
    const postAuthor = await User.findById(post.user_id);
    const reporter = await User.findById(reporterId);

    const mailOptions = {
      from: process.env.HQ_EMAIL,
      to: process.env.HQ_EMAIL,
      subject: `New Report: ${reason}`,
      html: `
        <h2>New Post Report</h2>
        <table style="border-collapse: collapse; width: 100%;">
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Report Reason</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">${reason}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Post ID</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">${post_id}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Post Content</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">${post.text}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Post Author</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">@${postAuthor?.username ?? 'unknown'} (ID: ${post.user_id})</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Posted At</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">${post.created_at}</td>
          </tr>
          <tr>
            <td style="padding: 8px; border: 1px solid #ddd;"><strong>Reported By</strong></td>
            <td style="padding: 8px; border: 1px solid #ddd;">@${reporter?.username ?? 'unknown'} (ID: ${reporterId})</td>
          </tr>
        </table>
      `
    };

    await transporter.sendMail(mailOptions);

    return res.status(200).json({ success: true, message: 'Report submitted' });

  } catch (err) {
    console.error('Report error:', err);
    return res.status(500).json({ success: false, message: 'Failed to submit report' });
  }
};

module.exports = { reportPost };