const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');
const {
  validateRelationalIntegrity,
} = require('../src/modules/system/integrity.service');

test('System Relational Integrity Suite', async (t) => {
  await app.initDb();

  const server = app.listen(0);
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}/api/v1`;

  try {
    // 1. Live probe: GET /health/integrity returns healthy on standard seeded data
    await t.test('GET /health/integrity returns healthy baseline status', async () => {
      const res = await fetch(`${baseUrl}/health/integrity`);
      assert.strictEqual(res.status, 200);

      const json = await res.json();
      assert.strictEqual(json.success, true);
      assert.ok(json.status === 'healthy' || json.status === 'warning');
      assert.ok(json.entityCounts);
      assert.ok(json.entityCounts.users >= 1);
      assert.ok(json.entityCounts.classes >= 1);
      assert.ok(json.checkedAt);
    });

    // 2. Unit test: mock DB detecting duplicate emails
    await t.test('validateRelationalIntegrity detects duplicate user email addresses', () => {
      const mockDb = {
        collection: (name) => ({
          find: () => {
            if (name === 'users') {
              return [
                { id: 'u1', email: 'duplicate@school.edu' },
                { id: 'u2', email: 'duplicate@school.edu' },
              ];
            }
            return [];
          },
        }),
      };

      const report = validateRelationalIntegrity(mockDb);
      assert.strictEqual(report.status, 'degraded');
      assert.strictEqual(report.summary.errors, 1);
      assert.ok(report.issues.some((i) => i.collection === 'users'));
    });

    // 3. Unit test: mock DB detecting orphaned fee records
    await t.test('validateRelationalIntegrity identifies orphaned fee records', () => {
      const mockDb = {
        collection: (name) => ({
          find: () => {
            if (name === 'users') return [];
            if (name === 'classes') return [];
            if (name === 'students') return [{ id: 'stu_10', class: 'Grade 9' }];
            if (name === 'fees') {
              return [{ id: 'fee_99', studentId: 'stu_unknown_orphan' }];
            }
            return [];
          },
        }),
      };

      const report = validateRelationalIntegrity(mockDb);
      assert.strictEqual(report.status, 'degraded');
      assert.ok(report.issues.some((i) => i.collection === 'fees'));
    });
  } finally {
    server.close();
  }
});
