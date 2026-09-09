const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class FeesService {
  async getAll(query = {}) {
    let fees = db.collection('fees').find();

    if (query.studentId) {
      fees = fees.filter((f) => f.studentId === query.studentId);
    }

    if (query.class) {
      fees = fees.filter((f) => (f.className || f.class || '').toLowerCase() === query.class.toLowerCase());
    }

    if (query.status && query.status !== 'all') {
      fees = fees.filter((f) => (f.status || '').toLowerCase() === query.status.toLowerCase());
    }

    return fees.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
  }

  async getById(id) {
    const fee = db.collection('fees').findById(id);
    if (!fee) throw new AppError('Fee record not found', 404);
    return fee;
  }

  async create(data) {
    return db.collection('fees').insert({
      studentId: data.studentId,
      studentName: data.studentName || '',
      className: data.className || data.class || '',
      feeType: data.feeType || 'Tuition Fee',
      amount: parseFloat(data.amount || 0),
      dueDate: data.dueDate,
      month: data.month || '',
      year: data.year || new Date().getFullYear().toString(),
      status: data.status || 'pending', // 'pending' | 'paid' | 'overdue' | 'pending_verification'
      paymentProof: null,
    });
  }

  async submitPaymentProof(id, { transactionId, paidAmount, paymentDate, notes, submittedBy }) {
    const fee = db.collection('fees').findById(id);
    if (!fee) throw new AppError('Fee record not found', 404);

    const paymentProof = {
      transactionId,
      paidAmount: parseFloat(paidAmount || fee.amount),
      paymentDate: paymentDate || new Date().toISOString().split('T')[0],
      notes: notes || '',
      submittedAt: new Date().toISOString(),
      submittedBy,
    };

    return db.collection('fees').update(id, {
      status: 'pending_verification',
      paymentProof,
    });
  }

  async verifyPayment(id, { verified, reason = '' }) {
    const fee = db.collection('fees').findById(id);
    if (!fee) throw new AppError('Fee record not found', 404);

    const newStatus = verified ? 'paid' : 'pending';
    return db.collection('fees').update(id, {
      status: newStatus,
      verifiedAt: new Date().toISOString(),
      verificationNote: reason,
    });
  }

  async getStatistics() {
    const all = db.collection('fees').find();
    let totalRevenue = 0;
    let pendingAmount = 0;
    let paidCount = 0;
    let pendingCount = 0;
    let overdueCount = 0;
    let pendingVerificationCount = 0;

    for (const f of all) {
      const amt = parseFloat(f.amount || 0);
      if (f.status === 'paid') {
        totalRevenue += amt;
        paidCount++;
      } else if (f.status === 'pending_verification') {
        pendingVerificationCount++;
        pendingAmount += amt;
      } else if (f.status === 'overdue') {
        overdueCount++;
        pendingAmount += amt;
      } else {
        pendingCount++;
        pendingAmount += amt;
      }
    }

    return {
      totalRecords: all.length,
      totalRevenue,
      pendingAmount,
      paidCount,
      pendingCount,
      overdueCount,
      pendingVerificationCount,
    };
  }
}

module.exports = new FeesService();
