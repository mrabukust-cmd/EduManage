const jwt = require('jsonwebtoken');
const config = require('../config');
const { AppError } = require('./error.middleware');

const authenticate = (req, res, next) => {
  let token = null;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer ')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('Authentication required. Please log in.', 401));
  }

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    req.user = decoded; // { id, email, role, name, ... }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new AppError('Your token has expired. Please log in again.', 401));
    }
    return next(new AppError('Invalid authentication token.', 401));
  }
};

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return next(new AppError('User role not found.', 403));
    }

    if (!roles.includes(req.user.role)) {
      return next(
        new AppError(
          `Access denied. Role '${req.user.role}' is not authorized for this action.`,
          403
        )
      );
    }

    next();
  };
};

module.exports = {
  authenticate,
  authorizeRoles,
};
