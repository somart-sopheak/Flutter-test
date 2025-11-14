const express = require('express');
const router = express.Router();
const ProductController = require('../controllers/product.controller');
const { 
  validateProduct, 
  validateId, 
  sanitizeInput, 
  validateBody 
} = require('../middlewares/validator');

/**
 * @route   GET /api/products
 * @desc    Get all products or get product by ID (with ?id= query param)
 * @access  Public
 */
router.get('/', ProductController.getProducts);

/**
 * @route   GET /api/products/search
 * @desc    Search products by name
 * @access  Public
 */
router.get('/search', ProductController.searchProducts);

/**
 * @route   POST /api/products
 * @desc    Create a new product
 * @access  Public
 */
router.post(
  '/',
  validateBody,
  sanitizeInput,
  validateProduct,
  ProductController.createProduct
);

/**
 * @route   PUT /api/products/:id
 * @desc    Update product by ID
 * @access  Public
 */
router.put(
  '/:id', // FIX: Changed from '/' to '/:id'
  validateBody,
  sanitizeInput,
  validateProduct,
  ProductController.updateProduct
);

/**
 * @route   DELETE /api/products/:id
 * @desc    Delete product by ID
 * @access  Public
 */
router.delete(
  '/:id', // FIX: Changed from '/' to '/:id'
  ProductController.deleteProduct
);

module.exports = router;