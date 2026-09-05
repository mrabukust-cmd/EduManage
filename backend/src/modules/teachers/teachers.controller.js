const teachersService = require('./teachers.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const result = await teachersService.getAll(req.query);
  const teachers = result.items || result;
  res.status(200).json({
    success: true,
    count: teachers.length,
    pagination: result.pagination,
    data: teachers,
  });
});

const getById = asyncHandler(async (req, res) => {
  const teacher = await teachersService.getById(req.params.id);
  res.status(200).json({ success: true, data: teacher });
});

const create = asyncHandler(async (req, res) => {
  const teacher = await teachersService.create(req.body);
  res.status(201).json({ success: true, message: 'Teacher created', data: teacher });
});

const update = asyncHandler(async (req, res) => {
  const teacher = await teachersService.update(req.params.id, req.body);
  res.status(200).json({ success: true, message: 'Teacher updated', data: teacher });
});

const remove = asyncHandler(async (req, res) => {
  await teachersService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Teacher deleted' });
});

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
