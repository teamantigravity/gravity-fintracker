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

  bool _isPlus = false;
  bool _isPro = false;

  // When subscriptions are disabled, all features are unlocked (development mode)
  // When enabled, checks RevenueCat entitlements
  bool get isPlus => _isPlus || _isPro || !AppConstants.enableSubscriptions;
  bool get isPro => _isPro || !AppConstants.enableSubscriptions;

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
      _isPlus = customerInfo.entitlements.all['plus']?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking entitlements: $e');
      _isPro = false;
      _isPlus = false;
    }
  }

  Future<bool> purchasePlus({bool yearly = false}) async {
    if (!AppConstants.enableSubscriptions) return true;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
      final offerings = await Purchases.getOfferings();
      final package = _findPackage(offerings, isPlus: true, yearly: yearly);
      if (package != null) {
        // ignore: deprecated_member_use
        final purchaseResult = await Purchases.purchasePackage(package);
        _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;
        _isPlus = purchaseResult.customerInfo.entitlements.all['plus']?.isActive ?? false;
        return isPlus;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> purchasePro({bool yearly = false}) async {
    if (!AppConstants.enableSubscriptions) return true;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
      final offerings = await Purchases.getOfferings();
      final package = _findPackage(offerings, isPlus: false, yearly: yearly);
      if (package != null) {
        // ignore: deprecated_member_use
        final purchaseResult = await Purchases.purchasePackage(package);
        _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;
        _isPlus = purchaseResult.customerInfo.entitlements.all['plus']?.isActive ?? false;
        return isPro;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> purchaseLifetime() async {
    if (!AppConstants.enableSubscriptions) return true;

    try {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.lifetime;
      if (package != null) {
        // ignore: deprecated_member_use
        final purchaseResult = await Purchases.purchasePackage(package);
        _isPro = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;
        _isPlus = purchaseResult.customerInfo.entitlements.all['plus']?.isActive ?? false;
        return isPlus || isPro;
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Package? _findPackage(Offerings? offerings, {required bool isPlus, required bool yearly}) {
    final current = offerings?.current;
    if (current == null) return null;

    // Prefer explicit package identifiers
    final packageId = '${isPlus ? 'plus' : 'pro'}_${yearly ? 'yearly' : 'monthly'}';
    for (final p in current.availablePackages) {
      if (p.identifier == packageId) return p;
    }

    // Fallback: package identifier containing the tier and billing interval
    final tierKeyword = isPlus ? 'plus' : 'pro';
    final intervalKeyword = yearly ? 'yearly' : 'monthly';
    for (final p in current.availablePackages) {
      final id = p.identifier.toLowerCase();
      if (id.contains(tierKeyword) && id.contains(intervalKeyword)) return p;
    }

    // Last-resort fallback to RevenueCat's current monthly/annual
    return yearly ? current.annual : current.monthly;
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
  bool get canExportPdf => isPlus;
  bool get canUseTaxReports => isPlus;
  bool get canUseRecurring => isPlus;
  bool get canUseAdvancedCharts => isPlus;
  bool get canUseMultiDevice => isPro;
  bool get hasAutoBackup => isPro;
  bool get canUseCashFlowForecast => isPlus;
  bool get canUseFinancialCoach => isPro;
  bool get canUseReceiptScanner => isPlus;
  bool get canUseVoiceInput => isPlus;
  bool get canUseSavingsGoals => isPlus;
  bool get canUseWhatIfPlanner => isPro;
  bool get canUseSubscriptionDashboard => isPlus;
  bool get canUseSubscriptionScanner => isPlus;
  bool get canUseRecurringRules => isPlus;
  bool get canUseHouseholdSync => isPro;
  bool get canUseDocumentVault => isPlus;

  // Offering details for paywall
  SubscriptionOffering get offering => SubscriptionOffering(
    plusMonthlyPrice: '\$${AppConstants.plusMonthlyPrice.toStringAsFixed(2)}/mo',
    plusYearlyPrice: '\$${AppConstants.plusYearlyPrice.toStringAsFixed(2)}/yr',
    proMonthlyPrice: '\$${AppConstants.proMonthlyPrice.toStringAsFixed(2)}/mo',
    proYearlyPrice: '\$${AppConstants.proYearlyPrice.toStringAsFixed(2)}/yr',
    plusYearlySavings: '${((1 - (AppConstants.plusYearlyPrice / (AppConstants.plusMonthlyPrice * 12))) * 100).round()}%',
    proYearlySavings: '${((1 - (AppConstants.proYearlyPrice / (AppConstants.proMonthlyPrice * 12))) * 100).round()}%',
  );
}

class SubscriptionOffering {
  final String plusMonthlyPrice;
  final String plusYearlyPrice;
  final String plusYearlySavings;
  final String proMonthlyPrice;
  final String proYearlyPrice;
  final String proYearlySavings;

  SubscriptionOffering({
    required this.plusMonthlyPrice,
    required this.plusYearlyPrice,
    required this.plusYearlySavings,
    required this.proMonthlyPrice,
    required this.proYearlyPrice,
    required this.proYearlySavings,
  });
}
