# 🏆 Professional Flutter Desktop Scoreboard Application

A modern, high-contrast, fully functional **Flutter Desktop Scoreboard Application** for Windows, macOS, Linux, and Web, powered by **Dart**, **SQLite (FFI)** for local data persistence, and **Google Cloud Firestore** for real-time cloud synchronization.

Built with **Material 3**, this scoreboard is specially engineered for large televisions, stadium monitors, gym projectors, and classroom displays.

---

## 📸 Overview & Architecture

```
flutter_scoreboard_app/
├── lib/
│   ├── models/                  # Immutable domain models (Team, FieldModel, ScoreHistory, AppSettings)
│   ├── database/                # SQLite FFI database helper, migrations, and transactional updates
│   ├── repositories/            # ScoreboardRepository coordinating SQLite, ranking, and Firestore sync
│   ├── providers/               # State management via Riverpod Notifier & AsyncNotifier
│   ├── services/                # Export/Import (CSV & JSON), Audio feedback, Firestore REST client
│   ├── animations/              # AnimatedScoreCounter, WinnerGlow, CelebrationParticlesOverlay
│   ├── widgets/                 # TeamTile, FieldColumn, OverallLeaderboard, QuickScoreButton, ThreeDTrophy
│   ├── screens/                 # ScoreboardScreen, PresentationScreen, AdminScreen, HistoryScreen
│   ├── utils/                   # RankCalculator (competition ties), ColorPalette, validators
│   └── main.dart                # Application entrypoint & Material 3 Dark theme
├── web/
│   └── three_trophy.html        # Interactive 3D Gold Trophy component powered by Three.js
├── firestore.rules              # Deployed Firestore security & schema validation rules
├── firebase.json                # Firebase configuration
├── test/
│   ├── unit_test.dart           # Automated tests for ranking, ties, SQLite, and CSV/JSON import/export
│   └── widget_test.dart         # Automated widget tests for TeamTile, FieldColumn, Leaderboard
└── pubspec.yaml                 # Dependencies and assets
```

---

## ✨ Key Features

### 1. Dual Field System: Field A & Field B
* Independent columns displaying assigned teams with designated field headers, leader indicators, and team counters.
* Responsive layout: displays side-by-side on wide desktop displays, and stacked gracefully on narrower viewports.
* Administrators can rename fields directly (e.g. "Court Alpha" / "Court Beta").
* Switchable view to **Overall Standings** comparing teams across all fields.

### 2. Six Standard Team Colors & Custom Teams
* Red (`#EF4444`)
* Blue (`#3B82F6`)
* Green (`#10B981`)
* Yellow (`#F59E0B`)
* Orange (`#F97316`)
* Purple (`#8B5CF6`)
* Dynamic contrast color computation so text and scores are instantly readable from 30+ feet away.
* Support for adding custom teams, renaming, editing colors, and assigning fields.

### 3. Click-to-Edit Interactive Score Tiles
* Click any team tile to open the quick-edit dialog.
* Quick-action buttons: `+1`, `+5`, `+10`, `-1`, `-5`, `-10`.
* Enter exact numerical values or add/subtract custom point increments.
* Visual preview showing previous score vs. projected score.
* Negative score prevention (unless explicitly enabled in Admin settings).
* Safety confirmation dialog before resetting a team's score.

### 4. Automatic Leaderboard Sorting & Rank Calculation
* Automatically places highest-scoring teams at the top.
* Standard competition ranking with deterministic tie-breaking (teams with equal points share the same rank badge `#1`, `#2`, etc.).
* Visual delta indicators show when a team moves up (green arrow) or down (red arrow).
* Leader highlight: First place team receives a glowing animated border and leader badge.

### 5. Smooth Visual Animations & 3D Visualizer
* **Animated Score Counter:** Smooth digit transition when scores change.
* **Winner Glow:** Pulsating golden aura for the tournament leader.
* **Celebration Confetti:** Realistic physics-based particle explosion when a team reaches the top.
* **3D Trophy Component:** Hardware-accelerated 3D rotating metallic trophy with fallback support and Three.js web visualizer (`web/three_trophy.html`).

