const apn = require('apn');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

class PushService {
  constructor() {
    this.provider = null;
    this.isConfigured = false;
    this.initializeProvider();
  }

  /**
   * Initialize APNs provider
   */
  initializeProvider() {
    try {
      // Check if APNs is configured
      if (!process.env.APNS_KEY_ID || !process.env.APNS_TEAM_ID || !process.env.APNS_TOPIC) {
        console.warn('⚠️  APNs not configured - push notifications disabled');
        return;
      }

      const keyPath = process.env.APNS_KEY_PATH;

      // Check if key file exists
      if (!fs.existsSync(keyPath)) {
        console.error(`✗ APNs key file not found at: ${keyPath}`);
        return;
      }

      // Configure APNs provider
      const options = {
        token: {
          key: keyPath,
          keyId: process.env.APNS_KEY_ID,
          teamId: process.env.APNS_TEAM_ID
        },
        production: process.env.APNS_PRODUCTION === 'true'
      };

      this.provider = new apn.Provider(options);
      this.isConfigured = true;

      console.log('✓ APNs provider initialized');
      console.log(`  Environment: ${options.production ? 'Production' : 'Development (Sandbox)'}`);
      console.log(`  Topic: ${process.env.APNS_TOPIC}`);
    } catch (error) {
      console.error('✗ Failed to initialize APNs provider:', error.message);
    }
  }

  /**
   * Send push notification to device tokens
   * @param {string[]} deviceTokens - Array of APNs device tokens
   * @param {Object} notification - Notification data
   * @returns {Promise<Object>} - Results
   */
  async sendNotification(deviceTokens, notification) {
    if (!this.isConfigured) {
      console.warn('APNs not configured - skipping push notification');
      return { success: false, error: 'APNs not configured' };
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      return { success: false, error: 'No device tokens provided' };
    }

    try {
      const apnNotification = new apn.Notification();

      // Configure notification
      apnNotification.alert = notification.alert || notification.message;
      apnNotification.badge = notification.badge || 1;
      apnNotification.sound = notification.sound || 'default';
      apnNotification.topic = process.env.APNS_TOPIC;
      apnNotification.payload = notification.payload || {};
      apnNotification.mutableContent = 1;

      // Send to all device tokens
      const result = await this.provider.send(apnNotification, deviceTokens);

      // Log results
      if (result.failed.length > 0) {
        console.error('Push notification failures:', result.failed);
      }

      return {
        success: true,
        sent: result.sent.length,
        failed: result.failed.length,
        failures: result.failed
      };
    } catch (error) {
      console.error('Error sending push notification:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send message notification
   * @param {string[]} deviceTokens - Device tokens
   * @param {Object} messageData - Message information
   */
  async sendMessageNotification(deviceTokens, messageData) {
    const { from_username, message_text, device_name, encrypted } = messageData;

    let notificationBody;

    if (encrypted || !message_text) {
      // Encrypted message - show device name
      notificationBody = device_name || 'New message';
    } else {
      // Plaintext message (legacy) - show device name
      notificationBody = device_name || message_text;
    }

    const notification = {
      alert: {
        title: 'MOF',
        body: notificationBody
      },
      badge: 1,
      sound: 'default',
      payload: {
        type: 'message',
        message_id: messageData.message_id,
        from_user_id: messageData.from_user_id,
        from_username: from_username,
        device_name: device_name,
        encrypted: encrypted || false
      }
    };

    return this.sendNotification(deviceTokens, notification);
  }

  /**
   * Shutdown provider
   */
  shutdown() {
    if (this.provider) {
      this.provider.shutdown();
      console.log('APNs provider shut down');
    }
  }
}

module.exports = new PushService();
