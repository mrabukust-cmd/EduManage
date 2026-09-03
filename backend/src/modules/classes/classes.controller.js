const classesService = require('./classes.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const classes = await classesService.getAll();
  res.status(200).json({ success: true, count: classes.length, data: classes });
});

const getById = asyncHandler(async (req, res) => {
  const cls = await classesService.getById(req.params.id);
  res.status(200).json({ success: true, data: cls });
});

const create = asyncHandler(async (req, res) => {
  const cls = await classesService.create(req.body);
  res.status(201).json({ success: true, message: 'Class created', data: cls });
});

const update = asyncHandler(async (req, res) => {
  const cls = await classesService.update(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Class updated', data: cls });
});

const remove = asyncHandler(async (req, res) => {
  await classesService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Class deleted' });
});

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
