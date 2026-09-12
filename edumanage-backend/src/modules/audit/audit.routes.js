const express = require('express');
const router = express.Router();
const { authenticate, authorizeRoles } = require('../../middleware/auth.middleware');
const {
  getAuditLogs,
  getAuditSummary,
  recordAuditEvent,
} = require('../../middleware/audit.middleware');

// Protect all audit endpoints: require authentication and admin role
router.use(authenticate);
router.use(authorizeRoles('admin'));

/**
 * GET /api/v1/audit/logs
 * Query paginated audit trails with optional filters.
 */
router.get('/logs', (req, res) => {
  const result = getAuditLogs(req.query);
  res.json(result);
});

/**
 * GET /api/v1/audit/summary
 * Aggregate statistics of recorded audit events.
 */
router.get('/summary', (req, res) => {
  const summary = getAuditSummary();
  res.json(summary);
});

/**
 * POST /api/v1/audit/event
 * Manually record an administrative audit entry.
 */
router.post('/event', (req, res) => {
  const { action, resource, details } = req.body;
  if (!action) {
    return res.status(400).json({
      success: false,
      message: 'Audit action name is required.',
    });
  }

  const event = recordAuditEvent({
    action,
    actor: req.user,
    resource: resource || 'MANUAL_ENTRY',
    method: 'POST',
    statusCode: 200,
    ip: req.ip || '127.0.0.1',
    details: details || {},
  });

  res.status(201).json({
    success: true,
    data: event,
  });
});

module.exports = router;
