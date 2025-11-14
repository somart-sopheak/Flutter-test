const ProductModel = require('../models/product.model');
const { successResponse, errorResponse } = require('../utils/response');

class ProductController {
  /**
   * Get all products or product by ID
   * GET /products or GET /products?id=1
   */
  static async getProducts(req, res, next) {
    try {
      // FIX: Check both query and params for robustness
      const id = req.query.id || req.params.id;

      if (id) {
        // Get single product by ID
        const product = await ProductModel.getProductById(parseInt(id));
        
        if (!product) {
          return errorResponse(res, 'Product not found', 404);
        }
        
        return successResponse(res, product, 'Product retrieved successfully');
      } else {
        // Get all products
        const products = await ProductModel.getAllProducts();
        
        return successResponse(
          res, 
          products, 
          'Products retrieved successfully',
          { count: products.length }
        );
      }
    } catch (error) {
      next(error);
    }
  }

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