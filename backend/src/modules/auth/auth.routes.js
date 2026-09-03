const express = require('express');
const authController = require('./auth.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.post(
  '/register',
  validate({ required: ['name', 'email', 'password'] }),
  authController.register
);

router.post(
  '/login',
  validate({ required: ['email', 'password'] }),
  authController.login
);

router.get('/me', authenticate, authController.getMe);

module.exports = router;
