const test = require('node:test');
const assert = require('node:assert');
const http = require('http');
const app = require('../src/app');

let server;
let baseUrl;
let adminToken;

test.before(async () => {
  await app.initDb();
  server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  baseUrl = `http://localhost:${port}/api/v1`;

  // Authenticate admin
  const loginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'admin@edumanage.edu',
      password: 'Password@123',
    }),
  });
  const data = await loginRes.json();
  adminToken = data.data.token;
});

test.after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

test('Query & Pagination Suite', async (t) => {
  await t.test('GET /students with search returns matching items', async () => {
    const res = await fetch(`${baseUrl}/students?search=Alex`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(Array.isArray(json.data));
    assert.ok(json.data.length >= 1);
    assert.ok(json.data[0].name.toLowerCase().includes('alex'));
  });

  await t.test('GET /students with pagination limits result count and includes meta', async () => {
    const res = await fetch(`${baseUrl}/students?page=1&limit=1`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.data.length, 1);
    assert.ok(json.pagination);
    assert.strictEqual(json.pagination.page, 1);
    assert.strictEqual(json.pagination.limit, 1);
    assert.ok(json.pagination.total >= 1);
  });

  await t.test('GET /classes with search returns filtered classes', async () => {
    const res = await fetch(`${baseUrl}/classes?search=Grade`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(Array.isArray(json.data));
    assert.ok(json.data.length >= 1);
  });

  await t.test('GET /teachers with sorting sorts correctly', async () => {
    const res = await fetch(`${baseUrl}/teachers?sortBy=name&sortOrder=asc`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.ok(Array.isArray(json.data));
    if (json.data.length > 1) {
      assert.ok(json.data[0].name.localeCompare(json.data[1].name) <= 0);
    }
  });
});
