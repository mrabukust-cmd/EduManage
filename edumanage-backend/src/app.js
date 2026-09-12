const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const logger = require('./middleware/logger.middleware');
const { notFound, errorHandler } = require('./middleware/error.middleware');
const { defaultLimiter } = require('./middleware/rateLimit.middleware');

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
  const memory = process.memoryUsage();
  res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.env,
    system: {
      platform: process.platform,
      arch: process.arch,
      nodeVersion: process.version,
      pid: process.pid,
    },
    memory: {
      rssMb: Math.round((memory.rss / 1024 / 1024) * 100) / 100,
      heapTotalMb: Math.round((memory.heapTotal / 1024 / 1024) * 100) / 100,
      heapUsedMb: Math.round((memory.heapUsed / 1024 / 1024) * 100) / 100,
    },
  });
});

app.get(`${config.apiPrefix}/health/ping`, (req, res) => {
  res.json({
    success: true,
    pong: true,
    timestamp: new Date().toISOString(),
  });
});

const { validateRelationalIntegrity } = require('./modules/system/integrity.service');
app.get(`${config.apiPrefix}/health/integrity`, (req, res) => {
  const report = validateRelationalIntegrity();
  res.json(report);
});

// ── API Routes (Mounted in Modules) ──────────────────────────
const apiRouter = express.Router();

// Mount module routes
const authRoutes = require('./modules/auth/auth.routes');
const classesRoutes = require('./modules/classes/classes.routes');
const studentsRoutes = require('./modules/students/students.routes');
const teachersRoutes = require('./modules/teachers/teachers.routes');
const attendanceRoutes = require('./modules/attendance/attendance.routes');
const assignmentsRoutes = require('./modules/assignments/assignments.routes');
const feesRoutes = require('./modules/fees/fees.routes');
const noticesRoutes = require('./modules/notices/notices.routes');
const timetableRoutes = require('./modules/timetable/timetable.routes');
const resultsRoutes = require('./modules/results/results.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');
const exportRoutes = require('./modules/export/export.routes');
const auditRoutes = require('./modules/audit/audit.routes');

// Apply rate limiter to API router in production/development
if (config.env !== 'test') {
  apiRouter.use(defaultLimiter);
}

apiRouter.use('/auth', authRoutes);
apiRouter.use('/classes', classesRoutes);
apiRouter.use('/students', studentsRoutes);
apiRouter.use('/teachers', teachersRoutes);
apiRouter.use('/attendance', attendanceRoutes);
apiRouter.use('/assignments', assignmentsRoutes);
apiRouter.use('/fees', feesRoutes);
apiRouter.use('/notices', noticesRoutes);
apiRouter.use('/timetable', timetableRoutes);
apiRouter.use('/results', resultsRoutes);
apiRouter.use('/dashboard', dashboardRoutes);
apiRouter.use('/export', exportRoutes);
apiRouter.use('/audit', auditRoutes);

// Mount root api router
app.use(config.apiPrefix, apiRouter);
app.apiRouter = apiRouter;


// Seed initial database records
const seedDatabase = require('./db/seeds');
app.initDb = seedDatabase;
seedDatabase().catch((err) => console.error('[EduManage Seed Error]:', err));

// ── 404 & Error Handler ──────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

module.exports = app;

