const { pool } = require('../config/database');

class MessageService {
  /**
   * Send a message to multiple recipients
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

      // Insert message
      const messageResult = await client.query(
        'INSERT INTO messages (from_user_id, message_text, device_name, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id, from_user_id, message_text, device_name, created_at',
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
   * Get message history for a user (sent and received)
   * @param {number} userId - User ID
   * @param {number} limit - Max messages to return
   * @param {number} offset - Offset for pagination
   * @returns {Promise<Object>} - Messages and metadata
   */
  async getMessageHistory(userId, limit = 50, offset = 0) {
    // Get messages sent by user
    const sentMessages = await pool.query(
      `SELECT
        m.id,
        m.from_user_id,
        u.username as from_username,
        m.message_text,
        m.device_name,
        m.created_at,
        true as is_sent
      FROM messages m
      JOIN users u ON m.from_user_id = u.id
      WHERE m.from_user_id = $1
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
      ...sentMessages.rows,
      ...receivedMessages.rows
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
