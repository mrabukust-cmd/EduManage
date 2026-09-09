const timetableService = require('./timetable.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const list = await timetableService.getAll(req.query);
  res.status(200).json({ success: true, count: list.length, data: list });
});

const getById = asyncHandler(async (req, res) => {
  const item = await timetableService.getById(req.params.id);
  res.status(200).json({ success: true, data: item });
});

const create = asyncHandler(async (req, res) => {
  const item = await timetableService.create(req.body);
  res.status(201).json({ success: true, message: 'Timetable entry added', data: item });
});

const update = asyncHandler(async (req, res) => {
  const item = await timetableService.update(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Timetable entry updated', data: item });
});

const remove = asyncHandler(async (req, res) => {
  await timetableService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Timetable entry removed' });
});

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
