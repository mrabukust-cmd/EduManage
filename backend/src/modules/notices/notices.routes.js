const express = require('express');
const noticesController = require('./notices.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', noticesController.getAll);
router.get('/:id', noticesController.getById);

router.post(
  '/',
  authorizeRoles('admin', 'teacher'),
  validate({ required: ['title'] }),
  noticesController.create
);

router.delete('/:id', authorizeRoles('admin'), noticesController.remove);

module.exports = router;
