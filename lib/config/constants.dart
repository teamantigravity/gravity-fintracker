class AppConstants {
  static const String appName = 'Gravity Fintracker';
  static const String appTagline = 'Private by design. Powerful by nature.';
  static const String appVersion = '1.1.0';
  static const String appBuildNumber = '2';
  static const String orgName = 'Team Antigravity';
  static const String repoUrl = 'https://github.com/teamantigravity/gravity-fintracker';

  // Privacy
  static const String privacyPromise =
      'Your financial data never leaves your device unless you explicitly enable quantum-encrypted sync.';
  static const String encryptionStandard = 'AES-256-GCM + HKDF-SHA512';
  static const String quantumShield =
      'Quantum-resistant: AES-256 symmetric encryption withstands Grover\'s algorithm. '
      'HKDF-SHA512 key derivation provides post-quantum key stretching.';

  // Subscription tiers
  static const String freeTierName = 'Free';
  static const String proTierName = 'Pro';
  static const double proMonthlyPrice = 3.99;
  static const double proYearlyPrice = 34.99;

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
  static const int dbVersion = 2;

  // Recurring transaction intervals
  static const String intervalDaily = 'daily';
  static const String intervalWeekly = 'weekly';
  static const String intervalMonthly = 'monthly';
  static const String intervalYearly = 'yearly';

  // Google brand colors (for icon and accents)
  static const int googleBlue = 0xFF4285F4;
  static const int googleRed = 0xFFEA4335;
  static const int googleYellow = 0xFFFBBC05;
  static const int googleGreen = 0xFF34A853;
}
