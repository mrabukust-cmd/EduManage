const express = require('express');
const exportController = require('./export.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(authenticate);
router.use(authorizeRoles('admin', 'teacher'));

router.get('/students', exportController.exportStudents);
router.get('/fees', exportController.exportFees);

module.exports = router;