### 6. Local SQLite Persistence + Firestore Cloud Sync
* **SQLite (sqflite_common_ffi):** 100% offline-first permanent local database. All teams, fields, settings, and score adjustments persist across restarts.
* **Audit Trail (score_history):** Every score adjustment records a timestamp, delta, previous score, new score, and optional reason.
* **Cloud Sync (Firestore):** Optional live synchronization to the dedicated Firebase project `scoreboard-app-live-9481`.

### 7. Live Scoreboard / Presentation Mode
* Full-screen presentation mode designed for TV screens and projectors.
* Hides administrative buttons to prevent accidental edits.
* Press **Escape** or click **Exit (Esc)** to leave presentation mode.

### 8. Import & Export
* Export full tournament backups to **JSON**.
* Export team rosters and scores to **CSV** (compatible with Excel and Google Sheets).
* Import from JSON or CSV with built-in validation.

---

## 🚀 Getting Started on Windows

### Prerequisites
* Flutter SDK (3.13+ or latest stable)
* Visual Studio 2022 / Build Tools with C++ workload (for Windows desktop executables)

### Running the Application

1. Clone or open the repository:
   ```powershell
   cd C:\Users\heinr\.gemini\antigravity\scratch\flutter_scoreboard_app
   ```

2. Fetch dependencies:
   ```powershell
   flutter pub get
   ```

3. Run the desktop application:
   ```powershell
   flutter run -d windows
   ```
   *(Or run on Chrome for web preview: `flutter run -d chrome`)*

---

## 🧪 Running Automated Tests

Run the test suite verifying unit logic, SQLite persistence, and UI rendering:

```powershell
flutter test
```

All 13 tests verify:
* Leaderboard sorting descending by score.
* Deterministic tie-handling (equal ranks for equal points).
* Rank delta calculation (up/down movement).
* SQLite default seeding and persistence.
* Transactional score updates and audit history logging.
* Field renaming.
* JSON and CSV serialization and deserialization.
* Interactive widget tests for `TeamTile`, `QuickScoreButton`, `FieldColumn`, and `OverallLeaderboard`.

---

## 📦 Building a Release Executable

To compile a standalone Windows desktop executable:

```powershell
flutter build windows --release
```

The compiled release package will be located at:
```
build\windows\x64\runner\Release\
```
To run the release app, launch `flutter_scoreboard_app.exe` in that directory.

---

## ☁️ Firebase & Firestore Deployment

The scoreboard cloud backend is deployed to a clean, isolated Firebase project:
* **Firebase Project ID:** `scoreboard-app-live-9481`
* **Firebase Console:** [https://console.firebase.google.com/project/scoreboard-app-live-9481/overview](https://console.firebase.google.com/project/scoreboard-app-live-9481/overview)
* **Firestore Rules:** Verified and deployed (`firestore.rules`).

To re-deploy rules at any time:
```powershell
npx firebase-tools deploy --only firestore --project scoreboard-app-live-9481
```

---

## 🛠️ Troubleshooting

1. **SQLite FFI on Desktop:**
   * SQLite uses `sqflite_common_ffi` and `sqlite3_flutter_libs`. On Windows, the required binaries are automatically bundled. If running in tests or custom scripts, `DatabaseHelper.initializeFfi()` must be called before database operations.
2. **Developer Mode on Windows:**
   * Flutter plugins on Windows require symlink support. If prompted, enable Developer Mode under Windows Settings (`ms-settings:developers`).
3. **Database Location:**
   * On Windows desktop, the SQLite database is located at:
     `%USERPROFILE%\Documents\ScoreboardApp\scoreboard.db`
   * To reset the database to a fresh state, either use **Reset All Scores** in the Admin Panel or delete `scoreboard.db`.
