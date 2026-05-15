class AppError extends Error {
  constructor(message, statusCode = 500, code) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

const errorHandler = (error, req, res, _next) => {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      error: { message: error.message, code: error.code || 'UNKNOWN_ERROR' }
    });
  }

  console.error('[ERROR]', req.method, req.originalUrl, error.message, error.stack);

  return res.status(500).json({
    success: false,
    error: { message: 'Internal server error', code: 'INTERNAL_SERVER_ERROR' }
  });
};

const notFoundHandler = (req, res) => {
  return res.status(404).json({
    success: false,
    error: { message: `Route ${req.method} ${req.originalUrl} not found`, code: 'ROUTE_NOT_FOUND' }
  });
};

module.exports = { AppError, errorHandler, notFoundHandler };
