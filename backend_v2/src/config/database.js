const sql = require('mssql');
require('dotenv').config();

const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true,
    trustServerCertificate: true,
    enableArithAbort: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

let poolPromise;

const getPool = async () => {
  try {
    if (!poolPromise) {
      poolPromise = sql.connect(dbConfig);
      const pool = await poolPromise;
      console.log('✅ Database connected successfully');
      return pool;
    }
    return poolPromise;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    poolPromise = null;
    throw error;
  }
};

const closePool = async () => {
  try {
    if (poolPromise) {
      await (await poolPromise).close();
      poolPromise = null;
      console.log('Database connection closed');
    }
  } catch (error) {
    console.error('Error closing database connection:', error.message);
  }
};

module.exports = {
  sql,
  getPool,
  closePool
};