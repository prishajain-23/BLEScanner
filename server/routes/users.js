const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth');
const { pool } = require('../config/database');

/**
 * GET /api/users/search?q=username
 * Search for users by username (partial match)
 */
router.get('/search', authenticateToken, async (req, res, next) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Search query is required'
      });
    }

    // Search for users (case-insensitive, partial match)
    const result = await pool.query(
      'SELECT id, username FROM users WHERE LOWER(username) LIKE LOWER($1) ORDER BY username LIMIT 20',
      [`%${q}%`]
    );

    res.json({
      success: true,
      users: result.rows
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/users/me
 * Get current user profile
 */
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    // Get contact count
    const contactCountResult = await pool.query(
      'SELECT COUNT(*) as count FROM contacts WHERE user_id = $1',
      [req.user.id]
    );

    res.json({
      success: true,
      user: {
        id: req.user.id,
        username: req.user.username,
        created_at: req.user.created_at,
        contact_count: parseInt(contactCountResult.rows[0].count)
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
