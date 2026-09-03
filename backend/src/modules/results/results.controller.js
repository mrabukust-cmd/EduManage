const resultsService = require('./results.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const list = await resultsService.getAll(req.query);
  res.status(200).json({ success: true, count: list.length, data: list });
});

const getById = asyncHandler(async (req, res) => {
  const item = await resultsService.getById(req.params.id);
  res.status(200).json({ success: true, data: item });
});

const create = asyncHandler(async (req, res) => {
  const item = await resultsService.create(req.body);
  res.status(201).json({ success: true, message: 'Result recorded', data: item });
});

const remove = asyncHandler(async (req, res) => {
  await resultsService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Result deleted' });
});

module.exports = {
  getAll,
  getById,
  create,
  remove,
};
