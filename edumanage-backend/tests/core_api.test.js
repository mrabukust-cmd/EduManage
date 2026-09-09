const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('Core APIs Integration Suite', async (t) => {
  await app.initDb();

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;


  let adminToken = '';
  let studentToken = '';

  try {
    // 1. Test Admin Login
    await t.test('POST /auth/login - admin logs in and receives JWT', async () => {
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
      assert.strictEqual(data.success, true);
      assert.strictEqual(data.data.user.role, 'admin');
      assert.ok(data.data.token);
      adminToken = data.data.token;
    });

    // 2. Test Get Me Profile
    await t.test('GET /auth/me - returns authenticated user profile', async () => {
      const res = await fetch(`${baseUrl}/auth/me`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.data.email, 'admin@edumanage.edu');
    });

    // 3. Test Classes Listing
    await t.test('GET /classes - lists registered classes', async () => {
      const res = await fetch(`${baseUrl}/classes`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.ok(data.count >= 2);
    });

    // 4. Test Create Class
    await t.test('POST /classes - admin creates a new class', async () => {
      const className = `Grade 11 - ${Date.now()}`;
      const res = await fetch(`${baseUrl}/classes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          name: className,
          capacity: 32,
        }),
      });

      assert.strictEqual(res.status, 201);
      const data = await res.json();
      assert.strictEqual(data.data.name, className);
    });


    // 5. Test Students Listing
    await t.test('GET /students - lists enrolled students', async () => {
      const res = await fetch(`${baseUrl}/students`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.count >= 2);
    });

    // 6. Test Teachers Listing
    await t.test('GET /teachers - lists teachers', async () => {
      const res = await fetch(`${baseUrl}/teachers`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.ok(data.count >= 2);
    });

    // 7. Test Mark Attendance
    await t.test('POST /attendance - records attendance for class', async () => {
      const res = await fetch(`${baseUrl}/attendance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          class: 'Grade 9 - A',
          date: '2026-09-03',
          records: [
            {
              studentId: 'student_001',
              studentName: 'Alex Johnson',
              status: 'present',
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
    });

    // 8. Test Student Attendance Summary
    await t.test('GET /attendance/student/:id - returns student attendance percentage', async () => {
      const res = await fetch(`${baseUrl}/attendance/student/student_001`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.data.studentId, 'student_001');
      assert.strictEqual(data.data.present, 1);
      assert.strictEqual(data.data.percentage, 100);
    });
  } finally {
    server.close();
  }
});
