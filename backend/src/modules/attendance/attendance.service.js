const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class AttendanceService {
  async markAttendance(payload = {}) {
    const className = payload.className || payload.class;
    const { date, records } = payload;

    if (!className || !date || !Array.isArray(records)) {
      throw new AppError('className (or class), date, and records array are required', 400);
    }

    if (records.length === 0) {
      throw new AppError('records array cannot be empty', 400);
    }

    const validStatuses = ['present', 'absent', 'leave'];
    for (const record of records) {
      if (!record.studentId) {
        throw new AppError('studentId is required for each attendance record', 400);
      }
      if (record.status && !validStatuses.includes(record.status)) {
        throw new AppError(`Invalid status '${record.status}'. Allowed values: ${validStatuses.join(', ')}`, 400);
      }
    }

    const attendanceCol = db.collection('attendance');
    const results = [];

    for (const record of records) {
      // Check if attendance already exists for this student on this date
      const existing = attendanceCol.findOne(
        (a) => a.studentId === record.studentId && a.date === date
      );

      if (existing) {
        const updated = attendanceCol.update(existing.id, {
          status: record.status || 'present',
          className,
          studentName: record.studentName || existing.studentName,
          rollNo: record.rollNo || existing.rollNo,
          date,
        });
        results.push(updated);
      } else {
        const created = attendanceCol.insert({
          studentId: record.studentId,
          studentName: record.studentName || '',
          rollNo: record.rollNo || '',
          className,
          date,
          status: record.status || 'present',
        });
        results.push(created);
      }
    }

    return results;
  }

  async getByClassAndDate(className, date) {
    const attendance = db.collection('attendance').find(
      (a) => (a.className || '').toLowerCase() === (className || '').toLowerCase() && a.date === date
    );
    return attendance;
  }

  async getStudentSummary(studentId) {
    const records = db.collection('attendance').find((a) => a.studentId === studentId);
    const total = records.length;
    const present = records.filter((r) => r.status === 'present').length;
    const absent = records.filter((r) => r.status === 'absent').length;
    const leave = records.filter((r) => r.status === 'leave').length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;

    return {
      studentId,
      total,
      present,
      absent,
      leave,
      percentage,
      records: records.sort((a, b) => (b.date || '').localeCompare(a.date || '')),
    };
  }
}

module.exports = new AttendanceService();
