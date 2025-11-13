// Centralized error handler to keep responses consistent
function errorHandler(err, req, res, next) {
  console.error(err); // Log for debugging during development
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    message: err.message || "Internal server error",
    details: err.details || null,
  });
}

module.exports = errorHandler;
