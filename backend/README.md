# EduManage REST API Backend

A clean, modular REST API server built with Node.js and Express powering the **EduManage** School Management System.

## Architecture

The backend follows a strict 3-tier architecture:
1. **Transport / Presentation Layer**:
   - `src/middleware/`: JWT authentication, Role-Based Access Control (RBAC), validation, logging, and error handling.
   - `src/modules/*/routes.js`: Versioned API routing (`/api/v1/*`).
   - `src/modules/*/controller.js`: Request handling and status code mapping.
2. **Business / Domain Layer**:
   - `src/modules/*/service.js`: Domain validation, calculation logic, security checks.
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

## Health Check
- `GET /api/v1/health`
