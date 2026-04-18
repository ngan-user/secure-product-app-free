require('dotenv').config();
const app = require('./app');
const { logger } = require('./utils/logger');

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

async function startServer() {
  // ✅ Start server TRƯỚC, không chờ DB
  const server = app.listen(PORT, HOST, () => {
    logger.info(`🚀 Server running on port ${PORT}`);
    logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  });

  // ✅ Test DB connection SAU khi server đã start
  try {
    const { testConnection } = require('./config/database');
    await testConnection();
    logger.info('✅ Database connection established');
  } catch (error) {
    // ✅ Không crash app nếu DB chậm — retry sau
    logger.error(`⚠️ DB connection failed (will retry): ${error.message}`);
  }

  // Graceful shutdown
  const shutdown = (signal) => {
    logger.info(`📴 ${signal} received — shutting down gracefully`);
    server.close(() => {
      logger.info('✅ HTTP server closed');
      process.exit(0);
    });
    setTimeout(() => {
      logger.error('❌ Force shutdown after timeout');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT',  () => shutdown('SIGINT'));

  process.on('unhandledRejection', (reason) => {
    logger.error(`Unhandled Rejection: ${reason}`);
  });
}

startServer();
