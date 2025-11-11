const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth');
const MessageService = require('../services/MessageService');
const PushService = require('../services/PushService');

/**
 * POST /api/messages/send
 * Send a plaintext message (LEGACY - for backwards compatibility)
 * @deprecated Clients should use /api/messages/send-encrypted instead
 */
router.post('/send', authenticateToken, async (req, res, next) => {
  try {
    const { to_user_ids, message, device_name } = req.body;

    // Validate required fields
    if (!to_user_ids || !Array.isArray(to_user_ids) || to_user_ids.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'to_user_ids must be a non-empty array'
      });
    }

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'message is required'
      });
    }

    // Send message
    const sentMessage = await MessageService.sendMessage(
      req.user.id,
      to_user_ids,
      message.trim(),
      device_name
    );

    // Send push notifications to recipients
    let pushResult = { success: false };
    try {
      const deviceTokens = await MessageService.getDeviceTokens(to_user_ids);

      if (deviceTokens.length > 0) {
        pushResult = await PushService.sendMessageNotification(deviceTokens, {
          from_username: req.user.username,
          message_text: message.trim(),
          device_name: device_name,
          message_id: sentMessage.id,
          from_user_id: req.user.id
        });
      }
    } catch (pushError) {
      console.error('Push notification error:', pushError);
      // Continue even if push fails
    }

    res.status(201).json({
      success: true,
      message: sentMessage,
      push_sent: pushResult.success || false,
      push_details: pushResult
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/messages/send-encrypted
 * Send encrypted messages using Signal Protocol E2EE
 *
 * Body: {
 *   messages: [{
 *     to_user_id: number,
 *     encrypted_payload: string (base64),
 *     sender_ratchet_key: string (base64, optional),
 *     counter: number (optional)
 *   }],
 *   device_name: string (optional)
 * }
 */
router.post('/send-encrypted', authenticateToken, async (req, res, next) => {
  try {
    const { messages, device_name } = req.body;

    // Validate required fields
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'messages must be a non-empty array'
      });
    }

    // Validate message structure
    for (const msg of messages) {
      if (!msg.to_user_id || !msg.encrypted_payload) {
        return res.status(400).json({
          success: false,
          error: 'Each message must have to_user_id and encrypted_payload'
        });
      }
    }

    // Convert base64 to buffers
    const encryptedMessages = messages.map(msg => ({
      toUserId: msg.to_user_id,
      encryptedPayload: Buffer.from(msg.encrypted_payload, 'base64'),
      senderRatchetKey: msg.sender_ratchet_key ? Buffer.from(msg.sender_ratchet_key, 'base64') : null,
      counter: msg.counter || null
    }));

    // Send encrypted messages
    const result = await MessageService.sendEncryptedMessages(
      req.user.id,
      encryptedMessages,
      device_name
    );

    // Send push notifications (sender-only, no message content)
    let pushResult = { success: false };
    try {
      const recipientIds = messages.map(m => m.to_user_id);
      const deviceTokens = await MessageService.getDeviceTokens(recipientIds);

      if (deviceTokens.length > 0) {
        pushResult = await PushService.sendMessageNotification(deviceTokens, {
          from_username: req.user.username,
          message_text: null,  // No plaintext (encrypted)
          device_name: device_name,
          message_id: result.messageIds[0],  // First message ID
          from_user_id: req.user.id,
          encrypted: true  // Flag for generic notification
        });
      }
    } catch (pushError) {
      console.error('Push notification error:', pushError);
      // Continue even if push fails
    }

    res.status(201).json({
      success: true,
      message_ids: result.messageIds,
      recipient_count: result.recipientCount,
      push_sent: pushResult.success || false
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/messages/history?limit=50&offset=0
 * Get message history (sent and received)
 */
router.get('/history', authenticateToken, async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    const history = await MessageService.getMessageHistory(req.user.id, limit, offset);

    res.json({
      success: true,
      ...history
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/messages/:messageId/read
 * Mark a message as read
 */
router.post('/:messageId/read', authenticateToken, async (req, res, next) => {
  try {
    const { messageId } = req.params;

    const success = await MessageService.markAsRead(messageId, req.user.id);

    if (!success) {
      return res.status(404).json({
        success: false,
        error: 'Message not found or already read'
      });
    }

    res.json({
      success: true,
      message: 'Message marked as read'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
