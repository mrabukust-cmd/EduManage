const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class TimetableService {
  async getAll(query = {}) {
    let list = db.collection('timetable').find();

    if (query.class) {
      list = list.filter((t) => (t.className || t.class || '').toLowerCase() === query.class.toLowerCase());
    }

    if (query.day) {
      list = list.filter((t) => (t.day || '').toLowerCase() === query.day.toLowerCase());
    }

    if (query.teacherId) {
      list = list.filter((t) => t.teacherId === query.teacherId);
    }

    return list.sort((a, b) => (a.startTime || '').localeCompare(b.startTime || ''));
  }

  async getById(id) {
    const item = db.collection('timetable').findById(id);
    if (!item) throw new AppError('Timetable slot not found', 404);
    return item;
  }

  async create(data) {
    return db.collection('timetable').insert({
      className: data.className || data.class,
      class: data.class || data.className,
      day: data.day,
      subject: data.subject,
      startTime: data.startTime,
      endTime: data.endTime,
      teacherId: data.teacherId || '',
      teacherName: data.teacherName || '',
      room: data.room || '',
    });
  }

  async update(id, updates) {
    const updated = db.collection('timetable').update(id, updates);
    if (!updated) throw new AppError('Timetable slot not found', 404);
    return updated;
  }

  async delete(id) {
    const deleted = db.collection('timetable').delete(id);
    if (!deleted) throw new AppError('Timetable slot not found', 404);
    return true;
  }
}

module.exports = new TimetableService();
