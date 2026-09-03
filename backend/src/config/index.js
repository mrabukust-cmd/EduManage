const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env if present
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '5000', 10),
  jwt: {
    secret: process.env.JWT_SECRET || 'edumanage_dev_jwt_secret_key_2026',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
  apiPrefix: '/api/v1',
};

module.exports = config;
