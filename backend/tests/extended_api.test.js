const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('Extended APIs Integration Suite', async (t) => {
  await app.initDb();

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  let adminToken = '';

  try {
    // 1. Authenticate as Admin
    await t.test('Admin authentication for extended tests', async () => {
      const res = await fetch(`${baseUrl}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'admin@edumanage.edu',
          password: 'Password@123',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      adminToken = data.data.token;
      assert.ok(adminToken);
    });

    // 2. Test Assignments
    let createdAssignmentId = '';
    await t.test('POST /assignments - create an assignment', async () => {
      const res = await fetch(`${baseUrl}/assignments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          title: 'Calculus Homework 1',
          class: 'Grade 9 - A',
          subject: 'Mathematics',
          dueDate: '2026-09-15',
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.data.title, 'Calculus Homework 1');
      createdAssignmentId = data.data.id;
    });

    await t.test('GET /assignments - list assignments', async () => {
      const res = await fetch(`${baseUrl}/assignments?class=Grade 9 - A`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.count >= 1);
    });

    // 3. Test Fees & Verification
    let feeId = '';
    await t.test('POST /fees - create fee invoice', async () => {
      const res = await fetch(`${baseUrl}/fees`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          studentId: 'student_001',
          studentName: 'Alex Johnson',
          className: 'Grade 9 - A',
          feeType: 'Tuition Fee',
          amount: 1500,
          dueDate: '2026-09-30',
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      feeId = data.data.id;
      assert.strictEqual(data.data.amount, 1500);
      assert.strictEqual(data.data.status, 'pending');
    });

    await t.test('POST /fees/:id/pay - submit payment proof', async () => {
      const res = await fetch(`${baseUrl}/fees/${feeId}/pay`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          transactionId: 'TXN_99882211',
          paidAmount: 1500,
          notes: 'Paid via bank transfer',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.data.status, 'pending_verification');
    });

    await t.test('PUT /fees/:id/verify - admin approves payment', async () => {
      const res = await fetch(`${baseUrl}/fees/${feeId}/verify`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          verified: true,
          reason: 'Bank statement verified',
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.data.status, 'paid');
    });

    await t.test('GET /fees/statistics - get fee analytics', async () => {
      const res = await fetch(`${baseUrl}/fees/statistics`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.data.totalRevenue >= 1500);
    });

    // 4. Test Notices
    await t.test('POST /notices - create notice', async () => {
      const res = await fetch(`${baseUrl}/notices`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          title: 'Parent-Teacher Meeting',
          content: 'Scheduled for Friday at 10 AM',
          targetRole: 'Parent',
          priority: 'high',
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.data.title, 'Parent-Teacher Meeting');
    });

    // 5. Test Timetable
    await t.test('POST /timetable - create timetable slot', async () => {
      const res = await fetch(`${baseUrl}/timetable`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          class: 'Grade 9 - A',
          day: 'Monday',
          subject: 'Physics',
          startTime: '09:00 AM',
          endTime: '09:45 AM',
          room: 'Lab 1',
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.data.subject, 'Physics');
    });

    // 6. Test Results
    await t.test('POST /results - record exam grade', async () => {
      const res = await fetch(`${baseUrl}/results`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          studentId: 'student_001',
          studentName: 'Alex Johnson',
          class: 'Grade 9 - A',
          subject: 'Mathematics',
          marksObtained: 94,
          totalMarks: 100,
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.data.grade, 'A+');
      assert.strictEqual(data.data.percentage, 94);
    });

    // 7. Test Dashboard Aggregation
    await t.test('GET /dashboard/admin - returns aggregated statistics', async () => {
      const res = await fetch(`${baseUrl}/dashboard/admin`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.data.totalStudents >= 2);
      assert.ok(data.data.totalTeachers >= 2);
      assert.ok(data.data.totalClasses >= 2);
      assert.ok(Array.isArray(data.data.recentActivities));
    });
  } finally {
    server.close();
  }
});
