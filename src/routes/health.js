const express = require('express');
const { pool } = require('../config/database');
const os = require('os');

const router = express.Router();

// GET /api/health — Basic health check (public)
router.get('/', async (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// GET /api/health/detailed — Chi tiết hơn (chỉ internal)
router.get('/detailed', async (req, res) => {
  const checks = {
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + 'MB',
    },
    cpu: os.loadavg(),
    database: 'unknown',
  };

  try {
    const conn = await pool.getConnection();
    await conn.query('SELECT 1');
    conn.release();
    checks.database = 'connected';
  } catch {
    checks.database = 'disconnected';
  }

  const isHealthy = checks.database === 'connected';
  res.status(isHealthy ? 200 : 503).json({
    status: isHealthy ? 'healthy' : 'unhealthy',
    ...checks,
  });
});

module.exports = router;
