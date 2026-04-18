const { logger } = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  // Log lỗi đầy đủ ở server
  logger.error(`[ERROR] ${err.message}`, {
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    user: req.user?.id || 'anonymous',
  });

  // ✅ SECURITY: Không expose stack trace ra client
  const statusCode = err.statusCode || err.status || 500;
  const isDev = process.env.NODE_ENV === 'development';

  res.status(statusCode).json({
    error: isDev ? err.message : getPublicMessage(statusCode),
    ...(isDev && { stack: err.stack }),
  });
};

function getPublicMessage(status) {
  const messages = {
    400: 'Bad request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not found',
    409: 'Conflict',
    422: 'Unprocessable entity',
    429: 'Too many requests',
    500: 'Internal server error',
  };
  return messages[status] || 'Something went wrong';
}

module.exports = { errorHandler };
