# EduManage Utilities & Health Monitoring Specification

This document provides a technical overview of the utility suites and system monitoring tools introduced in EduManage **v1.3.0**.

---

## 1. AppLogger (`lib/core/utils/app_logger.dart`)

Structured logging framework designed for mobile, web, and desktop environments.

### Key Capabilities
- **Severity Levels**: `debug`, `info`, `warning`, `error`, `wtf` (fatal).
- **Environment Aware**: Automatically sets minimum level to `info` in production (`kReleaseMode`), and `debug` during development.
- **In-Memory Ring Buffer**: Retains the last 200 log entries in memory for diagnostic export.
- **Diagnostic Export**: `AppLogger.exportLogsAsString()` exports complete trace logs for support tickets or bug reports.
- **Pluggable Printers**: Supports `customPrinter` hook for redirecting logs to remote monitoring (e.g., Sentry, Firebase Crashlytics).

---

## 2. SecurityHelper (`lib/core/utils/security_helper.dart`)

Enterprise-grade security and data-sanitization toolkit.

### Key Capabilities
- **Input Sanitization**: Strips dangerous HTML tags (`<script>`, `<iframe>`, etc.) and malicious URL schemes (`javascript:`, `data:`).
- **Injection Detection**: Scans inputs for known SQL injection patterns and cross-site scripting (XSS) vectors.
- **PII Obfuscation**:
  - `maskEmail(String)`: Protects student and parent emails (e.g. `j***e@domain.com`).
  - `maskPhoneNumber(String)`: Preserves dialing codes while masking middle subscriber digits.
  - `maskNationalId(String)`: Masks national identity and CNIC numbers.
- **Cryptographic Security**:
  - `generateSecureToken()`: Generates entropy-rich hex tokens via `Random.secure()`.
  - `constantTimeEquals()`: Mitigates timing attacks when validating tokens or hashes.

---

## 3. GpaCalculator (`lib/core/utils/gpa_calculator.dart`)

High-precision academic performance evaluation engine.

### Key Capabilities
- **Standard 4.0 Scale**: Evaluates grade points from percentages (`90%+ = 4.0`, `85-89% = 3.7`, down to `50% = 1.0` and `<50% = 0.0`).
- **Credit-Weighted SGPA**: Computes semester Grade Point Average weighted by course credit hours.
- **Cumulative CGPA**: Evaluates multi-semester cumulative averages.
- **Honors Classification**: Evaluates academic standing:
  - *Dean's List* (`CGPA >= 3.8`)
  - *First Class Honors* (`CGPA >= 3.5`)
  - *Good Academic Standing* (`CGPA >= 2.0`)
  - *Academic Warning* (`CGPA >= 1.7`)
  - *Academic Probation* (`CGPA < 1.7`)

---

## 4. NotificationHelper (`lib/core/utils/notification_helper.dart`)

Notification classifier, badge calculator, and visual priority mapper.

### Key Capabilities
- **Smart Categorization**: Automatically categorizes notifications into `emergency`, `fee`, `exam`, `attendance`, `holiday`, `academic`, or `general`.
- **Urgency Inference**: Assesses urgency levels (`low`, `normal`, `high`, `urgent`) for push alert scheduling.
- **Badge Counter**: Formats badge counts (`99+` formatting) and aggregates unread counts.
- **Theme Color & Icon Resolvers**: Maps categories to UI colors and icons for seamless display in alerts and notification trays.

---

## 5. NetworkService (`lib/core/services/network_service.dart`)

Reachability and connection quality monitor.

### Key Capabilities
- **Status States**: `connected`, `disconnected`, `slowConnection`, `unknown`.
- **Latency Evaluation**: Flags high-latency networks (`> 1500ms`) as `slowConnection` to enable degraded-network UI modes.
- **Injectable Ping Handlers**: Enables seamless unit testing without external socket dependencies.
- **Reactive State**: Extends `ChangeNotifier` to drive real-time offline banners across the app.

---

## 6. Backend System Health & Liveness Probes

Available via the Node.js / Express REST API backend:

### Endpoints

#### `GET /api/v1/health`
Returns full diagnostics including uptime, environment, system platform, Node.js version, and memory allocation:
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2026-09-11T06:46:22.000Z",
  "uptime": 142.58,
  "environment": "development",
  "system": {
    "platform": "win32",
    "arch": "x64",
    "nodeVersion": "v20.x",
    "pid": 12840
  },
  "memory": {
    "rssMb": 48.25,
    "heapTotalMb": 28.5,
    "heapUsedMb": 19.82
  }
}
```

#### `GET /api/v1/health/ping`
Ultra-fast, lightweight probe for load balancers and container orchestrators:
```json
{
  "success": true,
  "pong": true,
  "timestamp": "2026-09-11T06:46:22.000Z"
}
```
