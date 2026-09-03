const express = require('express');
const assignmentsController = require('./assignments.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', assignmentsController.getAll);
router.get('/:id', assignmentsController.getById);

router.post(
  '/',
  authorizeRoles('admin', 'teacher'),
  validate({ required: ['title', 'class', 'dueDate'] }),
  assignmentsController.create
);

router.put('/:id', authorizeRoles('admin', 'teacher'), assignmentsController.update);
router.delete('/:id', authorizeRoles('admin', 'teacher'), assignmentsController.remove);

module.exports = router;
