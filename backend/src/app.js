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

// Mount module routes
const authRoutes = require('./modules/auth/auth.routes');
const classesRoutes = require('./modules/classes/classes.routes');
const studentsRoutes = require('./modules/students/students.routes');
const teachersRoutes = require('./modules/teachers/teachers.routes');
const attendanceRoutes = require('./modules/attendance/attendance.routes');

apiRouter.use('/auth', authRoutes);
apiRouter.use('/classes', classesRoutes);
apiRouter.use('/students', studentsRoutes);
apiRouter.use('/teachers', teachersRoutes);
apiRouter.use('/attendance', attendanceRoutes);

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

