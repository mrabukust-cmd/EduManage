const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('Attendance Validation & Parameter Aliasing Suite', async (t) => {
  await app.initDb();

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  let teacherToken = '';

  try {
    // Authenticate as teacher
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'sarah.connor@edumanage.edu',
        password: 'Password@123',
      }),
    });
    const loginData = await loginRes.json();
    teacherToken = loginData.data?.token || '';

    await t.test('POST /attendance - accepts className alias payload', async () => {
      const res = await fetch(`${baseUrl}/attendance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${teacherToken}`,
        },
        body: JSON.stringify({
          className: 'Grade 10 - A',
          date: '2026-09-08',
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
      assert.strictEqual(data.data[0].className, 'Grade 10 - A');
    });

    await t.test('POST /attendance - rejects invalid status value with 400', async () => {
      const res = await fetch(`${baseUrl}/attendance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${teacherToken}`,
        },
        body: JSON.stringify({
          className: 'Grade 10 - A',
          date: '2026-09-08',
          records: [
            {
              studentId: 'student_001',
              status: 'unexcused', // Invalid status
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /Invalid status/);
    });

    await t.test('POST /attendance - rejects missing studentId with 400', async () => {
      const res = await fetch(`${baseUrl}/attendance`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${teacherToken}`,
        },
        body: JSON.stringify({
          className: 'Grade 10 - A',
          date: '2026-09-08',
          records: [
            {
              studentName: 'No ID Student',
              status: 'present',
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /studentId is required/);
    });

    await t.test('GET /attendance - rejects missing query parameters with 400', async () => {
      const res = await fetch(`${baseUrl}/attendance`, {
        headers: { Authorization: `Bearer ${teacherToken}` },
      });

      assert.strictEqual(res.status, 400);
      const data = await res.json();
      assert.strictEqual(data.success, false);
      assert.match(data.message, /Both className/);
    });

    await t.test('GET /attendance - retrieves attendance using className query parameter', async () => {
      const res = await fetch(`${baseUrl}/attendance?className=Grade%2010%20-%20A&date=2026-09-08`, {
        headers: { Authorization: `Bearer ${teacherToken}` },
      });

      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.success, true);
      assert.ok(data.data.length > 0);
    });
  } finally {
    server.close();
  }
});
