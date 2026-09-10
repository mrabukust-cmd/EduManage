# Changelog

All notable changes to the **EduManage** system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-09-10

### Added
- **DateTimeHelper Utility Suite**: Centralized date formatting (`formatIsoDate`, `formatDisplayDate`, `formatFullDateTime`), relative timestamps (`timeAgo`), and deadline difference calculation in Flutter.
- **Academic Models Validation Suite**: Unit and edge-case testing for `ClassModel`, `TimetableModel`, and `NoticeModel`.
- **Automated GitHub Actions CI**: Added `.github/workflows/ci.yml` running Flutter analyze/tests and Node.js backend integration test suites.
- **Project Documentation**: Added comprehensive `CONTRIBUTING.md` standards and `docs/ARCHITECTURE.md` system blueprint.

### Changed
- Refactored notice model parsing and test coverage.
- Updated project documentation and navigation links.

---

## [1.1.0] - 2026-09-09

### Added
- **Node.js Express REST API**: Production-ready backend server with JWT authentication, role verification, and rate limiting.
- **CSV Data Exporter**: RFC 4180 compliant CSV export engine for students roster, fee collections, attendance, and exam grades with injection attack mitigation.
- **Material 3 Dynamic Theming**: Complete dark mode palette with `themeModeProvider` state switching.
- **Validation Engine**: Robust `Validators` suite with composite rule chaining, email, password, phone, GPA, and amount validation.
- **Standardized UI Feedback**: Responsive `AppToast` floating snackbars and dismissible `AppBanner` alerts.

---

## [1.0.0] - 2026-09-08

### Added
- Initial release of EduManage School Management System.
- Multi-role portals for Administrators, Teachers, Students, and Parents.
- Academic modules: Classes, Timetable, Notices, and Attendance.
- Finance module: Invoices, receipt upload, and fee payment verification.
- Results module: Subject grading, GPA calculation, and report generation.
