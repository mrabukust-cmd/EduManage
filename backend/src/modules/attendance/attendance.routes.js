const express = require('express');
const attendanceController = require('./attendance.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.post(
  '/',
  authorizeRoles('admin', 'teacher'),
  attendanceController.markAttendance
);

router.get('/', attendanceController.getByClassAndDate);
router.get('/class', attendanceController.getByClassAndDate);
router.get('/student/:studentId?', attendanceController.getStudentSummary);

module.exports = router;
