const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { testConnection } = require('./config/database');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API routes (will be added)
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/contacts', require('./routes/contacts'));
app.use('/api/messages', require('./routes/messages'));
app.use('/api/devices', require('./routes/devices'));
app.use('/api/keys', require('./routes/keys'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Error handling middleware
app.use(require('./middleware/errorHandler'));

// Start server
async function startServer() {
  try {
    // Test database connection
    console.log('Testing database connection...');
    const dbConnected = await testConnection();

    if (!dbConnected) {
      console.error('Failed to connect to database. Exiting...');
      process.exit(1);
    }

    // Start listening
    app.listen(PORT, () => {
      console.log('');
      console.log('='.repeat(50));
      console.log('✅ BLEScanner Backend API Server Running');
      console.log('='.repeat(50));
      console.log(`🌐 Server: http://localhost:${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Database: Connected`);
      console.log('');
      console.log('Available endpoints:');
      console.log('  GET  /health - Health check');
      console.log('  POST /api/auth/register - Register user');
      console.log('  POST /api/auth/login - Login user');
      console.log('  GET  /api/users/search - Search users');
      console.log('  GET  /api/users/me - Get current user');
      console.log('  GET  /api/contacts - List contacts');
      console.log('  POST /api/contacts/add - Add contact');
      console.log('  DELETE /api/contacts/:id - Remove contact');
      console.log('  POST /api/messages/send - Send message');
      console.log('  GET  /api/messages/history - Get message history');
      console.log('  POST /api/messages/:id/read - Mark message as read');
      console.log('  POST /api/devices/register-push - Register device token');
      console.log('  DELETE /api/devices/unregister-push - Unregister device token');
      console.log('  POST /api/keys/upload - Upload Signal Protocol keys');
      console.log('  GET  /api/keys/bundle/:userId - Get prekey bundle');
      console.log('  GET  /api/keys/status - Check key setup status');
      console.log('='.repeat(50));
      console.log('');
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;
