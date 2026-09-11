const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('Health check endpoint returns status healthy and system metrics', async () => {
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://localhost:${port}/api/v1/health`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.status, 'healthy');
    assert.ok(body.uptime >= 0);
    assert.ok(body.system);
    assert.ok(body.system.platform);
    assert.ok(body.system.nodeVersion);
    assert.ok(body.memory);
    assert.ok(typeof body.memory.rssMb === 'number');
    assert.ok(typeof body.memory.heapUsedMb === 'number');
  } finally {
    server.close();
  }
});

test('Health ping probe returns immediate liveness confirmation', async () => {
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://localhost:${port}/api/v1/health/ping`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.pong, true);
    assert.ok(body.timestamp);
  } finally {
    server.close();
  }
});

test('Root endpoint returns API metadata', async () => {
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://localhost:${port}/`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.version, '1.0.0');
  } finally {
    server.close();
  }
});
