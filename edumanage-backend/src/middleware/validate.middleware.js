const { AppError } = require('./error.middleware');

/**
 * Validates request body, query, or params against defined required fields or schema.
 * @param {Object} schema - Object with optional required: [], types: {}
 * @param {'body' | 'query' | 'params'} source
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const data = req[source] || {};
    const errors = [];

    if (schema.required && Array.isArray(schema.required)) {
      for (const field of schema.required) {
        if (data[field] === undefined || data[field] === null || data[field] === '') {
          errors.push({ field, message: `${field} is required` });
        }
      }
    }

    if (schema.types && typeof schema.types === 'object') {
      for (const [field, type] of Object.entries(schema.types)) {
        if (data[field] !== undefined && typeof data[field] !== type) {
          errors.push({ field, message: `${field} must be of type ${type}` });
        }
      }
    }

    if (errors.length > 0) {
      return next(new AppError('Validation failed', 400, errors));
    }

    next();
  };
};

module.exports = validate;
