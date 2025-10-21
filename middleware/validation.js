const { validationResult } = require('express-validator');

// Validation middleware
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    console.log('=== VALIDATION ERRORS ===');
    console.log('URL:', req.url);
    console.log('Method:', req.method);
    console.log('Body:', JSON.stringify(req.body, null, 2));
    console.log('Errors:', errors.array());
    console.log('========================');
    
    return res.status(400).json({
      message: 'Validation failed',
      errors: errors.array().map(error => ({
        field: error.param,
        message: error.msg,
        value: error.value
      }))
    });
  }
  
  next();
};

// Async error handler
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Not found middleware
const notFound = (req, res, next) => {
  const error = new Error(`Not found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  console.error(err);

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = { message, statusCode: 404 };
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const fields = Object.keys(err.keyValue || {});
    const message = 'Duplicate field value entered';
    const errors = fields.map((field) => ({
      field,
      message: `${field} already exists`,
      value: err.keyValue[field]
    }));
    error = { message, statusCode: 400, ...(errors.length ? { errors } : {}) };
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const details = Object.values(err.errors || {});
    const message = details.map(val => val.message).join(', ');
    const errors = details.map((val) => ({
      field: val.path || val.properties?.path,
      message: val.message,
      value: val.value
    }));
    error = { message, statusCode: 400, ...(errors.length ? { errors } : {}) };
  }

  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || 'Server Error',
    ...(error.errors ? { errors: error.errors } : {}),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = {
  validate,
  asyncHandler,
  notFound,
  errorHandler
};
