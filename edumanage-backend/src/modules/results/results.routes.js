const express = require('express');
const resultsController = require('./results.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', resultsController.getAll);
router.get('/:id', resultsController.getById);

router.post(
  '/',
  authorizeRoles('admin', 'teacher'),
  validate({ required: ['studentId', 'subject', 'marksObtained', 'totalMarks'] }),
  resultsController.create
);

router.delete('/:id', authorizeRoles('admin'), resultsController.remove);

module.exports = router;
