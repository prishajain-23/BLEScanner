const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth');
const { pool } = require('../config/database');

/**
 * POST /api/devices/register-push
 * Register device token for push notifications
 */
router.post('/register-push', authenticateToken, async (req, res, next) => {
  try {
    const { device_token, platform } = req.body;

    if (!device_token) {
      return res.status(400).json({
        success: false,
        error: 'device_token is required'
      });
    }

    // Update user's device token
    await pool.query(
      'UPDATE users SET device_token = $1 WHERE id = $2',
      [device_token, req.user.id]
    );

    res.json({
      success: true,
      message: 'Device token registered successfully'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/devices/unregister-push
 * Unregister device token (e.g., on logout)
 */
router.delete('/unregister-push', authenticateToken, async (req, res, next) => {
  try {
    // Clear user's device token
    await pool.query(
      'UPDATE users SET device_token = NULL WHERE id = $1',
      [req.user.id]
    );

    res.json({
      success: true,
      message: 'Device token unregistered successfully'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
