const express = require('express');
const { pool } = require('../config/database');
const { logger } = require('../utils/logger');
const { productValidation, idValidation } = require('../middleware/validate');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/products — Lấy danh sách sản phẩm
router.get('/', async (req, res, next) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 10); // max 50/page
    const offset = (page - 1) * limit;
    const search = req.query.search ? `%${req.query.search}%` : '%';

    // ✅ SECURITY: Parameterized query
    const [products] = await pool.execute(
      `SELECT id, name, description, price, stock, category, created_at, updated_at
       FROM products
       WHERE (name LIKE ? OR category LIKE ?) AND is_deleted = 0
       ORDER BY created_at DESC
       LIMIT ? OFFSET ?`,
      [search, search, limit, offset]
    );

    const [[{ total }]] = await pool.execute(
      'SELECT COUNT(*) as total FROM products WHERE (name LIKE ? OR category LIKE ?) AND is_deleted = 0',
      [search, search]
    );

    logger.info(`[PRODUCTS] List fetched — user: ${req.user.id} page: ${page}`);
    res.json({ products, total, page, limit, pages: Math.ceil(total / limit) });
  } catch (err) {
    next(err);
  }
});

// GET /api/products/:id
router.get('/:id', idValidation, async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, name, description, price, stock, category, created_at FROM products WHERE id = ? AND is_deleted = 0',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Product not found' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});

// POST /api/products — Tạo sản phẩm mới
router.post('/', productValidation, async (req, res, next) => {
  try {
    const { name, description, price, stock, category } = req.body;

    const [result] = await pool.execute(
      'INSERT INTO products (name, description, price, stock, category, created_by) VALUES (?, ?, ?, ?, ?, ?)',
      [name, description || null, price, stock, category, req.user.id]
    );

    logger.info(`[PRODUCTS] Created id:${result.insertId} by user:${req.user.id}`);
    res.status(201).json({ message: 'Product created', id: result.insertId });
  } catch (err) {
    next(err);
  }
});

// PUT /api/products/:id
router.put('/:id', idValidation, productValidation, async (req, res, next) => {
  try {
    const { name, description, price, stock, category } = req.body;

    const [existing] = await pool.execute(
      'SELECT id, created_by FROM products WHERE id = ? AND is_deleted = 0', [req.params.id]
    );
    if (existing.length === 0) return res.status(404).json({ error: 'Product not found' });

    // ✅ Chỉ owner hoặc admin mới được sửa
    if (existing[0].created_by !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to update this product' });
    }

    await pool.execute(
      'UPDATE products SET name=?, description=?, price=?, stock=?, category=?, updated_at=NOW() WHERE id=?',
      [name, description || null, price, stock, category, req.params.id]
    );

    logger.info(`[PRODUCTS] Updated id:${req.params.id} by user:${req.user.id}`);
    res.json({ message: 'Product updated' });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/products/:id — Soft delete
router.delete('/:id', idValidation, async (req, res, next) => {
  try {
    const [existing] = await pool.execute(
      'SELECT id, created_by FROM products WHERE id = ? AND is_deleted = 0', [req.params.id]
    );
    if (existing.length === 0) return res.status(404).json({ error: 'Product not found' });

    if (existing[0].created_by !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized to delete this product' });
    }

    // ✅ Soft delete — không xóa vĩnh viễn khỏi DB
    await pool.execute(
      'UPDATE products SET is_deleted = 1, deleted_at = NOW(), deleted_by = ? WHERE id = ?',
      [req.user.id, req.params.id]
    );

    logger.info(`[PRODUCTS] Soft-deleted id:${req.params.id} by user:${req.user.id}`);
    res.json({ message: 'Product deleted' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
