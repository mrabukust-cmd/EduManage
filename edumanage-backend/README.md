# EduManage REST API Backend (`edumanage-backend`)

A modular, clean-architecture REST API backend built with **Node.js** and **Express.js**, powering the **EduManage** School Management System.

---

## 🏛️ Architecture & Folder Structure

The backend is organized with a clean, domain-driven modular architecture:

```
edumanage-backend/
├── .env.example              # Environment variables template
├── .gitignore                # Git ignore rules for Node.js
├── package.json              # NPM dependencies and scripts
├── package-lock.json         # Dependency lockfile
├── README.md                 # Backend documentation
├── data/
│   └── edumanage.db.json     # File-based JSON persistence store (runtime ignored)
├── src/
│   ├── app.js                # Express app configuration, middleware, and route mounting
│   ├── server.js             # HTTP server entrypoint and graceful shutdown listeners
│   ├── config/
│   │   └── index.js          # Central environment config (Port, JWT, CORS, Prefix)
│   ├── db/
│   │   ├── store.js          # Atomic document database store engine
│   │   └── seeds.js          # Initial database seeding for admin, classes, teachers, students
│   ├── middleware/
│   │   ├── auth.middleware.js       # JWT validation & Role-Based Access Control (RBAC)
│   │   ├── error.middleware.js      # Global 404 & centralized error handlers
│   │   ├── logger.middleware.js     # Morgan HTTP request logging
│   │   ├── query.middleware.js      # Query parsing, pagination, and field filtering
│   │   ├── rateLimit.middleware.js  # Sliding window rate limiter middleware
│   │   └── validate.middleware.js   # Payload validation & alias normalization
│   └── modules/
│       ├── assignments/      # Homework & assignment submissions
│       ├── attendance/       # Daily student & class attendance tracking
│       ├── auth/             # Authentication, login, profile, and JWT generation
│       ├── classes/          # Academic classes and sections management
│       ├── dashboard/        # Aggregated analytics for admin, teachers, students
│       ├── export/           # CSV data export streaming for students and fee records
│       ├── fees/             # Fee invoicing, online receipt submission, and verification
│       ├── notices/          # School notices, announcements, and push alerts
│       ├── results/          # Academic exam results and grading management
│       ├── students/         # Student directory, enrollment, and profile details
│       ├── teachers/         # Teacher staff records, qualifications, and approvals
│       └── timetable/        # Class timetable and weekly schedule slots
└── tests/
    ├── attendance_validation.test.js # Validation & alias test suite
    ├── core_api.test.js              # Auth, classes, students, teachers integration
    ├── extended_api.test.js          # Fees, notices, timetable, results, dashboard
    ├── health.test.js                # System health check endpoints
    ├── query_pagination.test.js      # Search, pagination, and sorting tests
    └── security_and_export.test.js   # Rate limiting & CSV export security tests
```

---

## 🚀 Getting Started

### Prerequisites
- **Node.js**: >= 18.0.0
- **npm**: >= 9.0.0

### Installation
```bash
cd edumanage-backend
npm install
```

### Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Default configuration values:
- `PORT`: `5000`
- `NODE_ENV`: `development`
- `JWT_SECRET`: `edumanage_dev_jwt_secret_key_2026`
- `JWT_EXPIRES_IN`: `7d`
- `CORS_ORIGIN`: `*`

### Running the Server
```bash
# Production mode
npm start

# Development mode (with auto-reload)
npm run dev

# Run full test suite
npm test
```

---

## 🔒 Security & Middleware Features

- **JWT Authentication & RBAC**: Enforces role access (`admin`, `teacher`, `student`, `parent`).
- **Sliding-Window Rate Limiter**: Configured with standard headers (`RateLimit-Limit`, `RateLimit-Remaining`).
- **HTTP Header Protection**: Enforced via `helmet`.
- **CORS Support**: Cross-origin policy supporting Flutter web, desktop, and mobile targets.
- **Input Validation**: Centralized validation schema with intelligent parameter aliasing.

---

## 🧪 Testing

All 36 integration test suites run with Node's native test runner (`node --test`):
```bash
npm test
```
