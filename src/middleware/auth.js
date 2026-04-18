const jwt = require('jsonwebtoken');
const { logger } = require('../utils/logger');

const authenticateToken = (req, res, next) => {
  // ✅ SECURITY: Token từ Authorization header (Bearer), không từ query string
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : null;

  if (!token) {
    logger.warn(`[AUTH] No token provided — IP: ${req.ip} URL: ${req.originalUrl}`);
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    // ✅ SECURITY: Verify với secret từ env, không hard-code
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256'],
      issuer: 'secure-product-app',
    });

    req.user = decoded;
    next();
  } catch (err) {
    logger.warn(`[AUTH] Invalid token — IP: ${req.ip} Error: ${err.message}`);

    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(403).json({ error: 'Invalid token' });
  }
};

const requireAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin') {
    logger.warn(`[AUTH] Unauthorized admin access — user: ${req.user?.id}`);
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

module.exports = { authenticateToken, requireAdmin };
