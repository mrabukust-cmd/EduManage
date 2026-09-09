const dashboardService = require('./dashboard.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const getAdminStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getAdminStats();
  res.status(200).json({ success: true, data: stats });
});

const getTeacherStats = asyncHandler(async (req, res) => {
  const teacherId = req.params.teacherId || req.user.id;
  const stats = await dashboardService.getTeacherStats(teacherId);
  res.status(200).json({ success: true, data: stats });
});

const getStudentStats = asyncHandler(async (req, res) => {
  const studentId = req.params.studentId || req.user.id;
  const stats = await dashboardService.getStudentStats(studentId);
  res.status(200).json({ success: true, data: stats });
});

module.exports = {
  getAdminStats,
  getTeacherStats,
  getStudentStats,
};
