const express = require('express');
const teachersController = require('./teachers.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', teachersController.getAll);
router.get('/:id', teachersController.getById);

router.post(
  '/',
  authorizeRoles('admin'),
  validate({ required: ['name', 'email'] }),
  teachersController.create
);

router.put('/:id', authorizeRoles('admin'), teachersController.update);
router.delete('/:id', authorizeRoles('admin'), teachersController.remove);

module.exports = router;
