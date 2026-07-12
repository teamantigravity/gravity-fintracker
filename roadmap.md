# Gravity Fintracker Roadmap

## ✅ Completed (v2.0)

### Privacy & Security
- [x] Zero-analytics architecture (no tracking SDKs)
- [x] Biometric app lock (fingerprint/Face ID)
- [x] Privacy Dashboard with 100% score
- [x] E2E encryption service (AES-256-CBC)
- [x] Secure key storage via flutter_secure_storage

### Charts & Insights
- [x] Spending breakdown pie chart (by category)
- [x] Daily income/expense bar chart
- [x] Toggle between list and chart views

### Recurring Transactions
- [x] Daily, Weekly, Monthly, Yearly intervals
- [x] Activate/deactivate toggle
- [x] Swipe-to-delete

### Theme System
- [x] Light, Dark, AMOLED Dark, System themes
- [x] Google Fonts (Inter) typography
- [x] Material 3 design language

### Data Management
- [x] JSON export/import (full backup)
- [x] CSV export (spreadsheet-ready)
- [x] Database migration system (v1 → v2)

### Monetization Architecture
- [x] Subscription service (RevenueCat-ready)
- [x] Paywall screen with monthly/yearly plans
- [x] Feature flag system in constants.dart

### Sync Architecture
- [x] Sync service with E2E encryption
- [x] Supabase backend integration (placeholder)
- [x] Encrypted snapshot export/import

### Redesigned UX
- [x] Modern onboarding with privacy messaging
- [x] Redesigned home screen with summary cards
- [x] 5-tab navigation (Home, Accounts, Categories, Recurring, Settings)
- [x] Sectioned settings screen

---

## ✅ Completed (v2.1)

### Rebranding
- [x] Rebranded to Gravity Fintracker (Team Antigravity)
- [x] Google-colored adaptive app icon (Android)
- [x] Updated all references, exports, manifests

### Quantum-Resistant Encryption
- [x] AES-256-GCM + HKDF-SHA512 key derivation
- [x] 100K-round SHA-512 passphrase key stretching
- [x] CSPRNG salts and IVs per encryption op
- [x] Versioned ciphertext format (v2 + v1 backward compat)
- [x] Post-quantum key stretching in privacy dashboard

### Smart Insights
- [x] Local-only spending insights engine
- [x] Savings rate analysis
- [x] Top spending category detection
- [x] Large transaction alerts
- [x] Spending diversity analysis

### Bug Fixes
- [x] Fixed null safety crashes in settings (username, currency)
- [x] Fixed missing await on resetDatabase delete calls (race condition)
- [x] Biometric permissions added to Android manifest

### CI/CD
- [x] GitHub Actions workflow for 6 platforms (Android, iOS, Web, Linux, Windows, macOS)
- [x] Aggressive caching (Flutter SDK, pub cache, Gradle, CocoaPods)
- [x] Concurrency control (cancel-in-progress)
- [x] APK + AAB artifact uploads

---

## 🔜 Next Up (v2.2)

### Reports & Analytics
- [ ] Weekly, Monthly, Yearly report views
- [ ] Category spending trends (month-over-month)
- [ ] PDF report generation
- [ ] Year-over-year comparison

### Smart Features
- [ ] Budget alerts via local notifications
- [ ] Smart category suggestions for new transactions
- [ ] In-app calculator during amount input

### Sync (activate with API keys)
- [ ] Supabase authentication (email + passkey)
- [ ] Real-time cloud sync
- [ ] Conflict resolution (last-write-wins per record)
- [ ] Sync status indicators

---

## 🔮 Future (v3.0)

### Platform Excellence
- [ ] iOS & Android home screen widgets (home_widget)
- [ ] Desktop sidebar navigation (responsive layout)
- [ ] iPad/tablet master-detail layout
- [ ] Keyboard shortcuts for desktop

### Advanced Features
- [ ] Receipt scanning (on-device OCR via ML Kit)
- [ ] Multi-currency support with conversion
- [ ] Investment portfolio tracking
- [ ] Debt payoff calculator
- [ ] Financial goal setting & tracking

### Community
- [ ] App Store & Play Store listing
- [ ] Marketing website
- [ ] Privacy audit documentation
- [ ] Contributor guidelines
