const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');
const { applyFilterAndPagination } = require('../../middleware/query.middleware');

class ClassesService {
  async getAll(query = {}) {
    const classes = db.collection('classes').find();
    if (!query.sortBy) {
      classes.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }
    return applyFilterAndPagination(classes, query, ['name', 'classTeacher', 'room']);
  }

  async getById(id) {
    const cls = db.collection('classes').findById(id);
    if (!cls) throw new AppError('Class not found', 404);
    return cls;
  }

  async create({ name, capacity, teacherId, teacherName }) {
    const classesCol = db.collection('classes');
    const existing = classesCol.findOne(
      (c) => (c.name || '').trim().toLowerCase() === (name || '').trim().toLowerCase()
    );

    if (existing) {
      throw new AppError(`Class '${name}' already exists`, 400);
    }

    return classesCol.insert({
      name: name.trim(),
      capacity: capacity || 30,
      teacherId: teacherId || '',
      teacherName: teacherName || '',
    });
  }

  async update(id, updates) {
    const updated = db.collection('classes').update(id, updates);
    if (!updated) throw new AppError('Class not found', 404);
    return updated;
  }

  async delete(id) {
    const deleted = db.collection('classes').delete(id);
    if (!deleted) throw new AppError('Class not found', 404);
    return true;
  }
}

module.exports = new ClassesService();
