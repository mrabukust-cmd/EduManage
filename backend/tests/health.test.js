const test = require('node:test');
const assert = require('node:assert');
const app = require('../src/app');

test('Health check endpoint returns status healthy', async () => {
  // Start server on an ephemeral port
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://localhost:${port}/api/v1/health`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.status, 'healthy');
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
