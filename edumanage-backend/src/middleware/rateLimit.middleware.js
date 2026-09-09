/**
 * Lightweight sliding-window in-memory rate limiting middleware
 * Protects endpoints against brute-force and request flooding.
 */
function createRateLimiter(options = {}) {
  const windowMs = options.windowMs || 60 * 1000; // 1 minute default
  const max = options.max || 100; // Max 100 requests per window
  const message = options.message || 'Too many requests, please try again later';
  const hits = new Map();

  function rateLimiter(req, res, next) {
    const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
    const now = Date.now();
    const windowStart = now - windowMs;

    let timestamps = hits.get(ip) || [];
    timestamps = timestamps.filter(t => t > windowStart);

    if (timestamps.length >= max) {
      res.setHeader('Retry-After', Math.ceil(windowMs / 1000));
      return res.status(429).json({
        success: false,
        message,
      });
    }

    timestamps.push(now);
    hits.set(ip, timestamps);

    res.setHeader('RateLimit-Limit', max);
    res.setHeader('RateLimit-Remaining', max - timestamps.length);

    next();
  }

  rateLimiter.reset = () => hits.clear();

  return rateLimiter;
}

module.exports = {
  createRateLimiter,
  defaultLimiter: createRateLimiter({ windowMs: 60 * 1000, max: 120 }),
  authLimiter: createRateLimiter({ windowMs: 15 * 60 * 1000, max: 20, message: 'Too many login attempts, please try again later' }),
};
