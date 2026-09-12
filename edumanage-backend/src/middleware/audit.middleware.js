const auditLogStore = [];
const MAX_AUDIT_LOGS = 500;

/**
 * Record a structured audit event into the store.
 */
const recordAuditEvent = ({
  action,
  actor = null,
  resource = '',
  method = 'CUSTOM',
  statusCode = 200,
  ip = '127.0.0.1',
  durationMs = 0,
  details = {},
}) => {
  const event = {
    id: `audit_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
    timestamp: new Date().toISOString(),
    action,
    actor: actor
      ? {
          id: actor.id || actor.uid || 'unknown',
          email: actor.email || 'unknown',
          role: actor.role || 'unknown',
        }
      : { id: 'system', email: 'system@edumanage.local', role: 'system' },
    resource,
    method,
    statusCode,
    ip,
    durationMs: Math.round(durationMs * 100) / 100,
    details,
  };

  auditLogStore.unshift(event);

  // Maintain max bounded capacity
  if (auditLogStore.length > MAX_AUDIT_LOGS) {
    auditLogStore.pop();
  }

  return event;
};

/**
 * Express middleware that records an audit trail entry upon response completion.
 */
const auditLogger = (actionName) => {
  return (req, res, next) => {
    const start = process.hrtime();

    res.on('finish', () => {
      const diff = process.hrtime(start);
      const durationMs = (diff[0] * 1e9 + diff[1]) / 1e6;

      const action =
        actionName ||
        `${req.method}_${req.baseUrl || ''}${req.path || ''}`.toUpperCase();

      // Mask sensitive fields if present in body
      const sanitizedDetails = {};
      if (req.body && typeof req.body === 'object') {
        for (const [key, val] of Object.entries(req.body)) {
          if (/pass|secret|token|credential/i.test(key)) {
            sanitizedDetails[key] = '***REDACTED***';
          } else {
            sanitizedDetails[key] = val;
          }
        }
      }

      recordAuditEvent({
        action,
        actor: req.user || null,
        resource: req.originalUrl || req.url,
        method: req.method,
        statusCode: res.statusCode,
        ip: req.ip || req.connection.remoteAddress || '127.0.0.1',
        durationMs,
        details: sanitizedDetails,
      });
    });

    next();
  };
};

/**
 * Retrieve filtered and paginated audit records.
 */
const getAuditLogs = ({
  page = 1,
  limit = 20,
  action,
  role,
  status,
} = {}) => {
  let filtered = [...auditLogStore];

  if (action) {
    filtered = filtered.filter((e) =>
      e.action.toLowerCase().includes(action.toLowerCase())
    );
  }

  if (role) {
    filtered = filtered.filter(
      (e) => e.actor && e.actor.role.toLowerCase() === role.toLowerCase()
    );
  }

  if (status) {
    const statusCode = parseInt(status, 10);
    if (!isNaN(statusCode)) {
      filtered = filtered.filter((e) => e.statusCode === statusCode);
    }
  }

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
  const startIndex = (pageNum - 1) * limitNum;
  const endIndex = startIndex + limitNum;

  const data = filtered.slice(startIndex, endIndex);

  return {
    success: true,
    total: filtered.length,
    page: pageNum,
    limit: limitNum,
    totalPages: Math.ceil(filtered.length / limitNum) || 1,
    data,
  };
};

/**
 * Generate aggregated metrics and analytics for audit events.
 */
const getAuditSummary = () => {
  const actionCounts = {};
  const roleCounts = {};
  let totalDuration = 0;

  for (const log of auditLogStore) {
    actionCounts[log.action] = (actionCounts[log.action] || 0) + 1;
    const role = log.actor ? log.actor.role : 'system';
    roleCounts[role] = (roleCounts[role] || 0) + 1;
    totalDuration += log.durationMs || 0;
  }

  const avgDurationMs =
    auditLogStore.length === 0
      ? 0
      : Math.round((totalDuration / auditLogStore.length) * 100) / 100;

  return {
    success: true,
    totalEvents: auditLogStore.length,
    avgDurationMs,
    actionDistribution: actionCounts,
    roleDistribution: roleCounts,
  };
};

/**
 * Reset audit logs (used for test setup).
 */
const clearAuditLogs = () => {
  auditLogStore.length = 0;
};

module.exports = {
  recordAuditEvent,
  auditLogger,
  getAuditLogs,
  getAuditSummary,
  clearAuditLogs,
};
