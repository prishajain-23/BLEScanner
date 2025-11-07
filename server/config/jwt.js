require('dotenv').config();

// JWT configuration
const jwtConfig = {
  secret: process.env.JWT_SECRET || 'your-secret-key-change-this-in-production',
  expiresIn: process.env.JWT_EXPIRATION || '30d', // 30 days
  algorithm: 'HS256'
};

// Validate JWT secret on startup
if (process.env.NODE_ENV === 'production' && jwtConfig.secret === 'your-secret-key-change-this-in-production') {
  console.error('✗ FATAL: JWT_SECRET not set in production environment!');
  console.error('  Please set a secure JWT_SECRET in your .env file');
  process.exit(1);
}

if (jwtConfig.secret.length < 32) {
  console.warn('⚠ WARNING: JWT_SECRET is too short. Use at least 32 characters for security.');
}

module.exports = jwtConfig;
