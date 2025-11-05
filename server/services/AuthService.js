const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const jwtConfig = require('../config/jwt');

const SALT_ROUNDS = 10;

class AuthService {
  /**
   * Register a new user
   * @param {string} username - Username (alphanumeric + underscore)
   * @param {string} password - Plain text password (will be hashed)
   * @returns {Promise<{user, token}>} - User object and JWT token
   */
  async register(username, password) {
    // Validate username format
    if (!/^[a-zA-Z0-9_]{3,50}$/.test(username)) {
      const error = new Error('Username must be 3-50 characters (alphanumeric and underscore only)');
      error.statusCode = 400;
      throw error;
    }

    // Validate password length
    if (password.length < 8) {
      const error = new Error('Password must be at least 8 characters');
      error.statusCode = 400;
      throw error;
    }

    // Check if username already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE username = $1',
      [username]
    );

    if (existingUser.rows.length > 0) {
      const error = new Error('Username already exists');
      error.statusCode = 400;
      throw error;
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    // Insert user into database
    const result = await pool.query(
      'INSERT INTO users (username, password_hash, created_at) VALUES ($1, $2, NOW()) RETURNING id, username, created_at',
      [username, passwordHash]
    );

    const user = result.rows[0];

    // Generate JWT token
    const token = this.generateToken(user.id);

    return {
      user: {
        id: user.id,
        username: user.username,
        created_at: user.created_at
      },
      token
    };
  }

  /**
   * Login existing user
   * @param {string} username - Username
   * @param {string} password - Plain text password
   * @returns {Promise<{user, token}>} - User object and JWT token
   */
  async login(username, password) {
    // Find user by username
    const result = await pool.query(
      'SELECT id, username, password_hash, created_at FROM users WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      const error = new Error('Invalid credentials');
      error.statusCode = 401;
      throw error;
    }

    const user = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      const error = new Error('Invalid credentials');
      error.statusCode = 401;
      throw error;
    }

    // Update last login
    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE id = $1',
      [user.id]
    );

    // Generate JWT token
    const token = this.generateToken(user.id);

    return {
      user: {
        id: user.id,
        username: user.username
      },
      token
    };
  }

  /**
   * Generate JWT token for user
   * @param {number} userId - User ID
   * @returns {string} - JWT token
   */
  generateToken(userId) {
    return jwt.sign(
      { userId },
      jwtConfig.secret,
      {
        expiresIn: jwtConfig.expiresIn,
        algorithm: jwtConfig.algorithm
      }
    );
  }

  /**
   * Verify JWT token
   * @param {string} token - JWT token
   * @returns {Promise<{userId}>} - Decoded token payload
   */
  async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, jwtConfig.secret, {
        algorithms: [jwtConfig.algorithm]
      });
      return decoded;
    } catch (error) {
      const err = new Error('Invalid or expired token');
      err.statusCode = 401;
      throw err;
    }
  }

  /**
   * Get user by ID
   * @param {number} userId - User ID
   * @returns {Promise<Object>} - User object
   */
  async getUserById(userId) {
    const result = await pool.query(
      'SELECT id, username, created_at, last_login FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return result.rows[0];
  }
}

module.exports = new AuthService();
