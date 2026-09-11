# EduManage - School Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/mrabukust-cmd/EduManage/actions/workflows/ci.yml/badge.svg)](https://github.com/mrabukust-cmd/EduManage/actions)

EduManage is a comprehensive, multi-role School Management System featuring a cross-platform **Flutter** client (Android, iOS, Web, Desktop) and a high-performance **Node.js/Express** REST API backend with real-time Firebase support.

---

## Key Features

- **Multi-Role Dashboards**: Tailored experiences for Administrators, Teachers, Students, and Parents.
- **REST API + Firebase Dual Support**: Clean, modular API architecture with JWT authentication, query search/pagination, and persistent token caching.
- **Dark Mode & Dynamic Theming**: Complete Material 3 dark palette with `themeModeProvider` support for light, dark, and system theme switching.
- **Standardized UI Feedback**: Responsive `AppToast` floating snackbars and dismissible `AppBanner` alert widgets for consistent user feedback.
- **Robust Form Validation Engine**: Centralized `Validators` suite with email, password, phone, amount/currency, numeric bounds, score, GPA, URL, sanitizers, and composite rule chaining.
- **CSV Data Export Engine**: RFC 4180 compliant `CsvExporter` for students roster, fee collections, attendance, and exam grades with injection attack protection.
- **DateTime & Formatting Utilities**: Centralized `DateTimeHelper` for ISO parsing, human relative timestamps (`timeAgo`), and academic deadline calculations.
- **Attendance Management**: Class attendance marking, student percentage tracking, and monthly reports.
- **Assignments & Submissions**: Assignment distribution, deadline reminders, and file submission workflows.
- **Fee Management**: Invoice generation, receipt upload, admin verification, and fee collection analytics.
- **Notices & Timetable**: Institutional notice broadcasts and dynamic class schedule management.
- **Results & Grading**: Exam grade tracking with automated GPA and letter grade calculations.
- **Structured Telemetry & Logging**: Configurable `AppLogger` utility with severity levels, ring buffer caching, and diagnostic exports.
- **Security & Data Sanitization**: `SecurityHelper` suite protecting against XSS, SQL injection, and providing automated PII masking for emails, phones, and IDs.
- **Academic GPA & Honors Engine**: Precision `GpaCalculator` supporting 4.0 weighted scale, SGPA, CGPA, and honors/standing evaluation.
- **Smart Notification Categorization**: Dynamic `NotificationHelper` for urgency classification, badge counters, and category color mapping.
- **Network Reachability Monitoring**: `NetworkService` supporting latency evaluation and real-time connectivity state management.
- **API Security & Rate Limiting**: In-memory sliding window rate limiter protecting endpoints against brute-force and request flooding.
- **Backend Health & Liveness Probes**: System health endpoint `/api/v1/health` with process memory metrics and `/api/v1/health/ping` liveness probe.

---

## Tech Stack

- **Frontend**: Flutter 3.x, Flutter Riverpod, GoRouter, HTTP, ResponsiveSizer
- **Backend**: Node.js, Express.js, JWT, Helmet, Morgan, Bcrypt, RateLimit
- **Architecture**: Clean Architecture, Repository Pattern, Type-Safe API Services

---

## Documentation & Navigation

- **[System Architecture](docs/ARCHITECTURE.md)**: Deep-dive into client and server components, state management, and security model.
- **[REST API Specifications](docs/API_DOCUMENTATION.md)**: Complete endpoint contracts, request/response schemas, and Curl examples.
- **[Utilities & Health Monitoring](docs/UTILITIES_AND_HEALTH_SPEC.md)**: Specifications for security, logging, academic calculators, and health probes.
- **[Backend Guide](edumanage-backend/README.md)**: Setup and run instructions for the Express REST server.
- **[Contributing Guide](CONTRIBUTING.md)**: Standards, branch workflows, and conventional commit rules.
- **[Changelog](CHANGELOG.md)**: Full history of releases and milestone updates.

---

## Testing & Verification

Run automated test suites across both layers:

```bash
# Flutter Test Suite
flutter test

# Backend API Tests
cd edumanage-backend && npm test
```
