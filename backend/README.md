# EduManage REST API Backend

A clean, modular REST API server built with Node.js and Express powering the **EduManage** School Management System.

## Architecture

The backend follows a strict 3-tier architecture:
1. **Transport / Presentation Layer**:
   - `src/middleware/`: JWT authentication, Role-Based Access Control (RBAC), sliding-window rate limiting, input validation, request logging, and unified error handling.
   - `src/modules/*/routes.js`: Versioned API routing (`/api/v1/*`).
   - `src/modules/*/controller.js`: Request handling, CSV export streaming, and status code mapping.
2. **Business / Domain Layer**:
   - `src/modules/*/service.js`: Domain validation, calculation logic, and security checks.
3. **Data Access / Persistence Layer**:
   - `src/db/`: Data store models, repositories, and initial schema seeds.

## Getting Started

### Prerequisites
- Node.js >= 18.0.0
- npm >= 9.0.0

### Installation
```bash
cd backend
npm install
```

### Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

### Running the Server
```bash
# Production mode
npm start

# Development mode (with auto-reload)
npm run dev

# Run tests
npm test
```

## Security & Rate Limiting
- Built-in sliding-window rate limiting (`RateLimit-Limit`, `RateLimit-Remaining`) protects endpoints against brute-force and DoS attacks.
- Standard HTTP security headers enabled via `helmet`.
- CORS policies configured for authorized cross-origin clients.

## Key Endpoints
- Health: `GET /api/v1/health`
- Auth: `POST /api/v1/auth/login`, `GET /api/v1/auth/me`
- Export: `GET /api/v1/export/students`, `GET /api/v1/export/fees`
- Full API reference in [docs/API_DOCUMENTATION.md](../docs/API_DOCUMENTATION.md).
