const morgan = require('morgan');
const config = require('../config');

// Use short format in test/production, dev format in development
const logger = morgan(config.env === 'development' ? 'dev' : 'combined');

module.exports = logger;
