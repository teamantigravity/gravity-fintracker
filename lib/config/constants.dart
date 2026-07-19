import 'package:fintracker/config/strings.dart';

/// Application-level configuration, environment values, and feature flags.
/// All user-facing copy lives in [Strings]; all design tokens live in
/// [PrismColors] / [AppTheme].
class AppConstants {
  // RevenueCat — disabled until app is published on stores
  // Injected at build time via --dart-define. Never hardcode secrets in source.
  static const String revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const String revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');

  // Supabase — injected at build time via --dart-define (see README "Secrets" section).
  // Local dev: flutter run --dart-define-from-file=env/secrets.json
  // CI: values are sourced from GitHub Actions encrypted secrets.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // Feature flags
  static const bool enableSync = false; // Enable after Supabase config
  static const bool enableSubscriptions = false; // Enable after RevenueCat config
  static const bool enableBiometricLock = true;
  static const bool enableRecurringTransactions = true;
  static const bool enableCharts = true;
  static const bool enableSmartInsights = true;

  // Database
  static const int dbVersion = 4;

  // Recurring transaction intervals
  static const String intervalDaily = 'daily';
  static const String intervalWeekly = 'weekly';
  static const String intervalMonthly = 'monthly';
  static const String intervalYearly = 'yearly';

  // Subscription pricing
  static const double plusMonthlyPrice = 1.99;
  static const double plusYearlyPrice = 14.99;
  static const double proMonthlyPrice = 3.99;
  static const double proYearlyPrice = 34.99;

  // RevenueCat identifiers
  static const String entitlementPro = 'pro';
  static const String entitlementPlus = 'plus';

  // Sync schema and storage constants
  static const String syncTableName = 'sync_snapshots';
  static const String syncUserIdColumn = 'user_id';
  static const String syncEncryptedDataColumn = 'encrypted_data';
  static const String syncUpdatedAtColumn = 'updated_at';
  static const String syncMasterKeyStorageKey = 'gravity_quantum_master_key';
  static const String syncCipherVersion = 'v2';
  static const String syncHkdfInfo = 'gravity-fintracker-quantum-v2';
  static const int syncPbkdf2Iterations = 100000;
  static const String syncSelectColumns = '$syncEncryptedDataColumn, $syncUpdatedAtColumn';

  // Post-quantum hybrid KEM-DEM sync constants
  static const String pqKeyStorageKey = 'gravity_pq_keys';
  static const String pqCipherVersion = 'v3';
  static const String pqKemAlgorithm = 'ML-KEM-768';
  static const String pqKdfAlgorithm = 'HKDF-SHA-512';
  static const String pqSymmetricCipher = 'AES-256-GCM';
  static const String pqKeyWrapHkdfInfo = 'gravity-fintracker-pq-keywrap-v1';
  static const String pqHybridHkdfInfo = 'gravity-hybrid-kem-v3';

  // Legacy aliases for strings and colors; prefer the canonical sources above.
  static String get appName => Strings.appName;
  static String get appTagline => Strings.appTagline;
}
