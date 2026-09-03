const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class NoticesService {
  async getAll(query = {}) {
    let notices = db.collection('notices').find();

    if (query.targetRole && query.targetRole !== 'All') {
      notices = notices.filter(
        (n) => n.targetRole === 'All' || n.targetRole === query.targetRole
      );
    }

    if (query.category && query.category !== 'All') {
      notices = notices.filter(
        (n) => (n.category || '').toLowerCase() === query.category.toLowerCase()
      );
    }

    return notices.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
  }

  async getById(id) {
    const notice = db.collection('notices').findById(id);
    if (!notice) throw new AppError('Notice not found', 404);
    return notice;
  }

  async create(data) {
    return db.collection('notices').insert({
      title: data.title,
      content: data.content || data.body || '',
      category: data.category || 'General',
      targetRole: data.targetRole || 'All', // 'All', 'Student', 'Teacher', 'Parent'
      authorName: data.authorName || 'Administration',
      authorId: data.authorId || '',
      priority: data.priority || 'normal', // 'normal' | 'high' | 'urgent'
    });
  }

  async delete(id) {
    const deleted = db.collection('notices').delete(id);
    if (!deleted) throw new AppError('Notice not found', 404);
    return true;
  }
}

module.exports = new NoticesService();
