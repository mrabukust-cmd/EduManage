const attendanceService = require('./attendance.service');
const { asyncHandler } = require('../../middleware/error.middleware');

const markAttendance = asyncHandler(async (req, res) => {
  const result = await attendanceService.markAttendance(req.body);
  res.status(200).json({ success: true, message: 'Attendance marked', count: result.length, data: result });
});

const getByClassAndDate = asyncHandler(async (req, res) => {
  const className = req.query.className || req.query.class;
  const { date } = req.query;

  if (!className || !date) {
    return res.status(400).json({
      success: false,
      message: 'Both className (or class) and date query parameters are required',
    });
  }

  const records = await attendanceService.getByClassAndDate(className, date);
  res.status(200).json({ success: true, count: records.length, data: records });
});

const getStudentSummary = asyncHandler(async (req, res) => {
  const studentId = req.params.studentId || req.user.id;
  const summary = await attendanceService.getStudentSummary(studentId);
  res.status(200).json({ success: true, data: summary });
});

module.exports = {
  markAttendance,
  getByClassAndDate,
  getStudentSummary,
};
