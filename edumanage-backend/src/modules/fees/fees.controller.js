const feesService = require('./fees.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const fees = await feesService.getAll(req.query);
  res.status(200).json({ success: true, count: fees.length, data: fees });
});

const getById = asyncHandler(async (req, res) => {
  const fee = await feesService.getById(req.params.id);
  res.status(200).json({ success: true, data: fee });
});

const create = asyncHandler(async (req, res) => {
  const fee = await feesService.create(req.body);
  res.status(201).json({ success: true, message: 'Fee invoice generated', data: fee });
});

const submitPaymentProof = asyncHandler(async (req, res) => {
  const fee = await feesService.submitPaymentProof(req.params.id, {
    ...req.body,
    submittedBy: req.user.id,
  });
  res.status(200).json({ success: true, message: 'Payment proof submitted', data: fee });
});

const verifyPayment = asyncHandler(async (req, res) => {
  const fee = await feesService.verifyPayment(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Payment verification recorded', data: fee });
});

const getStatistics = asyncHandler(async (req, res) => {
  const stats = await feesService.getStatistics();
  res.status(200).json({ success: true, data: stats });
});

module.exports = {
  getAll,
  getById,
  create,
  submitPaymentProof,
  verifyPayment,
  getStatistics,
};
