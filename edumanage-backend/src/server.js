const app = require('./app');
const config = require('./config');

const server = app.listen(config.port, () => {
  console.log(`[EduManage Server] Running on http://localhost:${config.port} in ${config.env} mode`);
});

// ── Handle Unhandled Rejections & Exceptions ─────────────────
process.on('unhandledRejection', (err) => {
  console.error('[EduManage Server] UNHANDLED REJECTION! Shutting down...', err);
  server.close(() => {
    process.exit(1);
  });
});

process.on('uncaughtException', (err) => {
  console.error('[EduManage Server] UNCAUGHT EXCEPTION! Shutting down...', err);
  process.exit(1);
});

// ── Graceful Shutdown ────────────────────────────────────────
process.on('SIGTERM', () => {
  console.log('[EduManage Server] SIGTERM received. Gracefully terminating...');
  server.close(() => {
    console.log('[EduManage Server] Process terminated.');
  });
});

module.exports = server;
