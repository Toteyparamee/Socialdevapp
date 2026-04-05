# Socialdev App - Project Structure

## Entry Point

```
main.dart
  └─ CommunityReportApp (Provider wrapper)
     └─ AuthGate (ตรวจสอบสถานะ login)
        ├─ ยังไม่ login → WelcomeScreen
        └─ login แล้ว → HomeScreen
```

---

## Screens (7 ไฟล์)

| ไฟล์ | Widget | หน้าที่ |
|------|--------|---------|
| `welcome_screen.dart` | `WelcomeScreen` | Onboarding carousel 4 หน้า |
| `login_screen.dart` | `LoginScreen` | เลือก role + ฟอร์ม login (นักเรียนใช้ Gmail) + Login with Google |
| `register_screen.dart` | `RegisterScreen` | สมัครสมาชิก |
| `map_screen.dart` | `MapHomeScreen` | Google Maps + markers ปัญหาชุมชน |
| `problem_detail_screen.dart` | `ProblemDetailScreen` | รายละเอียดปัญหา |
| `student/student_screen.dart` | `StudentScreen` | Dashboard นักเรียน + Bottom Navigation |
| `student/school_activities_screen.dart` | `SchoolActivitiesScreen` | รายการกิจกรรมโรงเรียน + หน้ารายละเอียดกิจกรรม |

---

## Models (1 ไฟล์)

**`models/problem_report.dart`**

- `ProblemReport` - ข้อมูลปัญหา (id, title, description, location, status, ...)
- `ProblemCategory` enum: flood, trash, traffic, infrastructure, other
- `ProblemStatus` enum: pending, inProgress, resolved
- `ProblemSource` enum: user, government, urgent
- `sampleProblems` - ข้อมูลตัวอย่าง 5 รายการ

---

## Services (1 ไฟล์)

**`services/auth_service.dart`**

- `AuthService` (ChangeNotifier) - จัดการ login/logout เชื่อมต่อ Backend API
- `login()` - POST /auth/login (username + password)
- `register()` - POST /auth/register (username + email + password + role)
- `loginWithGoogle()` - Auth0 + POST /auth/google (access_token)
- `AuthException` - custom exception class
- เก็บ session ใน SharedPreferences (token, username, role, avatarUrl)
- Properties: isLoggedIn, username, role, token, avatarUrl, isLoading, authHeaders

---

## Theme (1 ไฟล์)

**`theme/app_theme.dart`**

- `AppTheme` - สี, gradient, border radius, shadow, ThemeData
- Primary: #4A90D9 | Accent colors | Status colors | Marker colors

---

## Widgets (3 ไฟล์)

| ไฟล์ | Widget | หน้าที่ |
|------|--------|---------|
| `problem_bottom_sheet.dart` | `ProblemBottomSheet` | Preview card บนแผนที่ |
| `filter_panel.dart` | `FilterPanel` | กรองหมวดหมู่ปัญหา |
| `add_problem_sheet.dart` | `AddProblemSheet` | ฟอร์มแจ้งปัญหาใหม่ |

---

## Navigation Flow

```
WelcomeScreen (onboarding 4 หน้า)
  └─ [ข้าม / ถัดไป]
     └─ LoginScreen
        ├─ Page 1: เลือก Role (นักเรียน / ครู / ทั่วไป)
        └─ Page 2: กรอก Gmail + Password (นักเรียน) / อีเมล (ครู) / เบอร์โทรหรืออีเมล (ทั่วไป) | Login with Google (Auth0)
           └─ StudentScreen (Dashboard นักเรียน)
              ├─ Tab 0: MapHomeScreen (แผนที่)
              │  ├─ แตะ marker → ProblemBottomSheet
              │  │  └─ ดูเพิ่ม → ProblemDetailScreen
              │  └─ ปุ่ม Filter → FilterPanel
              ├─ Tab 1: ActivityTab (กิจกรรม)
              │  └─ เมนู กิจกรรมโรงเรียน → SchoolActivitiesScreen
              │     └─ แตะ card กิจกรรม → ActivityDetailScreen (รายละเอียด + ลงทะเบียน)
              └─ Tab 2: ProfileTab (โปรไฟล์)
                 └─ Logout → กลับ WelcomeScreen
```

---

## Auth Config (Flutter ↔ Auth0 ↔ Backend)

| ค่า | ที่อยู่ |
|-----|--------|
| Auth0 Domain | `dev-p6m40iaxhz0i543y.us.auth0.com` |
| Auth0 Client ID | `tiHEUCuLCaE03SyInMkyRVLPgxZopy7s` |
| Redirect URI | `com.socialdev.app://login-callback` |
| Backend URL | `http://10.0.2.2:8080` (Android) / `http://localhost:8080` (iOS) |
| Android config | `build.gradle.kts` → `appAuthRedirectScheme` |
| iOS config | `Info.plist` → `CFBundleURLSchemes` |

---

## State Management

- **Provider**: `AuthService` (ChangeNotifier) - สถานะ login ทั้งแอป
- **Local State**: StatefulWidget + setState() - UI state ภายใน screen
- **Persistence**: SharedPreferences - เก็บ session + JWT token

---

