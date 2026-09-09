const express = require('express');
const classesController = require('./classes.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', classesController.getAll);
router.get('/:id', classesController.getById);

router.post(
  '/',
  authorizeRoles('admin'),
  validate({ required: ['name'] }),
  classesController.create
);

router.put('/:id', authorizeRoles('admin'), classesController.update);
router.delete('/:id', authorizeRoles('admin'), classesController.remove);

module.exports = router;
