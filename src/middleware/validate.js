const { body, param, validationResult } = require('express-validator');

// Middleware kiểm tra kết quả validation
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }
  next();
};

// ✅ Input validation rules cho sản phẩm
const productValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Product name is required')
    .isLength({ min: 2, max: 200 }).withMessage('Name must be 2–200 characters')
    .escape(), // ✅ chống XSS

  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 }).withMessage('Description max 1000 characters')
    .escape(),

  body('price')
    .notEmpty().withMessage('Price is required')
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),

  body('stock')
    .notEmpty().withMessage('Stock is required')
    .isInt({ min: 0 }).withMessage('Stock must be a non-negative integer'),

  body('category')
    .trim()
    .notEmpty().withMessage('Category is required')
    .isLength({ max: 100 })
    .escape(),

  validate,
];

const loginValidation = [
  body('username')
    .trim()
    .notEmpty().withMessage('Username is required')
    .isLength({ max: 50 })
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username: alphanumeric and underscore only'),

  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 8, max: 128 }).withMessage('Password must be 8–128 characters'),

  validate,
];

const idValidation = [
  param('id').isInt({ min: 1 }).withMessage('Invalid ID'),
  validate,
];

module.exports = { productValidation, loginValidation, idValidation };
