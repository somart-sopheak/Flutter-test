const { errorResponse } = require('../utils/response');

/**
 * Global error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    timestamp: new Date().toISOString()
  });

  // Database connection errors
  if (err.message.includes('connection') || err.message.includes('ECONNREFUSED')) {
    return errorResponse(
      res, 
      'Database connection error. Please try again later.',
      503,
      process.env.NODE_ENV === 'development' ? [err.message] : null
    );
  }

  // SQL Server specific errors
  if (err.code === 'EREQUEST') {
    return errorResponse(
      res,
      'Database query error',
      500,
      process.env.NODE_ENV === 'development' ? [err.message] : null
    );
  }

  // Validation errors
  if (err.name === 'ValidationError') {
    return errorResponse(res, err.message, 400);
  }

  // Default error response
  return errorResponse(
    res,
    'Internal server error',
    500,
    process.env.NODE_ENV === 'development' ? [err.message] : null
  );
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res) => {
  return errorResponse(
    res,
    `Route not found: ${req.method} ${req.url}`,
    404
  );
};

module.exports = {
  errorHandler,
  notFoundHandler
};