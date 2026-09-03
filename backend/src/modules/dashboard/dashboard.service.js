const db = require('../../db/store');

class DashboardService {
  async getAdminStats() {
    const totalStudents = db.collection('students').count();
    const totalTeachers = db.collection('teachers').count();
    const totalClasses = db.collection('classes').count();
    const totalNotices = db.collection('notices').count();

    const fees = db.collection('fees').find();
    let totalRevenue = 0;
    let pendingFees = 0;
    for (const f of fees) {
      if (f.status === 'paid') totalRevenue += parseFloat(f.amount || 0);
      else pendingFees += parseFloat(f.amount || 0);
    }

    // Recent activity stream: union of newly added records
    const recentStudents = db.collection('students').find().slice(-5).map(s => ({
      type: 'student_enrolled',
      title: `Student enrolled: ${s.name}`,
      subtitle: `Class: ${s.class || 'Unassigned'}`,
      timestamp: s.createdAt,
    }));

    const recentNotices = db.collection('notices').find().slice(-5).map(n => ({
      type: 'notice_published',
      title: `Notice: ${n.title}`,
      subtitle: `Target: ${n.targetRole}`,
      timestamp: n.createdAt,
    }));

    const recentActivities = [...recentStudents, ...recentNotices]
      .sort((a, b) => new Date(b.timestamp || 0) - new Date(a.timestamp || 0))
      .slice(0, 10);

    return {
      totalStudents,
      totalTeachers,
      totalClasses,
      totalNotices,
      totalRevenue,
      pendingFees,
      recentActivities,
    };
  }

  async getTeacherStats(teacherId) {
    const teacher = db.collection('teachers').findById(teacherId);
    const classes = teacher ? teacher.classes || [] : [];
    
    const assignments = db.collection('assignments').find((a) => a.teacherId === teacherId);
    const activeAssignments = assignments.length;

    return {
      assignedClasses: classes,
      totalClasses: classes.length,
      activeAssignments,
    };
  }

  async getStudentStats(studentId) {
    const student = db.collection('students').findById(studentId);
    const attendanceRecords = db.collection('attendance').find((a) => a.studentId === studentId);
    const totalAtt = attendanceRecords.length;
    const presentAtt = attendanceRecords.filter((a) => a.status === 'present').length;
    const attendancePct = totalAtt > 0 ? Math.round((presentAtt / totalAtt) * 100) : 0;

    const assignments = student && student.class
      ? db.collection('assignments').find((a) => (a.className || a.class || '').toLowerCase() === student.class.toLowerCase())
      : [];

    const results = db.collection('results').find((r) => r.studentId === studentId);

    return {
      student,
      attendancePercentage: attendancePct,
      pendingAssignmentsCount: assignments.length,
      recentResults: results.slice(-5),
    };
  }
}

module.exports = new DashboardService();
