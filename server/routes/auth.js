const express = require('express');
const router = express.Router();
const AuthService = require('../services/AuthService');

/**
 * POST /api/auth/register
 * Register a new user
 */
router.post('/register', async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Validate required fields
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'Username and password are required'
      });
    }

    // Register user
    const result = await AuthService.register(username, password);

    res.status(201).json({
      success: true,
      user: result.user,
      token: result.token
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/login
 * Login existing user
 */
router.post('/login', async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Validate required fields
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'Username and password are required'
      });
    }

    // Login user
    const result = await AuthService.login(username, password);

    res.status(200).json({
      success: true,
      user: result.user,
      token: result.token
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
