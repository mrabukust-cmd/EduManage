# EduManage - School Management System

EduManage is a comprehensive, multi-role School Management System featuring a cross-platform **Flutter** client (Android, iOS, Web, Desktop) and a high-performance **Node.js/Express** REST API backend with real-time Firebase support.

---

## Key Features

- **Multi-Role Dashboards**: Tailored experiences for Administrators, Teachers, Students, and Parents.
- **REST API + Firebase Dual Support**: Clean, modular API architecture with JWT authentication, query search/pagination, and persistent token caching.
- **Attendance Management**: Class attendance marking, student percentage tracking, and monthly reports.
- **Assignments & Submissions**: Assignment distribution, deadline reminders, and file submission workflows.
- **Fee Management**: Invoice generation, receipt upload, admin verification, and fee collection analytics.
- **Notices & Timetable**: Institutional notice broadcasts and dynamic class schedule management.
- **Results & Grading**: Exam grade tracking with automated GPA and letter grade calculations.

---

## Tech Stack

- **Frontend**: Flutter 3.x, Flutter Riverpod, GoRouter, HTTP
- **Backend**: Node.js, Express.js, JWT, Helmet, Morgan, Bcrypt
- **Architecture**: Clean Architecture, Repository Pattern, Type-Safe API Services

---

## Documentation & Getting Started

1. **REST API Documentation**: Full endpoint contracts, request/response schemas, and Curl examples are in [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md).
2. **Backend Setup**: Instructions for running the Express API server are in [backend/README.md](backend/README.md).
3. **Flutter App**: Run `flutter run` for Android/iOS/Web or desktop targets.

---

## Testing & Verification

Run automated test suites across both layers:

```bash
# Flutter Test Suite
flutter test

# Backend API Tests
cd backend && npm test
```
