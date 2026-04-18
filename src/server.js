require('dotenv').config();
const app = require('./app');
const { logger } = require('./utils/logger');
const { testConnection } = require('./config/database');

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Bind to all interfaces trong container

async function startServer() {
  try {
    // Test DB connection trước khi start
    await testConnection();
    logger.info('✅ Database connection established');

    const server = app.listen(PORT, HOST, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    // Graceful shutdown
    const shutdown = (signal) => {
      logger.info(`📴 ${signal} received — shutting down gracefully`);
      server.close(() => {
        logger.info('✅ HTTP server closed');
        process.exit(0);
      });
      // Force kill nếu không đóng được sau 10s
      setTimeout(() => {
        logger.error('❌ Force shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    process.on('unhandledRejection', (reason) => {
      logger.error(`Unhandled Rejection: ${reason}`);
    });

  } catch (error) {
    logger.error(`❌ Failed to start server: ${error.message}`);
    process.exit(1);
  }
}

startServer();