## Dependencies หลัก

| Package | ใช้ทำอะไร |
|---------|-----------|
| `provider` | State management |
| `google_maps_flutter` | แผนที่ + markers |
| `geolocator` | ตำแหน่งปัจจุบัน |
| `shared_preferences` | เก็บ session |
| `image_picker` | เลือกรูปจากกล้อง/แกลเลอรี |
| `http` | HTTP client เรียก Backend API |
| `flutter_appauth` | Auth0 / Google OAuth login |

---

## File Tree

```
lib/
├── main.dart
├── models/
│   └── problem_report.dart
├── screens/
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── map_screen.dart
│   ├── problem_detail_screen.dart
│   └── student/
│       ├── student_screen.dart
│       └── school_activities_screen.dart
├── services/
│   └── auth_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── problem_bottom_sheet.dart
    ├── filter_panel.dart
    └── add_problem_sheet.dart
```

**รวมทั้งหมด: 14 ไฟล์ .dart**

---

# Backend - Login Service (Go Fiber v3)

## Entry Point

```
server/login/main.go
  └─ Load .env
  └─ Connect SQLite database
  └─ Auto migrate User model
  └─ Start Fiber server (:8080)
```

---

## โครงสร้างโฟลเดอร์

```
server/login/
├── main.go                 # Entry point
├── go.mod / go.sum         # Dependencies
├── .env.example            # ตัวอย่าง environment variables
├── .gitignore
├── config/
│   ├── database.go         # GORM + SQLite connection
│   ├── auth0.go            # Auth0 config (domain, client_id)
│   └── jwt.go              # JWT secret
├── models/
│   └── user.go             # User model + AutoMigrate
├── handlers/
│   ├── auth.go             # Register, Login, GoogleLogin handlers
│   └── user.go             # GetProfile, UpdateProfile handlers
├── middleware/
│   └── jwt.go              # JWT authentication middleware
└── routes/
    └── routes.go           # Route setup (auth + user groups)
```

---

## API Endpoints

### Public (ไม่ต้อง login)

| Method | Path | หน้าที่ |
|--------|------|---------|
| GET | `/health` | Health check |
| POST | `/auth/register` | สมัครสมาชิก (username + email + password + role) |
| POST | `/auth/login` | Login ธรรมดา (username + password) |
| POST | `/auth/google` | Login ด้วย Google ผ่าน Auth0 (access_token + role) |

### Protected (ต้องส่ง JWT ใน header)

| Method | Path | หน้าที่ |
|--------|------|---------|
| GET | `/user/profile` | ดึงข้อมูลโปรไฟล์ |
| PUT | `/user/profile` | อัพเดทโปรไฟล์ (username, role) |

---

## Auth Flow

```
[แบบธรรมดา]
Flutter → POST /auth/register → สร้าง user + hash password → JWT
Flutter → POST /auth/login    → ตรวจ password (bcrypt)     → JWT

[แบบ Google]
Flutter → Auth0 → Google → ได้ access_token
Flutter → POST /auth/google → Server verify กับ Auth0 /userinfo
       → สร้าง/อัพเดท user อัตโนมัติ → JWT

ทั้ง 2 แบบได้ JWT เหมือนกัน → ใช้เรียก API protected routes
```

---

## User Model

| Field | Type | หมายเหตุ |
|-------|------|----------|
| id | uint | Primary key |
| username | string | Unique |
| email | string | Unique |
| password | string | bcrypt hash (เฉพาะ local) |
| role | string | นักเรียน / ครู / ทั่วไป |
| provider | string | `local` หรือ `google` |
| google_id | string | Google sub ID |
| avatar_url | string | รูปโปรไฟล์จาก Google |
| created_at | time | |
| updated_at | time | |

---

## Dependencies (Go)

| Package | ใช้ทำอะไร |
|---------|-----------|
| `gofiber/fiber/v3` | Web framework |
| `golang-jwt/jwt/v5` | สร้าง/verify JWT |
| `gorm.io/gorm` | ORM |
| `gorm.io/driver/sqlite` | SQLite database |
| `golang.org/x/crypto` | bcrypt hash password |
| `joho/godotenv` | Load .env file |

---

# Database Schema (PostgreSQL)

**`server/schema/schema.sql`**

## Tables

| Table | หน้าที่ |
|-------|---------|
| `users` | ข้อมูลผู้ใช้ (username, email, password, role, provider, google_id, avatar_url) |
| `problem_reports` | รายงานปัญหาชุมชน + PostGIS location |
| `problem_images` | รูปภาพปัญหา (1 ปัญหามีได้หลายรูป) |
| `school_activities` | กิจกรรมโรงเรียน |
| `activity_registrations` | ลงทะเบียนกิจกรรม (user ↔ activity) |

## Enum Types

| Type | ค่า |
|------|-----|
| `user_role` | นักเรียน, ครู, ทั่วไป |
| `auth_provider` | local, google |
| `problem_category` | flood, trash, traffic, infrastructure, other |
| `problem_status` | pending, in_progress, resolved |
| `problem_source` | user, government, urgent |

## Extensions

- `uuid-ossp` - สร้าง UUID
- `postgis` - รองรับ location (lat/lng)