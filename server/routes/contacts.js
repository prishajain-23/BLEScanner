const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth');
const { pool } = require('../config/database');

/**
 * GET /api/contacts
 * List all contacts for the current user
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT
        u.id,
        u.username,
        c.nickname,
        c.created_at as added_at
      FROM contacts c
      JOIN users u ON c.contact_user_id = u.id
      WHERE c.user_id = $1
      ORDER BY c.created_at DESC`,
      [req.user.id]
    );

    res.json({
      success: true,
      contacts: result.rows
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/contacts/add
 * Add a new contact by username
 */
router.post('/add', authenticateToken, async (req, res, next) => {
  try {
    const { contact_username } = req.body;

    if (!contact_username) {
      return res.status(400).json({
        success: false,
        error: 'contact_username is required'
      });
    }

    // Find the user to add as contact
    const userResult = await pool.query(
      'SELECT id, username FROM users WHERE username = $1',
      [contact_username]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const contactUser = userResult.rows[0];

    // Check if trying to add yourself
    if (contactUser.id === req.user.id) {
      return res.status(400).json({
        success: false,
        error: 'Cannot add yourself as a contact'
      });
    }

    // Check if contact already exists
    const existingContact = await pool.query(
      'SELECT id FROM contacts WHERE user_id = $1 AND contact_user_id = $2',
      [req.user.id, contactUser.id]
    );

    if (existingContact.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Contact already exists'
      });
    }

    // Add contact
    const result = await pool.query(
      'INSERT INTO contacts (user_id, contact_user_id, created_at) VALUES ($1, $2, NOW()) RETURNING created_at',
      [req.user.id, contactUser.id]
    );

    res.status(201).json({
      success: true,
      contact: {
        id: contactUser.id,
        username: contactUser.username,
        added_at: result.rows[0].created_at
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/contacts/:contactId
 * Remove a contact
 */
router.delete('/:contactId', authenticateToken, async (req, res, next) => {
  try {
    const { contactId } = req.params;

    // Delete the contact
    const result = await pool.query(
      'DELETE FROM contacts WHERE user_id = $1 AND contact_user_id = $2',
      [req.user.id, contactId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Contact not found'
      });
    }

    res.json({
      success: true,
      message: 'Contact removed'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
