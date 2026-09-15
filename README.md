# 📱 SMS Mitra — Enterprise Mobile SMS Gateway & Dispatch System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express-5.x-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)
[![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)
[![Firebase FCM](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_2.6-blue?style=for-the-badge)](https://riverpod.dev)

**SMS Mitra** is an enterprise-grade, cost-effective SMS Gateway platform that transforms physical Android smartphones into powerful outbound SMS dispatch engines. It eliminates costly third-party SMS aggregator fees by routing cloud dispatch tasks through your local dual-SIM cellular subscriptions with automated quota management, real-time status reporting, and background resilience.

---

## 📑 Table of Contents

1. [Architecture Overview](#-architecture-overview)
2. [Key Features](#-key-features)
3. [Scheduled SMS & Timeline Dispatch Engine](#-scheduled-sms--timeline-dispatch-engine)
4. [Project Structure](#-project-structure)
5. [Prerequisites](#-prerequisites)
6. [Backend Server Setup](#-backend-server-setup)
7. [Flutter Client App Setup](#-flutter-client-app-setup)
8. [Android Device & Permissions Guide](#-android-device--permissions-guide)
9. [Testing & Code Quality](#-testing--code-quality)
10. [API & Dispatch Endpoints](#-api--dispatch-endpoints)
11. [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## 🏗 Architecture Overview

The system operates via a decoupled client-server architecture:

```mermaid
graph TD
    Client[Web/Admin App / Backend APIs] -->|POST /api/sms/send or /schedules| Server[SMS Mitra Node.js Server]
    Server -->|Store SMS Log & Schedules| DB[(MySQL Database)]
    Server -->|Cron Scheduler Daemon (20s)| Scheduler[Background Dispatcher]
    Scheduler -->|FCM High-Priority Push| FlutterApp[SMS Mitra Android Gateway App]
    Server -->|WebSocket Real-time Broadcast| FlutterApp
    
    subgraph Android Device Hardware
        FlutterApp -->|MethodChannel| NativeTelephony[Android SmsManager]
        NativeTelephony -->|SIM Slot 1 / SIM Slot 2| Carrier[Cellular Telecom Network]
    end
    
    Carrier -->|SMS Delivery Receipt| NativeTelephony
    NativeTelephony -->|Status Callback| FlutterApp
    FlutterApp -->|POST /api/sms/update-status| Server
    Server -->|Broadcast Status Update| Client
```

1. **Cloud API & Schedule Dispatch**: Trigger instant SMS dispatches or schedule future outbound campaigns with recipient, custom gateway SIM, and precise dispatch timestamps.
2. **Automated Scheduler Daemon**: High-reliability background cron running every 20 seconds with atomic status locking (`pending` $\rightarrow$ `processing` $\rightarrow$ `completed`), automatic SIM routing, and FCM push wakeup.
3. **Native Multi-SIM Carrier Dispatch**: Flutter application invokes native Android `SmsManager` across dual-SIM hardware slots with slot priority routing.
4. **Real-Time Reconciliation & Timeline**: Live delivery receipts and schedule status changes sync via WebSockets and are displayed in an interactive timeline with optimistic updates.

---

## ✨ Key Features

- ⏰ **Scheduled SMS & Timeline Engine**: Schedule outbound SMS messages for any future date & time with auto-priority SIM routing, full editing, and instant cancellation.
- 📅 **Google Calendar Style Agenda View**: Date-grouped timeline with intuitive day headers (*Today*, *Tomorrow*, *Calendar Dates*), active SIM carrier badges, and live per-second countdown badges (`59s -> 58s -> 57s`).
- 💥 **Realistic 12-Shard Glass Shatter Animations**:
  - **Cancel Shatter**: Card breaks into 12 polygon glass shards with realistic trajectory physics, angular spin, gravity arcs, and glowing 🔴 **Crimson Red fracture lines**.
  - **Dispatch Shatter**: When an SMS reaches dispatch time or gets processed, it shatters with glowing 🟢 **Emerald Green fracture lines** before smoothly collapsing vertical space (`SizeTransition`).
  - **Persistent Optimistic State**: Departed cards never pop back onto the *Upcoming* tab, even during background polling syncs.
- 📐 **Compact Summary Statistics**: Space-optimized top stat cards (*Upcoming*, *Completed*, *Cancelled*) with smooth number transitions (`AnimatedSwitcher`).
- 📶 **Multi-SIM Support & Dynamic Priority**: Auto-detects physical SIM cards, carrier names, and slot IDs with drag-and-drop priority reordering.
- ⚡ **Dual Dispatch Channels**: High-priority Firebase Cloud Messaging (FCM) for background wakeup + low-latency WebSockets for instant foreground sync.
- 📊 **Strict Quota & Limit Enforcement**: Configure per-SIM daily or monthly dispatch limits (e.g. 100/day or unlimited) with real-time UI warning badges.
- 📑 **PDF Export & Detailed Analytics**: Filter SMS history by date range, SIM carrier, or status, and generate formatted PDF reports ready for export.
- 🛡 **Robust Error Handling & Auto-Retry**: Typed domain exceptions, transient error retry interceptor with exponential backoff, and sanitized token logging.
- 📴 **Offline-First Resilience**: Local caching via Hive and encrypted credential storage via `flutter_secure_storage`.
- 🔋 **Background Execution Reliability**: Built-in system battery optimization bypass and Google Play Protect guidance.

---

## ⏰ Scheduled SMS & Timeline Dispatch Engine

The scheduling module provides an end-to-end client-server infrastructure for precision outbound SMS delivery:

### 1. Server-Side Scheduler Daemon (`server/utils/scheduler.js`)
- Runs every **20 seconds** via `node-cron`.
- Uses atomic SQL updates (`UPDATE ScheduledSms SET status = 'processing' WHERE ... AND status = 'scheduled'`) to prevent duplicate dispatches across server clusters.
- Resolves recipient details, validates target SIM or selects top-priority active SIM.
- Dispatches messages via FCM high-priority push payload and broadcasts WebSocket updates to connected clients.

### 2. Interactive Calendar Timeline & Transitions (`sms_app/lib/features/schedules/`)
- **Space-Making Entry**: When a new schedule is created, surrounding cards part smoothly to open space before the new card pops in.
- **Live Countdown Badges**: Dedicated ticking sub-second ticker displaying exact countdowns (`In 45s`, `In 12m 30s`, `Today at 06:30 PM`).
- **12-Shard Geometric Shatter Physics**: Custom polygon shard clipper with outward velocity vectors ($dx$, $dy$), angular rotation, and gravity parabolic drops.
- **Immediate Bottom Sheet Dismissal**: Create/Edit bottom sheets dismiss immediately upon submission so the user can watch the timeline insertion and animation in real time.

---

## 📂 Project Structure

```
SMSMitra/
├── server/                          # Node.js Express REST API & WebSocket Server
│   ├── config/                      # Database (Sequelize) & Firebase Admin Config
│   ├── controllers/                 # Auth, SMS, Schedules, Devices, and Report Controllers
│   ├── models/                      # Sequelize Models (User, ScheduledSms, SMSLog, Device, etc.)
│   ├── routes/                      # Express Route Definitions (auth, sms, schedules, reports)
│   ├── utils/                       # Scheduler cron daemon, FCM dispatcher, and helpers
│   ├── index.js                     # Application Entry Point & Socket.IO initialization
│   ├── package.json
│   └── .env.example
│
└── sms_app/                         # Flutter Client Gateway Application
    ├── lib/
    │   ├── core/                    # Constants, App Tokens, Errors, Helpers, Theme, Routes
    │   │   ├── constants/           # ApiConstants, StorageKeys
    │   │   ├── errors/              # Domain Exceptions (AppException, NetworkException, etc.)
    │   │   ├── helpers/             # ValidationHelper, MessageHelper, DialogHelper
    │   │   ├── routes/              # GoRouter configuration & route guards
    │   │   └── theme/               # Design tokens (AppSpacing, AppRadius, AppColors)
    │   ├── data/                    # Data Layer
    │   │   ├── cache/               # Hive Caching & CacheManager
    │   │   ├── models/              # UserModel, ScheduledSmsModel, SimModel, SmsLogModel
    │   │   ├── providers/           # Riverpod Service Providers (DI Layer)
    │   │   ├── repositories/        # AuthRepository & Repository Interfaces
    │   │   └── services/            # ApiService, ScheduledSmsService, SimService, SmsService
    │   ├── features/                # Presentation Layer (Feature-Driven)
    │   │   ├── auth/                # Login, Register screens & AuthNotifier
    │   │   ├── home/                # Dashboard, Stats, Quick Send & HomeNotifier
    │   │   ├── profile/             # Profile management & Logout
    │   │   ├── reports/             # Filterable reports, logs table & PDF export
    │   │   ├── schedules/           # Google Calendar Timeline, Shatter Animations & SchedulesNotifier
    │   │   │   ├── widgets/         # ScheduleSmsSheet, Calendar Day Sections, AnimatedTimelineItem
    │   │   ├── settings/            # SIM priority, limits, permissions & theme
    │   │   └── splash/              # Animated Splash & Session routing
    │   ├── shared/                  # Reusable UI Design System Components
    │   │   └── widgets/             # StatCard (Compact & Full), StatusBadge, EmptyState, etc.
    │   └── main.dart                # Global error handlers & FCM background receiver
    ├── test/                        # Automated Unit, Widget & DI Test Suite (54+ Tests)
    ├── pubspec.yaml
    └── analysis_options.yaml        # Strict Analyzer & Production Linter Rules
```

---

## 📋 Prerequisites

Before running the project, ensure you have the following installed:

1. **Flutter SDK**: `v3.24.0` or higher ([Download Flutter](https://flutter.dev/docs/get-started/install))
2. **Dart SDK**: `v3.5.0` or higher
3. **Node.js**: `v18.x` or higher ([Download Node.js](https://nodejs.org))
4. **MySQL Database**: `v8.x` running locally or on a cloud instance
5. **Android Device**: Physical Android smartphone running Android 8.0 (API 26) or higher with active SIM cards inserted. *(Note: Telephony/SMS features require real SIM hardware and will not work on standard emulators).*
6. **Firebase Account**: A Firebase project configured for Cloud Messaging.

---

## 🚀 Backend Server Setup

### 1. Install Dependencies
```bash
cd server
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and fill in your details:
```bash
cp .env.example .env
```

Edit `server/.env`:
```env
PORT=5000
NODE_ENV=development

# MySQL Database Configuration
DB_HOST=localhost
DB_NAME=smsmitra_db
DB_USER=root
DB_PASSWORD=your_mysql_password

# JWT Authentication
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRE=30d
```

### 3. Setup Firebase Admin SDK
1. Go to **Firebase Console** -> **Project Settings** -> **Service Accounts**.
2. Click **Generate new private key** and download the JSON file.
3. Rename the file to `serviceAccountKey.json` and place it in the `server/` root directory:
   ```
   server/serviceAccountKey.json
   ```

### 4. Create MySQL Database
Ensure your MySQL instance is running, then create the database:
```sql
CREATE DATABASE smsmitra_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 5. Start the Server
```bash
# Development mode with hot-reload
npm run dev

# Or production mode
npm start
```
The server will automatically synchronize Sequelize tables (including `ScheduledSms`), start the 20-second background scheduler daemon, and listen on `http://localhost:5000`.

---

## 📱 Flutter Client App Setup

### 1. Configure Backend Server URL
Open [lib/core/constants/api_constants.dart](file:///e:/Allysoft%20solutions/SMSMitra/sms_app/lib/core/constants/api_constants.dart) and update the base URL to your server's IP address (or domain):

```dart
class ApiConstants {
  // Replace with your local machine's IP address (e.g. http://192.168.1.100:5000/smsmitra/v1)
  static const String baseUrl = 'http://YOUR_LOCAL_IP:5000/smsmitra/v1';
  ...
}
```
> [!TIP]
> Do NOT use `localhost` or `127.0.0.1` when running on a physical Android phone, as the phone cannot resolve your computer's loopback interface. Use your computer's local Wi-Fi IP address (e.g., `192.168.x.x`).

### 2. Install Flutter Dependencies
```bash
cd sms_app
flutter pub get
```

### 3. Generate Hive Adapters
Run `build_runner` to generate type adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Connect Physical Android Device & Run
Enable **Developer Options** and **USB Debugging** on your Android smartphone, plug it in via USB, and run:
```bash
# Check connected devices
flutter devices

# Run the app in debug mode
flutter run -d <DEVICE_ID>
```

---

## ⚙️ Android Device & Permissions Guide

To guarantee 100% reliable background SMS dispatching on modern Android OS versions, execute these quick configuration steps on your gateway device:

### 1. Grant Runtime Permissions
When launching the app for the first time, allow all requested permissions:
- **SMS Permissions**: `SEND_SMS`, `READ_SMS`, `RECEIVE_SMS` (Required for dispatch).
- **Phone State Permission**: `READ_PHONE_STATE` (Required to detect SIM slot indices and carrier info).
- **Notifications**: Required for FCM foreground and background triggers.

### 2. Disable Battery Optimization (Background Alive)
Manufacturers (Xiaomi, Samsung, Oppo, Vivo, OnePlus) aggressively terminate background processes.
1. Open **Settings** -> **Battery** -> **App Battery Usage** / **Battery Optimization**.
2. Locate **SMS Mitra** and select **"Unrestricted" / "Don't Optimize"**.
3. In app, go to **Settings** screen and verify **Battery Saver** shows a green checkmark.

### 3. Disable Google Play Protect Scanning (For Sideloaded Gateway Builds)
Google Play Protect flags sideloaded APKs requesting `SEND_SMS` permissions and may suppress background workers:
1. Open **Google Play Store**.
2. Tap your profile icon (top-right) -> **Play Protect**.
3. Tap **Settings (Gear Icon)** in top-right.
4. Turn **OFF** *"Scan apps with Play Protect"* and *"Improve harmful app detection"*.

---

## 🧪 Testing & Code Quality

The codebase enforces strict static analysis (`strict-casts`, `strict-inference`, `strict-raw-types`) and includes a comprehensive automated test suite.

### Run Static Analysis
```bash
cd sms_app
flutter analyze
```
*Expected output: `No issues found!` (0 errors, 0 warnings).*

### Run Automated Unit & Widget Test Suite
```bash
cd sms_app
flutter test
```
*Test coverage covers 54+ automated tests across:*
- **Schedules & Timeline**: Creation, optimistic updates, date/time pickers, 12-shard destruction animations, cancellation & countdown badges.
- **Error Handling**: Domain exception mappings, Dio error interceptors, HTTP status code translation.
- **Navigation**: Declarative GoRouter auth guards, deep linking, custom 404 screens, RouteObservers.
- **Validation**: RFC regex email, 10-digit mobile formatting with international prefixes, SMS limit boundaries.
- **Widget Lifecycle & Safety**: Memory leak safety, focus nodes, stream subscriptions, and unmount checks.
- **Design Tokens & UI**: Reusable compact `StatCard`, `StatusBadge`, `EmptyStateWidget`, `ConfirmBottomSheet`.
- **Dependency Injection**: Riverpod service provider overrides and mock isolation.

---

## 🔌 API & Dispatch Endpoints

### Authentication
- `POST /smsmitra/v1/auth/register` — Register a new organization/user account.
- `POST /smsmitra/v1/auth/login` — Authenticate and retrieve JWT token.
- `POST /smsmitra/v1/auth/update-token` — Update device FCM push token.
- `POST /smsmitra/v1/auth/update-profile` — Update account profile details.

### Scheduled SMS
- `POST /smsmitra/v1/schedules` — Schedule a new SMS message with dispatch timestamp and target SIM.
- `GET /smsmitra/v1/schedules?userId=:id&status=:status` — Fetch user's scheduled messages and summary counts.
- `PUT /smsmitra/v1/schedules/:id` — Edit an upcoming scheduled message (phone, text, SIM, time).
- `DELETE /smsmitra/v1/schedules/:id` — Cancel an upcoming scheduled SMS.

### Frequently Sending / Recurring SMS
- `POST /smsmitra/v1/frequent` — Create a recurring rule (Daily, Alternate Day, Weekly, Monthly, Custom) with time and SIM selection.
- `GET /smsmitra/v1/frequent?userId=:id&status=:status` — Fetch recurring SMS rules and execution stats.
- `PUT /smsmitra/v1/frequent/:id` — Update recurring SMS rule parameters.
- `PATCH /smsmitra/v1/frequent/:id/toggle` — Instantly switch rule between `active` and `paused`.
- `DELETE /smsmitra/v1/frequent/:id` — Delete recurring rule with realistic 12-shard glass shatter animation.

### SIM & Gateway Operations
- `POST /smsmitra/v1/sms/sync-sims` — Sync detected physical SIM cards and configured quota limits.
- `POST /smsmitra/v1/sms/create-log` — Create manual or external SMS dispatch log.
- `POST /smsmitra/v1/sms/update-status` — Update SMS dispatch status (`sent`, `failed`, `pending`).

### Reports & Analytics
- `GET /smsmitra/v1/reports/stats?userId=:id` — Fetch daily summary counts (Sent Today, Failed Today).
- `GET /smsmitra/v1/reports/detailed` — Fetch filtered logs (by `startDate`, `endDate`, `simId`, `channel`).

---

## ❓ Troubleshooting & FAQs

#### Q1: Why are SMS messages not sending in the background?
- **Battery Optimization**: Ensure battery optimization is disabled ("Unrestricted") for SMS Mitra.
- **Play Protect**: Disable Google Play Protect scanning on the phone as explained above.
- **FCM Setup**: Verify that your `google-services.json` on the client and `serviceAccountKey.json` on the server belong to the exact same Firebase project.

#### Q2: The app shows `Connection timeout` or `NetworkException`.
- Verify your smartphone and backend computer are on the same local Wi-Fi network.
- Confirm that your computer's firewall allows incoming connections on port `5000`.
- Double-check the IP address specified in `lib/core/constants/api_constants.dart`.

#### Q3: SIM cards are not detected.
- Verify the device has active SIM cards inserted and cellular network bars are visible.
- Ensure the **Phone State** (`READ_PHONE_STATE`) permission is granted in Android App Settings.

---

## 📄 License

This project is licensed under the [ISC License](LICENSE).

Developed by the **Ally Soft Solutions**.