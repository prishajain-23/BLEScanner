const AuthService = require('../services/AuthService');

/**
 * Authentication middleware
 * Verifies JWT token from Authorization header and adds user to request
 */
async function authenticateToken(req, res, next) {
  try {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No authentication token provided'
      });
    }

    // Verify token
    const decoded = await AuthService.verifyToken(token);

    // Get user data
    const user = await AuthService.getUserById(decoded.userId);

    // Add user to request object
    req.user = user;

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: error.message || 'Invalid authentication token'
    });
  }
}

module.exports = authenticateToken;
