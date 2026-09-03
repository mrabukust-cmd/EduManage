const express = require('express');
const timetableController = require('./timetable.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', timetableController.getAll);
router.get('/:id', timetableController.getById);

router.post(
  '/',
  authorizeRoles('admin'),
  validate({ required: ['class', 'day', 'subject', 'startTime', 'endTime'] }),
  timetableController.create
);

router.put('/:id', authorizeRoles('admin'), timetableController.update);
router.delete('/:id', authorizeRoles('admin'), timetableController.remove);

module.exports = router;
