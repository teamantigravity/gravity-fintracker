import 'dart:io';
import 'package:fintracker/config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription management service
///
/// Uses RevenueCat for cross-platform subscription handling.
/// Supports App Store, Play Store, and Stripe (desktop).
///
/// Free tier: Full local app, unlimited transactions, single device
/// Pro tier: E2E encrypted sync, multi-device, advanced reports, recurring transactions
///
/// To activate: Set RevenueCat API keys in constants.dart and set enableSubscriptions = true
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isPro = false;
  bool get isPro => _isPro || !AppConstants.enableSubscriptions;

  // When subscriptions are disabled, all features are unlocked (development mode)
  // When enabled, checks RevenueCat entitlements

  Future<void> initialize() async {
    if (!AppConstants.enableSubscriptions) {
      _isPro = true; // All features unlocked in dev mode
      return;
    }

    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      _isPro = true; // Web/Desktop use mock pro for now
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);
    PurchasesConfiguration configuration;
    if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(AppConstants.revenueCatAppleKey);
    } else {
      configuration = PurchasesConfiguration(AppConstants.revenueCatGoogleKey);
    }
    await Purchases.configure(configuration);

    await _checkEntitlements();
  }

  Future<void> _checkEntitlements() async {
    if (!AppConstants.enableSubscriptions) {
      _isPro = true;
      return;
    }

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return;
      final customerInfo = await Purchases.getCustomerInfo();
      _isPro = customerInfo.entitlements.all['pro']?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking entitlements: $e');
      _isPro = false;
    }
  }

  Future<bool> purchaseMonthly() async {
    if (!AppConstants.enableSubscriptions) return true;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly != null) {
        // ignore: deprecated_member_use
        final purchaseResult = await Purchases.purchasePackage(monthly);
        _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;
        return _isPro;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> purchaseYearly() async {
    if (!AppConstants.enableSubscriptions) return true;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
      final offerings = await Purchases.getOfferings();
      final annual = offerings.current?.annual;
      if (annual != null) {
        // ignore: deprecated_member_use
        final purchaseResult = await Purchases.purchasePackage(annual);
        _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;
        return _isPro;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!AppConstants.enableSubscriptions) return;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return;
      await Purchases.restorePurchases();
      await _checkEntitlements();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  // Feature gates
  bool get canSync => isPro;
  bool get canExportPdf => isPro;
  bool get canUseRecurring => isPro;
  bool get canUseAdvancedCharts => isPro;
  bool get canUseMultiDevice => isPro;
  bool get hasAutoBackup => isPro;
  bool get canUseCashFlowForecast => isPro;
  bool get canUseFinancialCoach => isPro;
  bool get canUseReceiptScanner => isPro;
  bool get canUseVoiceInput => isPro;
  bool get canUseSavingsGoals => isPro;
  bool get canUseWhatIfPlanner => isPro;

  // Offering details for paywall
  SubscriptionOffering get offering => SubscriptionOffering(
    monthlyPrice: '\$${AppConstants.proMonthlyPrice.toStringAsFixed(2)}/mo',
    yearlyPrice: '\$${AppConstants.proYearlyPrice.toStringAsFixed(2)}/yr',
    yearlySavings: '${((1 - (AppConstants.proYearlyPrice / (AppConstants.proMonthlyPrice * 12))) * 100).round()}%',
  );
}

class SubscriptionOffering {
  final String monthlyPrice;
  final String yearlyPrice;
  final String yearlySavings;

  SubscriptionOffering({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.yearlySavings,
  });
}
