const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');
const { createRateLimiter } = require('../src/middleware/rateLimit.middleware');

test('Rate Limiter blocks requests exceeding allowed limit', async () => {
  const limiter = createRateLimiter({ windowMs: 1000, max: 2, message: 'Too many requests' });

  let called = 0;
  const mockReq = { ip: '192.168.1.100' };
  const mockRes = {
    statusCode: 200,
    headers: {},
    setHeader(k, v) { this.headers[k] = v; },
    status(code) { this.statusCode = code; return this; },
    json(data) { this.body = data; return this; },
  };
  const mockNext = () => { called++; };

  // Request 1: OK
  limiter(mockReq, mockRes, mockNext);
  assert.strictEqual(called, 1);
  assert.strictEqual(mockRes.headers['RateLimit-Remaining'], 1);

  // Request 2: OK
  limiter(mockReq, mockRes, mockNext);
  assert.strictEqual(called, 2);
  assert.strictEqual(mockRes.headers['RateLimit-Remaining'], 0);

  // Request 3: Blocked (429)
  limiter(mockReq, mockRes, mockNext);
  assert.strictEqual(called, 2);
  assert.strictEqual(mockRes.statusCode, 429);
  assert.strictEqual(mockRes.body.success, false);
  assert.strictEqual(mockRes.body.message, 'Too many requests');
});

test('Export Endpoints require authentication and export CSV with correct headers', async () => {
  await app.initDb();
  const server = app.listen(0);
  const port = server.address().port;

  try {
    // 1. Unauthenticated request to /export/students should return 401
    const unauthRes = await fetch(`http://localhost:${port}/api/v1/export/students`);
    assert.strictEqual(unauthRes.status, 401);

    // 2. Login as admin to obtain JWT
    const loginRes = await fetch(`http://localhost:${port}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@edumanage.edu', password: 'Password@123' }),
    });
    assert.strictEqual(loginRes.status, 200);
    const loginData = await loginRes.json();
    const token = loginData.data.token;

    // 3. Authenticated request to /export/students returns CSV
    const studentsRes = await fetch(`http://localhost:${port}/api/v1/export/students`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    assert.strictEqual(studentsRes.status, 200);
    assert.ok(studentsRes.headers.get('content-type').includes('text/csv'));
    const studentsCsv = await studentsRes.text();
    assert.ok(studentsCsv.includes('Roll Number'));
    assert.ok(studentsCsv.includes('Name'));

    // 4. Authenticated request to /export/fees returns CSV
    const feesRes = await fetch(`http://localhost:${port}/api/v1/export/fees`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    assert.strictEqual(feesRes.status, 200);
    assert.ok(feesRes.headers.get('content-type').includes('text/csv'));
    const feesCsv = await feesRes.text();
    assert.ok(feesCsv.includes('Fee ID'));
    assert.ok(feesCsv.includes('Student Name'));
  } finally {
    server.close();
  }
});
