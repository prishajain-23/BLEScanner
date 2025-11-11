const { pool } = require('../config/database');

class MessageService {
  /**
   * Send a message to multiple recipients (LEGACY - plaintext)
   * @deprecated Use sendEncryptedMessages instead
   * @param {number} fromUserId - Sender's user ID
   * @param {number[]} toUserIds - Array of recipient user IDs
   * @param {string} messageText - Message content
   * @param {string} deviceName - Optional device name
   * @returns {Promise<Object>} - Created message object
   */
  async sendMessage(fromUserId, toUserIds, messageText, deviceName = null) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Insert message (plaintext - legacy)
      const messageResult = await client.query(
        'INSERT INTO messages (from_user_id, message_text, device_name, encryption_version, created_at) VALUES ($1, $2, $3, 0, NOW()) RETURNING id, from_user_id, message_text, device_name, created_at',
        [fromUserId, messageText, deviceName]
      );

      const message = messageResult.rows[0];

      // Insert message recipients
      for (const toUserId of toUserIds) {
        await client.query(
          'INSERT INTO message_recipients (message_id, to_user_id) VALUES ($1, $2)',
          [message.id, toUserId]
        );
      }

      await client.query('COMMIT');

      return {
        id: message.id,
        from_user_id: message.from_user_id,
        message_text: message.message_text,
        device_name: message.device_name,
        created_at: message.created_at,
        recipients: toUserIds
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Send encrypted messages (Signal Protocol E2EE)
   * @param {number} fromUserId - Sender's user ID
   * @param {Array<Object>} encryptedMessages - Array of {toUserId, encryptedPayload, senderRatchetKey, counter}
   * @param {string} deviceName - Optional device name
   * @returns {Promise<Object>} - Created message IDs
   */
  async sendEncryptedMessages(fromUserId, encryptedMessages, deviceName = null) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const messageIds = [];

      // Insert one message per recipient (each has unique encrypted payload)
      for (const encMsg of encryptedMessages) {
        const messageResult = await client.query(
          `INSERT INTO messages (
            from_user_id,
            encrypted_payload,
            sender_ratchet_key,
            counter,
            device_name,
            encryption_version,
            created_at
          ) VALUES ($1, $2, $3, $4, $5, 1, NOW())
          RETURNING id`,
          [
            fromUserId,
            encMsg.encryptedPayload,  // Buffer (BYTEA)
            encMsg.senderRatchetKey || null,  // Buffer (BYTEA)
            encMsg.counter || null,  // Integer
            deviceName
          ]
        );

        const messageId = messageResult.rows[0].id;
        messageIds.push(messageId);

        // Insert recipient record
        await client.query(
          'INSERT INTO message_recipients (message_id, to_user_id) VALUES ($1, $2)',
          [messageId, encMsg.toUserId]
        );
      }

      await client.query('COMMIT');

      return {
        success: true,
        messageIds,
        recipientCount: encryptedMessages.length
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get message history for a user (sent and received)
   * Supports both encrypted (v1) and plaintext (v0) messages
   * @param {number} userId - User ID
   * @param {number} limit - Max messages to return
   * @param {number} offset - Offset for pagination
   * @returns {Promise<Object>} - Messages and metadata
   */
  async getMessageHistory(userId, limit = 50, offset = 0) {
    // Get messages sent by user (with recipients)
    const sentMessages = await pool.query(
      `SELECT
        m.id,
        m.from_user_id,
        u.username as from_username,
        m.message_text,
        m.encrypted_payload,
        m.sender_ratchet_key,
        m.counter,
        m.encryption_version,
        m.device_name,
        m.created_at,
        true as is_sent,
        ARRAY_AGG(ru.username) as to_usernames
      FROM messages m
      JOIN users u ON m.from_user_id = u.id
      LEFT JOIN message_recipients mr ON m.id = mr.message_id
      LEFT JOIN users ru ON mr.to_user_id = ru.id
      WHERE m.from_user_id = $1
      GROUP BY m.id, u.username
      ORDER BY m.created_at DESC`,
      [userId]
    );

    // Get messages received by user
    const receivedMessages = await pool.query(
      `SELECT
        m.id,
        m.from_user_id,
        u.username as from_username,
        m.message_text,
        m.encrypted_payload,
        m.sender_ratchet_key,
        m.counter,
        m.encryption_version,
        m.device_name,
        m.created_at,
        false as is_sent,
        mr.read,
        mr.read_at
      FROM message_recipients mr
      JOIN messages m ON mr.message_id = m.id
      JOIN users u ON m.from_user_id = u.id
      WHERE mr.to_user_id = $1
      ORDER BY m.created_at DESC`,
      [userId]
    );

    // Combine and sort by timestamp
    const allMessages = [
      ...sentMessages.rows.map(msg => this._formatMessage(msg)),
      ...receivedMessages.rows.map(msg => this._formatMessage(msg))
    ].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    // Apply pagination
    const paginatedMessages = allMessages.slice(offset, offset + limit);

    return {
      messages: paginatedMessages,
      total: allMessages.length,
      limit,
      offset
    };
  }

  /**
   * Format message based on encryption version
   * @private
   */
  _formatMessage(msg) {
    const formatted = {
      id: msg.id,
      from_user_id: msg.from_user_id,
      from_username: msg.from_username,
      device_name: msg.device_name,
      created_at: msg.created_at,
      is_sent: msg.is_sent,
      encryption_version: msg.encryption_version || 0
    };

    // Add sent-specific fields
    if (msg.is_sent) {
      formatted.to_usernames = msg.to_usernames;
    } else {
      formatted.read = msg.read;
      formatted.read_at = msg.read_at;
    }

    // Include appropriate message content based on encryption version
    if (msg.encryption_version === 1) {
      // Encrypted message - return encrypted payload as base64
      formatted.encrypted_payload = msg.encrypted_payload ? msg.encrypted_payload.toString('base64') : null;
      formatted.sender_ratchet_key = msg.sender_ratchet_key ? msg.sender_ratchet_key.toString('base64') : null;
      formatted.counter = msg.counter;
    } else {
      // Plaintext message (legacy)
      formatted.message_text = msg.message_text;
    }

    return formatted;
  }

  /**
   * Mark a message as read
   * @param {number} messageId - Message ID
   * @param {number} userId - User ID marking the message as read
   * @returns {Promise<boolean>} - Success
   */
  async markAsRead(messageId, userId) {
    const result = await pool.query(
      'UPDATE message_recipients SET read = true, read_at = NOW() WHERE message_id = $1 AND to_user_id = $2',
      [messageId, userId]
    );

    return result.rowCount > 0;
  }

  /**
   * Get device tokens for users (for push notifications - Day 3)
   * @param {number[]} userIds - Array of user IDs
   * @returns {Promise<string[]>} - Array of device tokens
   */
  async getDeviceTokens(userIds) {
    const result = await pool.query(
      'SELECT device_token FROM users WHERE id = ANY($1) AND device_token IS NOT NULL',
      [userIds]
    );

    return result.rows.map(row => row.device_token);
  }
}

module.exports = new MessageService();
