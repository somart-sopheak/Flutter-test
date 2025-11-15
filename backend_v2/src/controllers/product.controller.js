// backend/src/controllers/product.controller.js
const ProductModel = require('../models/product.model');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');

class ProductController {
  /**
   * Get all products (paginated) or product by ID
   * GET /products
   * GET /products?id=1
   * GET /products?page=1&limit=10&q=...&sortBy=...
   */
static async getProducts(req, res, next) {
  try {
    const id = req.query.id || req.params.id;

    // ----------------------------
    // 🔹 GET PRODUCT BY ID
    // ----------------------------
    if (id) {
      const product = await ProductModel.getProductById(parseInt(id));
      if (!product) {
        return errorResponse(res, 'Product not found', 404);
      }
      return successResponse(res, product, 'Product retrieved successfully');
    }

    // ----------------------------
    // 🔹 PAGINATION & FILTER LOGIC
    // ----------------------------
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const all = parseInt(req.query.all);   // <-- important
    
    // Filters
    const searchTerm = req.query.q || '';
    const { 
      priceMin, priceMax, 
      stockMin, stockMax, 
      dateFrom, dateTo 
    } = req.query;

    // Sorting
    let sortBy = req.query.sortBy || 'PRODUCTID';
    const sortOrder = req.query.sortOrder || 'DESC';

    // Map frontend key to database column
    if (sortBy === 'price') sortBy = 'PRICE';
    if (sortBy === 'stock') sortBy = 'STOCK';

    const filters = {
      searchTerm,
      priceMin: priceMin ? parseFloat(priceMin) : null,
      priceMax: priceMax ? parseFloat(priceMax) : null,
      stockMin: stockMin ? parseInt(stockMin) : null,
      stockMax: stockMax ? parseInt(stockMax) : null,
      dateFrom: dateFrom || null,
      dateTo: dateTo || null
    };

    // ----------------------------
    // 🔹 GET ALL PRODUCTS (no pagination)
    // ----------------------------
    if (all === 1) {
      const products = await ProductModel.getAllProducts({
        ...filters,
        sortBy,
        sortOrder
      });

      return successResponse(
        res,
        products,
        'All products retrieved successfully'
      );
    }

    // ----------------------------
    // 🔹 PAGINATED PRODUCTS
    // ----------------------------
    const products = await ProductModel.getPaginatedProducts({
      page,
      limit,
      ...filters,
      sortBy,
      sortOrder
    });

    const total = await ProductModel.getTotalProductCount(filters);

    return paginatedResponse(
      res,
      products,
      page,
      limit,
      total,
      false,
      'Products retrieved successfully'
    );

  } catch (error) {
    next(error);
  }
}


  // ... (keep all other methods: createProduct, updateProduct, deleteProduct, searchProducts)
  // ... (the searchProducts controller is now mostly handled by getProducts, but we can leave it)

  /**
   * Create new product
   * POST /products
   */
  static async createProduct(req, res, next) {
    try {
      // FIX: Changed from uppercase to lowercase
      const { name, price, stock } = req.body;

      // Validation is handled by middleware, so data is clean here
      const productData = {
        // FIX: Changed from uppercase to lowercase
        name: name.trim(),
        price: parseFloat(price),
        stock: parseInt(stock)
      };

      const newProduct = await ProductModel.createProduct(productData);
      
      return successResponse(
        res, 
        newProduct, 
        'Product created successfully',
        null,
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update product by ID
   * PUT /products/:id
   */
  static async updateProduct(req, res, next) {
    try {
      // FIX: Read id from req.params
      const { id } = req.params;
      // FIX: Changed from uppercase to lowercase
      const { name, price, stock } = req.body;

      if (!id) {
        return errorResponse(res, 'Product ID is required', 400);
      }

      // Check if product exists
      const exists = await ProductModel.productExists(parseInt(id));
      if (!exists) {
        return errorResponse(res, 'Product not found', 404);
      }

      // Validation is handled by middleware
      const productData = {
        // FIX: Changed from uppercase to lowercase
        name: name.trim(),
        price: parseFloat(price),
        stock: parseInt(stock)
      };

      const updatedProduct = await ProductModel.updateProduct(
        parseInt(id),
        productData
      );
      
      return successResponse(
        res, 
        updatedProduct, 
        'Product updated successfully'
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete product by ID
   * DELETE /products/:id
   */
  static async deleteProduct(req, res, next) {
    try {
      // FIX: Read id from req.params
      const { id } = req.params;

      if (!id) {
        return errorResponse(res, 'Product ID is required', 400);
      }

      const deletedProduct = await ProductModel.deleteProduct(parseInt(id));
      
      if (!deletedProduct) {
        return errorResponse(res, 'Product not found', 404);
      }
      
      return successResponse(
        res, 
        deletedProduct, 
        'Product deleted successfully'
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Search products by name
   * GET /products/search?q=searchTerm
   */
  static async searchProducts(req, res, next) {
    try {
      const { q } = req.query;

      if (!q || q.trim() === '') {
        return errorResponse(res, 'Search term is required', 400);
      }

      const products = await ProductModel.searchProducts(q.trim());
      
      return successResponse(
        res, 
        products, 
        'Search completed successfully',
        { count: products.length, searchTerm: q }
      );
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ProductController;