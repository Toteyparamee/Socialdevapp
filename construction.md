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

## Screens (5 ไฟล์)

| ไฟล์ | Widget | หน้าที่ |
|------|--------|---------|
| `welcome_screen.dart` | `WelcomeScreen` | Onboarding carousel 4 หน้า |
| `login_screen.dart` | `LoginScreen` | เลือก role + ฟอร์ม login |
| `home_screen.dart` | `HomeScreen` | หน้าหลัก + Bottom Navigation 3 แท็บ |
| `map_screen.dart` | `MapHomeScreen` | Google Maps + markers ปัญหาชุมชน |
| `problem_detail_screen.dart` | `ProblemDetailScreen` | รายละเอียดปัญหา |

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

- `AuthService` (ChangeNotifier) - จัดการ login/logout
- เก็บ session ใน SharedPreferences
- Properties: isLoggedIn, username, role, isLoading

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
        └─ Page 2: กรอก Username + Password
           └─ HomeScreen
              ├─ Tab 0: MapHomeScreen (แผนที่)
              │  ├─ แตะ marker → ProblemBottomSheet
              │  │  └─ ดูเพิ่ม → ProblemDetailScreen
              │  └─ ปุ่ม Filter → FilterPanel
              ├─ Tab 1: ActivityTab (กิจกรรม)
              └─ Tab 2: ProfileTab (โปรไฟล์)
                 └─ Logout → กลับ WelcomeScreen
```

---

## State Management

- **Provider**: `AuthService` (ChangeNotifier) - สถานะ login ทั้งแอป
- **Local State**: StatefulWidget + setState() - UI state ภายใน screen
- **Persistence**: SharedPreferences - เก็บ session

---

## Dependencies หลัก

| Package | ใช้ทำอะไร |
|---------|-----------|
| `provider` | State management |
| `google_maps_flutter` | แผนที่ + markers |
| `geolocator` | ตำแหน่งปัจจุบัน |
| `shared_preferences` | เก็บ session |
| `image_picker` | เลือกรูปจากกล้อง/แกลเลอรี |
| `http` | โหลดรูป marker |

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
│   ├── home_screen.dart
│   ├── map_screen.dart
│   └── problem_detail_screen.dart
├── services/
│   └── auth_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── problem_bottom_sheet.dart
    ├── filter_panel.dart
    └── add_problem_sheet.dart
```

**รวมทั้งหมด: 12 ไฟล์ .dart**
widget  (class ปู่)
  └─ StatefulWidget  (class แม่ - อยู่ใน Flutter framework)
       └─ LoginScreen  (class ลูก - อยู่ในไฟล์นี้ บรรทัด 10)