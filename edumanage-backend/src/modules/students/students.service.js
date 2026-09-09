const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');
const { applyFilterAndPagination } = require('../../middleware/query.middleware');

class StudentsService {
  async getAll(query = {}) {
    const studentsCol = db.collection('students');
    let students = studentsCol.find();

    if (query.class) {
      students = students.filter(
        (s) => (s.class || '').toLowerCase() === query.class.toLowerCase()
      );
    }

    if (query.approved !== undefined) {
      const isApproved = query.approved === 'true' || query.approved === true;
      students = students.filter((s) => s.approved === isApproved);
    }

    if (!query.sortBy) {
      students.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }

    return applyFilterAndPagination(students, query, ['name', 'email', 'rollNo', 'class', 'section']);
  }

  async getById(id) {
    const student = db.collection('students').findById(id);
    if (!student) throw new AppError('Student not found', 404);
    return student;
  }

  async getParentChildren(parentId) {
    const links = db.collection('parent_children').find((l) => l.parentId === parentId);
    const studentsCol = db.collection('students');

    return links
      .map((link) => {
        const student = studentsCol.findById(link.studentId);
        return student || null;
      })
      .filter(Boolean);
  }

  async create(data) {
    const studentsCol = db.collection('students');
    const existing = studentsCol.findOne((s) => s.email && s.email.toLowerCase() === data.email.toLowerCase());

    if (existing) {
      throw new AppError('Student with this email already exists', 400);
    }

    return studentsCol.insert({
      name: data.name,
      email: (data.email || '').toLowerCase(),
      rollNo: data.rollNo || '',
      class: data.class || '',
      section: data.section || '',
      contact: data.contact || '',
      approved: data.approved !== undefined ? data.approved : true,
    });
  }

  async update(id, updates) {
    const updated = db.collection('students').update(id, updates);
    if (!updated) throw new AppError('Student not found', 404);
    return updated;
  }

  async delete(id) {
    const deleted = db.collection('students').delete(id);
    if (!deleted) throw new AppError('Student not found', 404);
    return true;
  }
}

module.exports = new StudentsService();
