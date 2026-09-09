const express = require('express');
const feesController = require('./fees.controller');
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const validate = require('../../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', feesController.getAll);
router.get('/statistics', authorizeRoles('admin'), feesController.getStatistics);
router.get('/:id', feesController.getById);

router.post(
  '/',
  authorizeRoles('admin'),
  validate({ required: ['studentId', 'amount', 'dueDate'] }),
  feesController.create
);

router.post(
  '/:id/pay',
  authorizeRoles('admin', 'parent', 'student'),
  validate({ required: ['transactionId'] }),
  feesController.submitPaymentProof
);

router.put(
  '/:id/verify',
  authorizeRoles('admin'),
  validate({ required: ['verified'] }),
  feesController.verifyPayment
);

module.exports = router;
