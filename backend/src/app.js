const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const logger = require('./middleware/logger.middleware');
const { notFound, errorHandler } = require('./middleware/error.middleware');

const app = express();

// ── Security & Utility Middleware ────────────────────────────
app.use(helmet());
app.use(cors({ origin: config.cors.origin, credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

if (config.env !== 'test') {
  app.use(logger);
}

// ── Root & Health Endpoints ──────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to EduManage REST API',
    version: '1.0.0',
    docs: `${config.apiPrefix}/health`,
  });
});

app.get(`${config.apiPrefix}/health`, (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.env,
  });
});

// ── API Routes (Mounted in Modules) ──────────────────────────
const apiRouter = express.Router();

// Mount root api router
app.use(config.apiPrefix, apiRouter);

// Export apiRouter so module routes can attach to it
app.apiRouter = apiRouter;

// ── 404 & Error Handler ──────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

module.exports = app;
