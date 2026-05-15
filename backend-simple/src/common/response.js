const sendSuccess = (res, data, statusCode = 200) => {
  return res.status(statusCode).json({ success: true, data });
};

const sendError = (res, statusCode, message, code) => {
  return res.status(statusCode).json({
    success: false,
    error: { message, code: code || 'UNKNOWN_ERROR' }
  });
};

module.exports = { sendSuccess, sendError };
