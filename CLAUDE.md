# CLAUDE.md

## Project Overview

This is **Socialdev App** - a community problem reporting and school activity management application.

Read [README.md](README.md) for full architecture details, data flow, API endpoints, and database schema.

## Tech Stack

- **Frontend:** Flutter (Dart) + Provider + Google Maps + Auth0
- **Backend:** Go Fiber v3 + GORM + JWT + bcrypt
- **Database:** PostgreSQL + PostGIS + uuid-ossp
- **Auth:** Auth0 (Google OAuth2) + Local (email/password)

## Project Structure

```
lib/                    # Flutter frontend (14 .dart files)
├── main.dart           # Entry point → AuthGate
├── models/             # Data models (ProblemReport)
├── screens/            # UI screens (7 files)
├── services/           # AuthService (API + state)
├── theme/              # AppTheme
└── widgets/            # Reusable UI components

server/login/           # Go backend
├── main.go             # Entry point (:8080)
├── config/             # DB, Auth0, JWT config
├── models/             # User model (GORM)
├── handlers/           # auth.go, user.go
├── middleware/          # JWT middleware
└── routes/             # Route definitions

server/schema/          # PostgreSQL schema
└── schema.sql
```

## Key Commands

```bash
# Frontend (Flutter)
flutter run

# Backend (Go)
cd server/login && go run main.go
```

## API Base URLs

- Android emulator: `http://10.0.2.2:8080`
- iOS simulator: `http://localhost:8080`

## Auth Config

- Auth0 Domain: `dev-p6m40iaxhz0i543y.us.auth0.com`
- Redirect URI: `com.socialdev.app://login-callback`
