const Punch = require('../models/Punch');
const User = require('../models/User');
const pushService = require('../services/pushService'); // adjust path if needed
const Notification = require('../models/Notification');

const punchController = {
    async sendPunch(req, res) {
    try {
        const { userId } = req.params;
        const senderId = req.user.id;

        if (!userId) {
        return res.status(400).json({ error: 'Target user ID is required' });
        }

        const receiverId = parseInt(userId, 10);
        const senderIdNum = parseInt(senderId, 10);

        if (isNaN(receiverId) || isNaN(senderIdNum)) {
        return res.status(400).json({ error: 'Invalid user ID format' });
        }

        if (receiverId === senderIdNum) {
        return res.status(400).json({ error: 'You cannot punch yourself' });
        }

        const receiver = await User.findById(receiverId);
        if (!receiver) {
        return res.status(404).json({ error: 'User not found' });
        }

        const sender = await User.findById(senderIdNum);
        if (!sender) {
        return res.status(404).json({ error: 'Sender not found' });
        }

        const punch = await Punch.create({
        sender_id: senderIdNum,
        receiver_id: receiverId
        });

        await Notification.create({
        recipient_user_id: receiverId,
        actor_user_id: senderIdNum,
        type: 'punch',
        entity_type: null,
        entity_id: null,
        message: null
        });

        try {
        await pushService.sendToUser(receiverId, {
            notification: {
            title: 'You got punched 👊',
            body: `${sender.display_name || sender.username} punched you`
            },
            data: {
            type: 'punch',
            punchId: String(punch.id),
            senderId: String(senderIdNum),
            receiverId: String(receiverId),
            senderUsername: String(sender.username || ''),
            senderDisplayName: String(sender.display_name || '')
            }
        });
        } catch (pushError) {
        console.error('Punch created but push failed:', pushError);
        }

        return res.status(201).json({
        success: true,
        message: 'Punch sent successfully',
        data: punch
        });
    } catch (error) {
        console.error('Send punch error:', error);
        return res.status(500).json({
        success: false,
        error: 'Failed to send punch',
        details: error.message
        });
    }
    },

  async getReceivedPunches(req, res) {
    try {
      const userId = req.user.id;
      let { limit = 20, offset = 0 } = req.query;

      limit = Number.isFinite(Number(limit)) && Number(limit) > 0 ? Number(limit) : 20;
      offset = Number.isFinite(Number(offset)) && Number(offset) >= 0 ? Number(offset) : 0;

      const punches = await Punch.findReceivedByUser(userId, limit, offset);

      return res.json({
        success: true,
        count: punches.length,
        data: punches
      });
    } catch (error) {
      console.error('Get received punches error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve received punches',
        details: error.message
      });
    }
  },

  async getSentPunches(req, res) {
    try {
      const userId = req.user.id;
      let { limit = 20, offset = 0 } = req.query;

      limit = Number.isFinite(Number(limit)) && Number(limit) > 0 ? Number(limit) : 20;
      offset = Number.isFinite(Number(offset)) && Number(offset) >= 0 ? Number(offset) : 0;

      const punches = await Punch.findSentByUser(userId, limit, offset);

      return res.json({
        success: true,
        count: punches.length,
        data: punches
      });
    } catch (error) {
      console.error('Get sent punches error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve sent punches',
        details: error.message
      });
    }
  }
};

module.exports = punchController;
