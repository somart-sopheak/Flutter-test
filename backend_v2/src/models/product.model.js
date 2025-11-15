// backend/src/models/product.model.js
const { sql, getPool } = require('../config/database');

class ProductModel {
  /**
   * Get paginated products with filtering and sorting
   */
  static async getPaginatedProducts({
    page = 1,
    limit = 5,
    searchTerm = '',
    sortBy = 'PRODUCTID',
    sortOrder = 'DESC',
    priceMin,
    priceMax,
    stockMin,
    stockMax,
    dateFrom,
    dateTo
  }) {
    try {
      const pool = await getPool();
      const request = pool.request();
      let query = 'FROM PRODUCTS WHERE 1=1';

      if (searchTerm) {
        query += ' AND PRODUCTNAME LIKE @searchTerm';
        request.input('searchTerm', sql.NVarChar, `%${searchTerm}%`);
      }
      if (priceMin != null) {
        query += ' AND PRICE >= @priceMin';
        request.input('priceMin', sql.Decimal(10, 2), priceMin);
      }
      if (priceMax != null) {
        query += ' AND PRICE <= @priceMax';
        request.input('priceMax', sql.Decimal(10, 2), priceMax);
      }
      if (stockMin != null) {
        query += ' AND STOCK >= @stockMin';
        request.input('stockMin', sql.Int, stockMin);
      }
      if (stockMax != null) {
        query += ' AND STOCK <= @stockMax';
        request.input('stockMax', sql.Int, stockMax);
      }
      if (dateFrom) {
        query += ' AND CREATED_AT >= @dateFrom';
        request.input('dateFrom', sql.DateTime, new Date(dateFrom));
      }
      if (dateTo) {
        query += ' AND CREATED_AT <= @dateTo';
        request.input('dateTo', sql.DateTime, new Date(dateTo));
      }

      // Sanitize sortBy
      const validSortColumns = ['PRODUCTID', 'PRODUCTNAME', 'PRICE', 'STOCK', 'CREATED_AT'];
      if (!validSortColumns.includes(sortBy.toUpperCase())) {
        sortBy = 'PRODUCTID';
      }
      
      // Sanitize sortOrder
      if (sortOrder.toUpperCase() !== 'ASC' && sortOrder.toUpperCase() !== 'DESC') {
        sortOrder = 'DESC';
      }

      const offset = (page - 1) * limit;
      request.input('offset', sql.Int, offset);
      request.input('limit', sql.Int, limit);

      const paginatedQuery = `
        SELECT * ${query}
        ORDER BY ${sortBy} ${sortOrder}
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
      `;

      const result = await request.query(paginatedQuery);
      return result.recordset;
    } catch (error) {
      throw new Error(`Error fetching paginated products: ${error.message}`);
    }
  }

  /**
   * Get total count of products for pagination (with filters)
   */
  static async getTotalProductCount({
    searchTerm = '',
    priceMin,
    priceMax,
    stockMin,
    stockMax,
    dateFrom,
    dateTo
  }) {
    try {
      const pool = await getPool();
      const request = pool.request();
      let query = 'SELECT COUNT(*) as total FROM PRODUCTS WHERE 1=1';

      if (searchTerm) {
        query += ' AND PRODUCTNAME LIKE @searchTerm';
        request.input('searchTerm', sql.NVarChar, `%${searchTerm}%`);
      }
      if (priceMin != null) {
        query += ' AND PRICE >= @priceMin';
        request.input('priceMin', sql.Decimal(10, 2), priceMin);
      }
      if (priceMax != null) {
        query += ' AND PRICE <= @priceMax';
        request.input('priceMax', sql.Decimal(10, 2), priceMax);
      }
      if (stockMin != null) {
        query += ' AND STOCK >= @stockMin';
        request.input('stockMin', sql.Int, stockMin);
      }
      if (stockMax != null) {
        query += ' AND STOCK <= @stockMax';
        request.input('stockMax', sql.Int, stockMax);
      }
      if (dateFrom) {
        query += ' AND CREATED_AT >= @dateFrom';
        request.input('dateFrom', sql.DateTime, new Date(dateFrom));
      }
      if (dateTo) {
        query += ' AND CREATED_AT <= @dateTo';
        request.input('dateTo', sql.DateTime, new Date(dateTo));
      }

      const result = await request.query(query);
      return result.recordset[0].total;
    } catch (error) {
      throw new Error(`Error getting product count: ${error.message}`);
    }
  }

