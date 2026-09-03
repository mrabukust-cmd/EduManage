const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class AssignmentsService {
  async getAll(query = {}) {
    let list = db.collection('assignments').find();

    if (query.class) {
      list = list.filter((a) => (a.class || a.className || '').toLowerCase() === query.class.toLowerCase());
    }

    if (query.teacherId) {
      list = list.filter((a) => a.teacherId === query.teacherId);
    }

    return list.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
  }

  async getById(id) {
    const assignment = db.collection('assignments').findById(id);
    if (!assignment) throw new AppError('Assignment not found', 404);
    return assignment;
  }

  async create(data) {
    return db.collection('assignments').insert({
      title: data.title,
      description: data.description || '',
      class: data.class || data.className || '',
      className: data.className || data.class || '',
      subject: data.subject || '',
      dueDate: data.dueDate,
      teacherId: data.teacherId,
      teacherName: data.teacherName || '',
      fileUrl: data.fileUrl || '',
      submissions: [],
    });
  }

  async update(id, updates) {
    const updated = db.collection('assignments').update(id, updates);
    if (!updated) throw new AppError('Assignment not found', 404);
    return updated;
  }

  async delete(id) {
    const deleted = db.collection('assignments').delete(id);
    if (!deleted) throw new AppError('Assignment not found', 404);
    return true;
  }
}

module.exports = new AssignmentsService();
