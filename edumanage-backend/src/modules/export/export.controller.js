const studentsService = require('../students/students.service');
const feesService = require('../fees/fees.service');
const { asyncHandler } = require('../../middleware/error.middleware');

function escapeCsvCell(val) {
  if (val == null) return '""';
  let str = String(val);
  if (/^[=+\-@\t\r]/.test(str)) {
    str = "'" + str;
  }
  if (str.includes(',') || str.includes('"') || str.includes('\n') || str.includes('\r')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return `"${str}"`;
}

function generateCsv(headers, rows) {
  const lines = [headers.map(escapeCsvCell).join(',')];
  for (const row of rows) {
    lines.push(row.map(escapeCsvCell).join(','));
  }
  return lines.join('\n');
}

const exportStudents = asyncHandler(async (req, res) => {
  const result = await studentsService.getAll(req.query);
  const students = Array.isArray(result) ? result : (result.items || []);

  const headers = ['Roll Number', 'Name', 'Class', 'Email', 'Phone', 'Parent Name', 'Parent Contact'];
  const rows = students.map(s => [
    s.rollNo || '',
    s.name || '',
    s.class || s.className || '',
    s.email || '',
    s.phone || '',
    s.parentName || '',
    s.parentPhone || '',
  ]);

  const csv = generateCsv(headers, rows);

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="students_export.csv"');
  res.status(200).send(csv);
});

const exportFees = asyncHandler(async (req, res) => {
  const fees = await feesService.getAll(req.query);

  const headers = ['Fee ID', 'Student Name', 'Class', 'Amount', 'Due Date', 'Status', 'Paid At'];
  const rows = fees.map(f => [
    f.id || '',
    f.studentName || '',
    f.class || f.className || '',
    Number(f.amount || 0).toFixed(2),
    f.dueDate || '',
    (f.status || '').toUpperCase(),
    f.paidAt || 'N/A',
  ]);

  const csv = generateCsv(headers, rows);

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="fees_export.csv"');
  res.status(200).send(csv);
});

module.exports = {
  exportStudents,
  exportFees,
};
