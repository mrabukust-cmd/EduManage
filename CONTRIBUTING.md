# Contributing to EduManage

Thank you for your interest in contributing to **EduManage**! This document provides guidelines and instructions for submitting contributions, reporting bugs, and maintaining high code quality across both the Flutter client and Node.js backend.

---

## 1. Development Environment Setup

### Prerequisites
- **Flutter SDK**: 3.x stable channel ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: Bundled with Flutter
- **Node.js**: >= 20.x ([Install Node.js](https://nodejs.org/))
- **Git**: Configured with your name and verified email

### Quick Start
```bash
# 1. Clone repository
git clone https://github.com/mrabukust-cmd/EduManage.git
cd EduManage

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Backend dependencies
cd edumanage-backend
npm install
cd ..
```

---

## 2. Git Branching & Commit Message Guidelines

We enforce the [Conventional Commits](https://www.conventionalcommits.org/) specification for clear, readable, and automated changelogs.

### Commit Format
```text
<type>(<scope>): <subject>
```

### Commit Types
- `feat`: A new feature or capability
- `fix`: A bug fix
- `docs`: Documentation updates (README, ARCHITECTURE, API docs)
- `style`: Formatting, missing semi-colons, whitespace changes
- `refactor`: Code restructuring without functional behavior changes
- `perf`: Performance optimizations
- `test`: Adding or modifying automated test suites
- `chore`: Maintenance tasks, dependency bumps, tooling configuration
- `ci`: CI/CD pipeline and GitHub Actions adjustments

### Example
```bash
git commit -m "feat(attendance): add weekly attendance summary chart widget"
git commit -m "fix(auth): handle expired token refresh gracefully"
git commit -m "test(api): add contract tests for student results payload"
```

---

## 3. Code Standards & Architecture Guidelines

### Flutter Frontend
1. **State Management**: Use **Riverpod** providers (`FutureProvider`, `StateNotifierProvider`, `NotifierProvider`). Avoid monolithic state objects.
2. **Clean Architecture**: Separate concerns cleanly into:
   - `features/`: Presentation layer, UI screens, feature-scoped widgets
   - `core/`: Shared theme, constants, routers, utilities, and reusable components
   - `data/`: Repositories, models, and data sources (REST API & Firebase)
3. **Immutability**: Ensure models use `const` constructors where applicable and provide `copyWith` and `toMap` serialization methods.
4. **Formatting**: Run `dart format .` before staging changes. Ensure `flutter analyze` passes with zero fatal issues.

### Node.js Backend
1. **Modular Routes & Controllers**: Keep route definitions thin and delegate business logic to controllers/services.
2. **Middleware First**: Use centralized middlewares for authentication (`authMiddleware`), validation (`validateBody`), and rate limiting.
3. **Response Envelope**: Follow the standard JSON response envelope:
   ```json
   {
     "success": true,
     "message": "Operation description",
     "data": {}
   }
   ```
4. **Error Handling**: Throw centralized `AppError` instances or use `next(err)` to ensure unified error formatting.

---

## 4. Testing Requirements

All submissions must include automated tests verifying new or changed functionality.

```bash
# Run Flutter tests
flutter test

# Run Backend tests
cd edumanage-backend && npm test
```

A Pull Request must pass all tests before merge approval.

---

## 5. Pull Request Workflow

1. Fork the repository and create your branch from `main`:
   ```bash
   git checkout -b feature/my-feature-name
   ```
2. Make your commits adhering to conventional commit style.
3. Ensure all tests pass locally.
4. Push your branch and open a Pull Request against `main`.
5. Describe the changes, motivation, and verification steps in the PR description.