  // ... (keep all other methods: getAllProducts, getProductById, createProduct, updateProduct, deleteProduct, etc.)
  // ... (getAllProducts is no longer used by the main list but good to keep)

  /**
   * Get all products
   * @returns {Promise<Array>} Array of products
   */
  static async getAllProducts() {
    try {
      const pool = await getPool();
      const result = await pool.request()
        .query('SELECT * FROM PRODUCTS ORDER BY PRODUCTID DESC');
      return result.recordset;
    } catch (error) {
      throw new Error(`Error fetching products: ${error.message}`);
    }
  }

  /**
   * Get product by ID
   * @param {number} id - Product ID
   * @returns {Promise<Object|null>} Product object or null
   */
  static async getProductById(id) {
    try {
      const pool = await getPool();
      const result = await pool.request()
        .input('id', sql.Int, id)
        .query('SELECT * FROM PRODUCTS WHERE PRODUCTID = @id');
      
      return result.recordset.length > 0 ? result.recordset[0] : null;
    } catch (error) {
      throw new Error(`Error fetching product: ${error.message}`);
    }
  }

  /**
   * Create new product
   * @param {Object} productData - Product data
   * @param {string} productData.name - Product name
   * @param {number} productData.price - Product price
   * @param {number} productData.stock - Product stock
   * @returns {Promise<Object>} Created product
   */
  static async createProduct({ name, price, stock }) {
    try {
      const pool = await getPool();
      const result = await pool.request()
        .input('name', sql.NVarChar(100), name)
        .input('price', sql.Decimal(10, 2), price)
        .input('stock', sql.Int, stock)
        .query(`
          INSERT INTO PRODUCTS (PRODUCTNAME, PRICE, STOCK)
          OUTPUT INSERTED.*
          VALUES (@name, @price, @stock)
        `);
      
      return result.recordset[0];
    } catch (error) {
      throw new Error(`Error creating product: ${error.message}`);
    }
  }

  /**
   * Update product by ID
   * @param {number} id - Product ID
   * @param {Object} productData - Product data
   * @param {string} productData.name - Product name
   * @param {number} productData.price - Product price
   * @param {number} productData.stock - Product stock
   * @returns {Promise<Object|null>} Updated product or null
   */
  static async updateProduct(id, { name, price, stock }) {
    try {
      const pool = await getPool();
      const result = await pool.request()
        .input('id', sql.Int, id)
        .input('name', sql.NVarChar(100), name)
        .input('price', sql.Decimal(10, 2), price)
        .input('stock', sql.Int, stock)
        .query(`
          UPDATE PRODUCTS
          SET PRODUCTNAME = @name, PRICE = @price, STOCK = @stock
          OUTPUT INSERTED.*
          WHERE PRODUCTID = @id
        `);
      
      return result.recordset.length > 0 ? result.recordset[0] : null;
    } catch (error) {
      throw new Error(`Error updating product: ${error.message}`);
    }
  }

  /**
   * Delete product by ID
   * @param {number} id - Product ID
   * @returns {Promise<Object|null>} Deleted product or null
   */
  static async deleteProduct(id) {
    try {
      const pool = await getPool();
      
      // First get the product
      const product = await this.getProductById(id);
      
      if (!product) {
        return null;
      }
      
      // Then delete it
      await pool.request()
        .input('id', sql.Int, id)
        .query('DELETE FROM PRODUCTS WHERE PRODUCTID = @id');
      
      return product;
    } catch (error) {
      throw new Error(`Error deleting product: ${error.message}`);
    }
  }

  /**
   * Check if product exists
   * @param {number} id - Product ID
   * @returns {Promise<boolean>} True if exists, false otherwise
   */
  static async productExists(id) {
    try {
      const product = await this.getProductById(id);
      return product !== null;
    } catch (error) {
      throw new Error(`Error checking product existence: ${error.message}`);
    }
  }

  /**
   * Search products by name
   * @param {string} searchTerm - Search term
   * @returns {Promise<Array>} Array of matching products
   */
  static async searchProducts(searchTerm) {
    try {
      const pool = await getPool();
      const result = await pool.request()
        .input('searchTerm', sql.NVarChar(100), `%${searchTerm}%`)
        .query('SELECT * FROM PRODUCTS WHERE PRODUCTNAME LIKE @searchTerm ORDER BY PRODUCTID DESC');
      
      return result.recordset;
    } catch (error) {
      throw new Error(`Error searching products: ${error.message}`);
    }
  }
}

module.exports = ProductModel;