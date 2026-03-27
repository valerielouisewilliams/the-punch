const User = require('../models/User');
const Notification = require('../models/Notification');
const pushService = require('./pushService');

const MENTION_REGEX = /(^|[^A-Za-z0-9_])@([A-Za-z0-9_]+)/g;

function extractMentionedUsernames(text = '') {
  const input = String(text || '');
  const usernames = new Set();

  for (const match of input.matchAll(MENTION_REGEX)) {
    const username = String(match[2] || '').trim();
    if (username) usernames.add(username);
  }

  return [...usernames];
}

async function resolveMentionsFromText(text = '') {
  const extractedUsernames = extractMentionedUsernames(text);

  if (extractedUsernames.length === 0) {
    return {
      extractedUsernames: [],
      mentionedUsers: [],
      invalidUsernames: [],
    };
  }

  const matchedUsers = await User.findActiveByUsernames(extractedUsernames);
  const matchedByLower = new Map(
    matchedUsers.map((u) => [String(u.username).toLowerCase(), u])
  );

  const invalidUsernames = extractedUsernames.filter(
    (username) => !matchedByLower.has(String(username).toLowerCase())
  );

  const mentionedUsers = extractedUsernames
    .map((username) => matchedByLower.get(String(username).toLowerCase()))
    .filter(Boolean);

  return {
    extractedUsernames,
    mentionedUsers,
    invalidUsernames,
  };
}

async function notifyMentionedUsers({
  mentionedUsers = [],
  actorUserId,
  actorUsername,
  entityType,
  entityId,
  mentionSource,
}) {
  const actorIdNum = Number(actorUserId);
  const recipients = mentionedUsers.filter((u) => Number(u.id) !== actorIdNum);

  await Promise.all(
    recipients.map(async (recipient) => {
      await Notification.create({
        recipient_user_id: Number(recipient.id),
        actor_user_id: actorIdNum,
        type: 'mention',
        entity_type: entityType,
        entity_id: Number(entityId),
        message: null,
      });

      await pushService.sendToUser(recipient.id, {
        notification: {
          title: 'You were mentioned 👀',
          body: `${actorUsername || 'Someone'} mentioned you in a ${mentionSource}`,
        },
        data: {
          type: 'MENTION',
          source: String(mentionSource || ''),
          entityType: String(entityType || ''),
          entityId: String(entityId || ''),
          fromUserId: String(actorIdNum),
        },
      });
    })
  );
}

module.exports = {
  extractMentionedUsernames,
  resolveMentionsFromText,
  notifyMentionedUsers,
};
