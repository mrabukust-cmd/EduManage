const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class ResultsService {
  async getAll(query = {}) {
    let list = db.collection('results').find();

    if (query.studentId) {
      list = list.filter((r) => r.studentId === query.studentId);
    }

    if (query.class) {
      list = list.filter((r) => (r.className || r.class || '').toLowerCase() === query.class.toLowerCase());
    }

    if (query.examName) {
      list = list.filter((r) => (r.examName || '').toLowerCase() === query.examName.toLowerCase());
    }

    return list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
  }

  async getById(id) {
    const item = db.collection('results').findById(id);
    if (!item) throw new AppError('Result record not found', 404);
    return item;
  }

  async create(data) {
    const marksObtained = parseFloat(data.marksObtained || 0);
    const totalMarks = parseFloat(data.totalMarks || 100);
    const percentage = totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0;

    let grade = 'F';
    if (percentage >= 90) grade = 'A+';
    else if (percentage >= 80) grade = 'A';
    else if (percentage >= 70) grade = 'B';
    else if (percentage >= 60) grade = 'C';
    else if (percentage >= 50) grade = 'D';

    return db.collection('results').insert({
      studentId: data.studentId,
      studentName: data.studentName || '',
      className: data.className || data.class || '',
      class: data.class || data.className || '',
      examName: data.examName || 'Midterm Exam',
      subject: data.subject || '',
      marksObtained,
      totalMarks,
      percentage: Math.round(percentage * 10) / 10,
      grade,
      remarks: data.remarks || '',
    });
  }

  async delete(id) {
    const deleted = db.collection('results').delete(id);
    if (!deleted) throw new AppError('Result record not found', 404);
    return true;
  }
}

module.exports = new ResultsService();
