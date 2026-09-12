const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');
const {
  clearAuditLogs,
  recordAuditEvent,
} = require('../src/middleware/audit.middleware');

test('Audit Logging & Security Trail Suite', async (t) => {
  await app.initDb();
  clearAuditLogs();

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  let adminToken = '';

  try {
    // 1. Authenticate as Admin
    await t.test('Admin logs in to access audit logs', async () => {
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

    // 2. Reject unauthenticated access to /audit/logs
    await t.test('GET /audit/logs rejects unauthenticated requests with 401', async () => {
      const res = await fetch(`${baseUrl}/audit/logs`);
      assert.strictEqual(res.status, 401);
    });

    // 3. Post manual audit event
    await t.test('POST /audit/event records administrative security event', async () => {
      const res = await fetch(`${baseUrl}/audit/event`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          action: 'SECURITY_CONFIG_UPDATE',
          resource: '/settings/security',
          details: { enforce2FA: true },
        }),
      });

      assert.strictEqual(res.status, 201);
      const body = await res.json();
      assert.strictEqual(body.success, true);
      assert.strictEqual(body.data.action, 'SECURITY_CONFIG_UPDATE');
    });

    // 4. Query audit logs with pagination and filters
    await t.test('GET /audit/logs returns recorded events with pagination', async () => {
      // Seed some programmatic audit events
      recordAuditEvent({
        action: 'FEE_OVERDUE_DISPATCH',
        actor: { id: 'admin_1', email: 'admin@edumanage.edu', role: 'admin' },
        statusCode: 200,
      });
      recordAuditEvent({
        action: 'USER_PASSWORD_RESET_ATTEMPT',
        actor: { id: 'user_99', email: 'student@edumanage.edu', role: 'student' },
        statusCode: 400,
      });

      const res = await fetch(`${baseUrl}/audit/logs?limit=10`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.strictEqual(json.success, true);
      assert.ok(json.total >= 3);
      assert.ok(Array.isArray(json.data));
    });

    // 5. Filter audit logs by action
    await t.test('GET /audit/logs filters by action name', async () => {
      const res = await fetch(
        `${baseUrl}/audit/logs?action=SECURITY_CONFIG_UPDATE`,
        {
          headers: { Authorization: `Bearer ${adminToken}` },
        }
      );

      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.ok(json.data.length >= 1);
      assert.strictEqual(json.data[0].action, 'SECURITY_CONFIG_UPDATE');
    });

    // 6. Check audit summary endpoint
    await t.test('GET /audit/summary returns aggregated metrics', async () => {
      const res = await fetch(`${baseUrl}/audit/summary`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });

      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.strictEqual(json.success, true);
      assert.ok(json.totalEvents >= 3);
      assert.ok(json.actionDistribution);
      assert.ok(json.roleDistribution);
    });
  } finally {
    server.close();
  }
});
