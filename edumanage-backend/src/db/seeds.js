const bcrypt = require('bcryptjs');
const db = require('./store');

const seedDatabase = async () => {
  const usersCol = db.collection('users');
  const classesCol = db.collection('classes');
  const studentsCol = db.collection('students');
  const teachersCol = db.collection('teachers');
  const parentsCol = db.collection('parents');
  const parentChildrenCol = db.collection('parent_children');

  // Check if already seeded
  if (usersCol.count() > 0) {
    return;
  }

  console.log('[EduManage Seeds] Seeding initial database records...');

  const passwordHash = await bcrypt.hash('Password@123', 10);

  // 1. Admin User
  usersCol.insert({
    id: 'admin_001',
    uid: 'admin_001',
    name: 'System Administrator',
    email: 'admin@edumanage.edu',
    password: passwordHash,
    role: 'admin',
    approved: true,
    photoUrl: '',
  });

  // 2. Classes
  const grade9A = classesCol.insert({
    id: 'class_9a',
    name: 'Grade 9 - A',
    capacity: 35,
    teacherId: 'teacher_001',
    teacherName: 'Prof. John Smith',
  });

  const grade10B = classesCol.insert({
    id: 'class_10b',
    name: 'Grade 10 - B',
    capacity: 30,
    teacherId: 'teacher_002',
    teacherName: 'Dr. Sarah Connor',
  });

  // 3. Teachers
  usersCol.insert({
    id: 'teacher_001',
    uid: 'teacher_001',
    name: 'Prof. John Smith',
    email: 'john.smith@edumanage.edu',
    password: passwordHash,
    role: 'teacher',
    approved: true,
    photoUrl: '',
  });

  teachersCol.insert({
    id: 'teacher_001',
    uid: 'teacher_001',
    name: 'Prof. John Smith',
    email: 'john.smith@edumanage.edu',
    phone: '+1-555-0101',
    subject: 'Mathematics',
    qualification: 'M.Sc Mathematics',
    classes: ['Grade 9 - A'],
    approved: true,
  });

  usersCol.insert({
    id: 'teacher_002',
    uid: 'teacher_002',
    name: 'Dr. Sarah Connor',
    email: 'sarah.connor@edumanage.edu',
    password: passwordHash,
    role: 'teacher',
    approved: true,
    photoUrl: '',
  });

  teachersCol.insert({
    id: 'teacher_002',
    uid: 'teacher_002',
    name: 'Dr. Sarah Connor',
    email: 'sarah.connor@edumanage.edu',
    phone: '+1-555-0102',
    subject: 'Physics',
    qualification: 'Ph.D Physics',
    classes: ['Grade 10 - B'],
    approved: true,
  });

  // 4. Students
  usersCol.insert({
    id: 'student_001',
    uid: 'student_001',
    name: 'Alex Johnson',
    email: 'alex.johnson@edumanage.edu',
    password: passwordHash,
    role: 'student',
    approved: true,
    photoUrl: '',
  });

  studentsCol.insert({
    id: 'student_001',
    uid: 'student_001',
    name: 'Alex Johnson',
    email: 'alex.johnson@edumanage.edu',
    rollNo: 'S9A-001',
    class: 'Grade 9 - A',
    section: 'A',
    contact: '+1-555-0201',
    approved: true,
  });

  usersCol.insert({
    id: 'student_002',
    uid: 'student_002',
    name: 'Emma Watson',
    email: 'emma.watson@edumanage.edu',
    password: passwordHash,
    role: 'student',
    approved: true,
    photoUrl: '',
  });

  studentsCol.insert({
    id: 'student_002',
    uid: 'student_002',
    name: 'Emma Watson',
    email: 'emma.watson@edumanage.edu',
    rollNo: 'S10B-001',
    class: 'Grade 10 - B',
    section: 'B',
    contact: '+1-555-0202',
    approved: true,
  });

  // 5. Parents
  usersCol.insert({
    id: 'parent_001',
    uid: 'parent_001',
    name: 'Robert Johnson',
    email: 'robert.johnson@edumanage.edu',
    password: passwordHash,
    role: 'parent',
    approved: true,
    photoUrl: '',
  });

  parentsCol.insert({
    id: 'parent_001',
    uid: 'parent_001',
    name: 'Robert Johnson',
    email: 'robert.johnson@edumanage.edu',
    approved: true,
  });

  // Link parent to student
  parentChildrenCol.insert({
    id: 'pc_001',
    parentId: 'parent_001',
    studentId: 'student_001',
    studentName: 'Alex Johnson',
    studentRollNo: 'S9A-001',
    className: 'Grade 9 - A',
  });

  console.log('[EduManage Seeds] Database seeded successfully.');
};

module.exports = seedDatabase;
