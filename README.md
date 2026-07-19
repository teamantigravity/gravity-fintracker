# Gravity Fintracker — Private by Design. Powerful by Nature.

[![Build](https://github.com/teamantigravity/gravity-fintracker/actions/workflows/build.yml/badge.svg)](https://github.com/teamantigravity/gravity-fintracker/actions)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Privacy](https://img.shields.io/badge/Privacy-100%25-green.svg)](#privacy)
[![Encryption](https://img.shields.io/badge/Encryption-Quantum%20Resistant-purple.svg)](#quantum-resistant-encryption)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#)

**Gravity Fintracker** is a quantum-encrypted, privacy-first expense tracker by **Team Antigravity**. Your financial data stays on your device. No analytics, no tracking, no ads — just clean finance management with optional quantum-resistant encrypted sync.

---

## Why Gravity Fintracker?

| Feature | Gravity Fintracker | Other Finance Apps |
|---|:---:|:---:|
| Quantum-resistant encryption | ✅ | ❌ |
| Zero tracking & analytics | ✅ | ❌ |
| Data stays on device | ✅ | ❌ |
| E2E encrypted sync | ✅ | ❌ |
| Smart spending insights (local) | ✅ | Cloud-based |
| Open source | ✅ | ❌ |
| No account required | ✅ | ❌ |
| 5 platforms (Android, iOS, Windows, macOS, Linux) | ✅ | 1-2 |
| No ads, ever | ✅ | ❌ |

---

## Features

### Free (Unlimited)
- **Expense & Income Tracking** — Categories, accounts, notes, date/time
- **Smart Insights** — AI-like spending analysis, 100% local, zero cloud
- **Interactive Charts** — Pie chart breakdown + daily bar charts (fl_chart)
- **Category Budgets** — Monthly budgets with progress tracking
- **Multiple Accounts** — Cash, bank, credit card — track them all
- **JSON & CSV Export** — Full data portability with cross-platform file pickers
- **Theme System** — Light, Dark, AMOLED Dark, System
- **Biometric Lock** — Fingerprint / Face ID app protection with PIN fallback
- **Adaptive UI** — Bottom navigation on mobile, navigation rail on desktop/tablet
- **Keyboard Shortcuts** — Global shortcuts for new transactions, search, lock, and navigation
- **Desktop Database** — sqflite_common_ffi powers Windows, macOS, and Linux
- **Privacy Dashboard** — Real-time 100% privacy score
- **Recurring Transactions** — Automate bills, subscriptions, income

### Pro (Subscription)
- **Quantum-Encrypted Sync** — AES-256-GCM + HKDF-SHA512, zero-knowledge
- **Multi-Device** — Phone + Tablet + Desktop, all in sync
- **Automatic Cloud Backups** — Daily encrypted backups
- **Advanced Reports** — PDF export, year-over-year trends

---

## Quantum-Resistant Encryption

Gravity Fintracker uses a **hybrid quantum-hardened** encryption architecture:

1. **AES-256-GCM** — Symmetric encryption with 256-bit keys (128-bit effective security against Grover's algorithm)
2. **HKDF-SHA512** — RFC 5869 key derivation with 256-bit post-quantum collision resistance
3. **100K-round SHA-512** — Key stretching from passphrase
4. **CSPRNG** — Unique salt + IV per encryption operation
5. **Versioned ciphertext** — Forward-compatible format (`v2:<salt>:<iv>:<ciphertext>`)

The server stores **only ciphertext**. Your encryption key **never leaves your device**.

---

## Architecture

```
lib/
├── bloc/cubit/          # State management (Flutter Bloc)
├── config/              # App constants, feature flags, API key placeholders
├── dao/                 # Data access objects (SQLite)
├── helpers/             # DB, currency, color utilities, migrations
├── model/               # Data models (Payment, Account, Category, Recurring)
├── screens/
│   ├── home/            # Dashboard with charts + smart insights
│   ├── accounts/        # Account management
│   ├── categories/      # Category management
│   ├── recurring/       # Recurring transactions CRUD
│   ├── settings/        # Settings, theme, biometric, export
│   ├── premium/         # Paywall, privacy dashboard
│   └── onboard/         # Onboarding flow
├── services/
│   ├── sync_service     # Quantum-encrypted E2E sync (Supabase)
│   ├── subscription     # RevenueCat subscription management
│   └── insights         # Local smart spending analysis
├── theme/               # Light / Dark / AMOLED theme system
└── widgets/             # Reusable UI components
```

### CI/CD
- **GitHub Actions** — Automated builds for Android (APK + AAB), iOS, Linux, Windows, macOS
- **Aggressive caching** — Flutter SDK, pub cache, Gradle, CocoaPods all cached
- **Concurrency control** — Cancels superseded builds

---

## Getting Started

```bash
git clone https://github.com/teamantigravity/gravity-fintracker.git
cd gravity-fintracker
flutter pub get
flutter run
```

### Build for production

```bash
flutter build apk --release --split-per-abi   # Android APK
flutter build appbundle --release              # Android AAB
flutter build linux --release                  # Linux
flutter build windows --release                # Windows
flutter build macos --release                  # macOS
flutter build ios --release --no-codesign      # iOS
```

---

## Configuration (for release)

1. **RevenueCat** — Set `revenueCatAppleKey` and `revenueCatGoogleKey` in `lib/config/constants.dart`
2. **Supabase** — Set `supabaseUrl` and `supabaseAnonKey` in `lib/config/constants.dart`
3. **Feature flags** — Set `enableSync = true` and `enableSubscriptions = true`
4. **Signing** — Configure Android keystore in `android/key.properties`

---

## Privacy

Gravity Fintracker's guarantees:

- **0 bytes** sent to any server (Free tier)
- **0 third-party trackers** — no Firebase, Crashlytics, or analytics SDKs
- **0 ads** — monetization through optional Pro subscription only
- **Quantum-resistant encryption** for all synced data
- **Open source** — audit our code yourself

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State | flutter_bloc (Cubit) |
| Database | sqflite + sqflite_common_ffi + migrations |
| Charts | fl_chart |
| Biometric | local_auth |
| Encryption | encrypt (AES-256) + crypto (HKDF-SHA512) |
| Key Storage | flutter_secure_storage |
| Typography | Google Fonts (Inter) |
| Icons | Material Symbols |
| Backend (Pro) | Supabase (managed, zero maintenance) |
| Payments (Pro) | RevenueCat |
| CI/CD | GitHub Actions (5 platforms) |

---

## Roadmap

See [ROADMAP.md](roadmap.md) for the full development roadmap.

---

## Building from source

### Secrets

No secret ever lives in source control. All configuration (Supabase URL/keys,
RevenueCat keys) is injected at build time via `--dart-define`:

```bash
cp env/secrets.example.json env/secrets.json   # fill in real values, gitignored
flutter run --dart-define-from-file=env/secrets.json
```

CI (`.github/workflows/build.yml`) sources the same values from GitHub Actions
encrypted repository secrets and passes them as individual `--dart-define`
flags to every build job.

### Android signing

Release builds are signed, not debug-signed. Generate a keystore once and
point `android/key.properties` (gitignored) at it:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../your-release.keystore
```

If `key.properties` is absent (e.g. a fork's CI run), the build falls back to
debug signing automatically — it never fails the build.

### Obfuscation

Release builds for Android, iOS, Windows, macOS and Linux are built with
`--obfuscate --split-debug-info=build/symbols/<platform>`. Debug symbol maps
are uploaded as CI artifacts (90-day retention) so stack traces from
obfuscated crash reports can still be de-symbolicated with
`flutter symbolize`. Web is excluded — dart2js already minifies release
output and `--obfuscate` isn't applicable to that compilation target.

---

## License

AGPL v3 License — see [LICENSE](LICENSE) for details.

Built with ❤️ by **Team Antigravity**.
