const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { logger, sanitizeLog } = require('../utils/logger');
const { loginValidation } = require('../middleware/validate');

const router = express.Router();

// POST /api/auth/login
router.post('/login', loginValidation, async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // ✅ SECURITY: Parameterized query - chống SQL Injection
    const [rows] = await pool.execute(
      'SELECT id, username, password_hash, role FROM users WHERE username = ? AND is_active = 1',
      [username]
    );

    // ✅ SECURITY: Thông báo chung để tránh user enumeration
    if (rows.length === 0) {
      logger.warn(`[AUTH] Failed login attempt for username: ${username} — IP: ${req.ip}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];

    // ✅ SECURITY: bcrypt so sánh password
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      logger.warn(`[AUTH] Wrong password for user: ${user.id} — IP: ${req.ip}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // ✅ SECURITY: JWT với expiry ngắn + issuer
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '1h', issuer: 'secure-product-app', algorithm: 'HS256' }
    );

    // Log thành công (không log password)
    logger.info(`[AUTH] Login success — user: ${user.id} IP: ${req.ip}`);

    // Update last login
    await pool.execute('UPDATE users SET last_login = NOW() WHERE id = ?', [user.id]);

    res.json({
      token,
      user: { id: user.id, username: user.username, role: user.role },
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/register
router.post('/register', loginValidation, async (req, res, next) => {
  try {
    const { username, password } = req.body;

    // Kiểm tra username đã tồn tại
    const [existing] = await pool.execute(
      'SELECT id FROM users WHERE username = ?', [username]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Username already exists' });
    }

    // ✅ SECURITY: Hash password với bcrypt (salt rounds = 12)
    const passwordHash = await bcrypt.hash(password, 12);

    const [result] = await pool.execute(
      'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
      [username, passwordHash, 'user']
    );

    logger.info(`[AUTH] New user registered — id: ${result.insertId}`);
    res.status(201).json({ message: 'User registered successfully', id: result.insertId });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
