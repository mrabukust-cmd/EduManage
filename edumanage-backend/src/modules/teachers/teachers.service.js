const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');
const { applyFilterAndPagination } = require('../../middleware/query.middleware');

class TeachersService {
  async getAll(query = {}) {
    const teachersCol = db.collection('teachers');
    let teachers = teachersCol.find();

    if (query.approved !== undefined) {
      const isApproved = query.approved === 'true' || query.approved === true;
      teachers = teachers.filter((t) => t.approved === isApproved);
    }

    if (!query.sortBy) {
      teachers.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }

    return applyFilterAndPagination(teachers, query, ['name', 'email', 'phone', 'subject', 'qualification']);
  }

  async getById(id) {
    const teacher = db.collection('teachers').findById(id);
    if (!teacher) throw new AppError('Teacher not found', 404);
    return teacher;
  }

  async create(data) {
    const teachersCol = db.collection('teachers');
    const existing = teachersCol.findOne((t) => t.email && t.email.toLowerCase() === data.email.toLowerCase());

    if (existing) {
      throw new AppError('Teacher with this email already exists', 400);
    }

    return teachersCol.insert({
      name: data.name,
      email: (data.email || '').toLowerCase(),
      phone: data.phone || '',
      subject: data.subject || '',
      qualification: data.qualification || '',
      classes: data.classes || [],
      approved: data.approved !== undefined ? data.approved : true,
    });
  }

  async update(id, updates) {
    const updated = db.collection('teachers').update(id, updates);
    if (!updated) throw new AppError('Teacher not found', 404);

    // Sync approved status to users table if present
    if (updates.approved !== undefined) {
      db.collection('users').update(id, { approved: updates.approved });
    }

    return updated;
  }

  async delete(id) {
    const deleted = db.collection('teachers').delete(id);
    if (!deleted) throw new AppError('Teacher not found', 404);
    return true;
  }
}

module.exports = new TeachersService();
