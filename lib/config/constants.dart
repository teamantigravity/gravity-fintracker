class AppConstants {
  static const String appName = 'Gravity Fintracker';
  static const String appTagline = 'Private by design. Powerful by nature.';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
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
  // Set keys and enableSubscriptions = true once published
  static const String revenueCatAppleKey = '';
  static const String revenueCatGoogleKey = '';

  // Supabase
  static const String supabaseUrl = 'https://ivjcgeyugeywqqxxtgyx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2amNnZXl1Z2V5d3FxeHh0Z3l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MDM0NTEsImV4cCI6MjA5OTM3OTQ1MX0.sLW3VUXb48RdcKM1Y5Dpa1poyXCYAGTgAS2DfGH3jz4';
  static const String supabasePublishableKey = 'sb_publishable_ai8P_M9In2r7nqSCIbIvhw_6dqLmLyO';

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
