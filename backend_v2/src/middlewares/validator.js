const { errorResponse } = require('../utils/response');

/**
 * Validate product data
 */
const validateProduct = (req, res, next) => {
  // FIX: Changed from uppercase to lowercase
  const { name, price, stock } = req.body;
  const errors = [];

  // Validate product name
  // FIX: Changed from PRODUCTNAME to name
  if (!name || typeof name !== 'string' || name.trim() === '') {
    errors.push('Product name is required and cannot be empty');
  // FIX: Changed from PRODUCTNAME to name
  } else if (name.trim().length > 100) {
    errors.push('Product name cannot exceed 100 characters');
  }

  // Validate price
  // FIX: Changed from PRICE to price
  if (price === undefined || price === null || price === '') {
    errors.push('Price is required');
  } else {
    // FIX: Changed from PRICE to price
    const priceValue = parseFloat(price);
    if (isNaN(priceValue)) {
      errors.push('Price must be a valid number');
    } else if (priceValue < 0) {
      errors.push('Price must be a positive number');
    } else if (priceValue > 99999999.99) {
      errors.push('Price cannot exceed 99999999.99');
    }
  }

  // Validate stock
  // FIX: Changed from STOCK to stock
  if (stock === undefined || stock === null || stock === '') {
    errors.push('Stock is required');
  } else {
    // FIX: Changed from STOCK to stock
    const stockValue = parseInt(stock);
    // FIX: Changed from STOCK to stock
    if (isNaN(stockValue) || !Number.isInteger(Number(stock))) {
      errors.push('Stock must be a valid integer');
    } else if (stockValue < 0) {
      errors.push('Stock must be a positive integer');
    } else if (stockValue > 2147483647) {
      errors.push('Stock value is too large');
    }
  }

  // If there are validation errors, return them
  if (errors.length > 0) {
    return errorResponse(res, 'Validation failed', 400, errors);
  }

  // Validation passed, proceed to next middleware
  next();
};

/**
 * Validate ID parameter
 */
const validateId = (req, res, next) => {
  const { id } = req.query;

  if (!id) {
    return errorResponse(res, 'ID parameter is required', 400);
  }

  const idValue = parseInt(id);
  if (isNaN(idValue) || idValue <= 0) {
    return errorResponse(res, 'ID must be a positive integer', 400);
  }

  next();
};

/**
 * Sanitize input to prevent SQL injection (additional layer)
 */
const sanitizeInput = (req, res, next) => {
  // FIX: Changed from PRODUCTNAME to name
  if (req.body.name) {
    // Remove any potentially dangerous characters
    // FIX: Changed from PRODUCTNAME to name
    req.body.name = req.body.name
      .replace(/[<>]/g, '') // Remove angle brackets
      .trim();
  }
  next();
};

/**
 * Validate request body exists
 */
const validateBody = (req, res, next) => {
  if (!req.body || Object.keys(req.body).length === 0) {
    return errorResponse(res, 'Request body is required', 400);
  }
  next();
};

module.exports = {
  validateProduct,
  validateId,
  sanitizeInput,
  validateBody
};