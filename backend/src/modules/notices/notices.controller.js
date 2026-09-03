const noticesService = require('./notices.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAll = asyncHandler(async (req, res) => {
  const notices = await noticesService.getAll(req.query);
  res.status(200).json({ success: true, count: notices.length, data: notices });
});

const getById = asyncHandler(async (req, res) => {
  const notice = await noticesService.getById(req.params.id);
  res.status(200).json({ success: true, data: notice });
});

const create = asyncHandler(async (req, res) => {
  const data = {
    ...req.body,
    authorId: req.user.id,
    authorName: req.user.name,
  };
  const notice = await noticesService.create(data);
  res.status(201).json({ success: true, message: 'Notice published', data: notice });
});

const remove = asyncHandler(async (req, res) => {
  await noticesService.delete(req.params.id);
  res.status(200).json({ success: true, message: 'Notice deleted' });
});

module.exports = {
  getAll,
  getById,
  create,
  remove,
};
