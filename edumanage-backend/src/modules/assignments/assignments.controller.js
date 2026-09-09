const assignmentsService = require('./assignments.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const assignments = await assignmentsService.getAll(req.query);
  res.status(200).json({ success: true, count: assignments.length, data: assignments });
});

const getById = asyncHandler(async (req, res) => {
  const assignment = await assignmentsService.getById(req.params.id);
  res.status(200).json({ success: true, data: assignment });
});

const create = asyncHandler(async (req, res) => {
  const data = {
    ...req.body,
    teacherId: req.user.id,
    teacherName: req.user.name,
  };
  const assignment = await assignmentsService.create(data);
  res.status(201).json({ success: true, message: 'Assignment created', data: assignment });
});

const update = asyncHandler(async (req, res) => {
  const assignment = await assignmentsService.update(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Assignment updated', data: assignment });
});

const remove = asyncHandler(async (req, res) => {
  await assignmentsService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Assignment deleted' });
});

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
