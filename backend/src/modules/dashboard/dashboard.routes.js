const express = require('express');
const dashboardController = require('./dashboard.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/admin', authorizeRoles('admin'), dashboardController.getAdminStats);
router.get('/teacher/:teacherId?', authorizeRoles('admin', 'teacher'), dashboardController.getTeacherStats);
router.get('/student/:studentId?', dashboardController.getStudentStats);

module.exports = router;
