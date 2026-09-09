const studentsService = require('./students.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const result = await studentsService.getAll(req.query);
  const students = result.items || result;
  res.status(200).json({
    success: true,
    count: students.length,
    pagination: result.pagination,
    data: students,
  });
});

const getById = asyncHandler(async (req, res) => {
  const student = await studentsService.getById(req.params.id);
  res.status(200).json({ success: true, data: student });
});

const getParentChildren = asyncHandler(async (req, res) => {
  const parentId = req.params.parentId || req.user.id;
  const children = await studentsService.getParentChildren(parentId);
  res.status(200).json({ success: true, count: children.length, data: children });
});

const create = asyncHandler(async (req, res) => {
  const student = await studentsService.create(req.body);
  res.status(201).json({ success: true, message: 'Student registered', data: student });
});

const update = asyncHandler(async (req, res) => {
  const student = await studentsService.update(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Student updated', data: student });
});

const remove = asyncHandler(async (req, res) => {
  await studentsService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Student deleted' });
});

module.exports = {
  getAll,
  getById,
  getParentChildren,
  create,
  update,
  remove,
};
