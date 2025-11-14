const { sql, getPool } = require('../config/database');

class ProductModel {
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