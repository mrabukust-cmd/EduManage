const defaultDb = require('../../db/store');

/**
 * Validates relational integrity across database collections.
 *
 * @param {Object} db - Database store instance (defaults to global singleton)
 * @returns {Object} Diagnostic report with integrity status and detected anomalies
 */
const validateRelationalIntegrity = (db = defaultDb) => {
  const issues = [];

  const users = db.collection('users').find();
  const classes = db.collection('classes').find();
  const students = db.collection('students').find();
  const fees = db.collection('fees').find();
  const attendance = db.collection('attendance').find();
  const results = db.collection('results').find();

  // Create lookup sets for fast existence checks
  const userIds = new Set(users.map((u) => u.id || u.uid));
  const classNames = new Set(classes.map((c) => c.name || c.className));
  const studentIds = new Set(
    students.map((s) => s.id || s.uid).concat([...userIds])
  );

  // 1. Check for duplicate emails in users
  const emailCounts = {};
  for (const u of users) {
    if (u.email) {
      const email = u.email.toLowerCase();
      emailCounts[email] = (emailCounts[email] || 0) + 1;
      if (emailCounts[email] > 1) {
        issues.push({
          severity: 'error',
          collection: 'users',
          entityId: u.id || u.uid,
          message: `Duplicate user email detected: ${u.email}`,
        });
      }
    }
  }

  // 2. Validate students have assigned classes that exist
  for (const s of students) {
    const studentClass = s.class || s.className;
    if (studentClass && classNames.size > 0 && !classNames.has(studentClass)) {
      issues.push({
        severity: 'warning',
        collection: 'students',
        entityId: s.id || s.uid,
        message: `Student references non-existent class: '${studentClass}'`,
      });
    }
  }

  // 3. Validate fee invoices reference known students
  for (const f of fees) {
    if (f.studentId && !studentIds.has(f.studentId)) {
      issues.push({
        severity: 'error',
        collection: 'fees',
        entityId: f.id,
        message: `Fee record links to non-existent student ID: '${f.studentId}'`,
      });
    }
  }

  // 4. Validate attendance entries reference known students
  for (const a of attendance) {
    if (a.studentId && !studentIds.has(a.studentId)) {
      issues.push({
        severity: 'warning',
        collection: 'attendance',
        entityId: a.id,
        message: `Attendance links to non-existent student ID: '${a.studentId}'`,
      });
    }
  }

  // 5. Validate academic results reference known students
  for (const r of results) {
    if (r.studentId && !studentIds.has(r.studentId)) {
      issues.push({
        severity: 'warning',
        collection: 'results',
        entityId: r.id,
        message: `Result links to non-existent student ID: '${r.studentId}'`,
      });
    }
  }

  const errorCount = issues.filter((i) => i.severity === 'error').length;
  const warningCount = issues.filter((i) => i.severity === 'warning').length;

  let status = 'healthy';
  if (errorCount > 0) {
    status = 'degraded';
  } else if (warningCount > 0) {
    status = 'warning';
  }

  return {
    success: true,
    status,
    checkedAt: new Date().toISOString(),
    issueCount: issues.length,
    summary: {
      errors: errorCount,
      warnings: warningCount,
    },
    issues,
    entityCounts: {
      users: users.length,
      classes: classes.length,
      students: students.length,
      fees: fees.length,
      attendance: attendance.length,
      results: results.length,
    },
  };
};

module.exports = {
  validateRelationalIntegrity,
};
