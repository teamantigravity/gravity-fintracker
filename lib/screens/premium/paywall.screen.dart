import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/config/strings.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/ui/prism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  String _selectedTier = AppConstants.entitlementPlus;
  bool _isYearly = true;
  bool _isLoading = false;

  Future<void> _restorePurchases() async {
    await _subscriptionService.restorePurchases();
    if (!mounted) return;
    if (_subscriptionService.isPro) {
      context.read<AppCubit>().updatePro(true);
    } else if (_subscriptionService.isPlus) {
      context.read<AppCubit>().updatePlus(true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.purchasesRestored)),
    );
  }

  Future<void> _handleLifetimePurchase() async {
    setState(() => _isLoading = true);
    try {
      final success = await _subscriptionService.purchaseLifetime();
      if (success && mounted) {
        final subscriptionService = SubscriptionService();
        if (subscriptionService.isPro) {
          context.read<AppCubit>().updatePro(true);
        } else {
          context.read<AppCubit>().updatePlus(true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(subscriptionService.isPro ? Strings.welcomeLifetimePro : Strings.welcomeLifetimePlus)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.purchaseFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      bool success;
      if (_selectedTier == AppConstants.entitlementPlus) {
        success = await _subscriptionService.purchasePlus(yearly: _isYearly);
      } else {
        success = await _subscriptionService.purchasePro(yearly: _isYearly);
      }
      if (success && mounted) {
        if (_selectedTier == AppConstants.entitlementPro) {
          context.read<AppCubit>().updatePro(true);
        } else {
          context.read<AppCubit>().updatePlus(true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedTier == AppConstants.entitlementPro ? Strings.welcomePro : Strings.welcomePlus)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.purchaseFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final offering = _subscriptionService.offering;
    final isPro = _selectedTier == AppConstants.entitlementPro;
    final monthlyPrice = isPro ? offering.proMonthlyPrice : offering.plusMonthlyPrice;
    final yearlyPrice = isPro ? offering.proYearlyPrice : offering.plusYearlyPrice;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPro ? Strings.pro : Strings.plus,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPro ? Strings.unlockEverything : Strings.unlockSmartRecurring,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Strings.privacyFirstFinanceEverywhere,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _PlanCard(
                        title: Strings.plusPlanTitle,
                        price: _isYearly ? offering.plusYearlyPrice : offering.plusMonthlyPrice,
                        subtitle: Strings.saveYearlyFmt(offering.plusYearlySavings),
                        features: Strings.plusPlanFeatures,
                        isSelected: !isPro,
                        onTap: () => setState(() => _selectedTier = AppConstants.entitlementPlus),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlanCard(
                        title: Strings.proPlanTitle,
                        price: _isYearly ? offering.proYearlyPrice : offering.proMonthlyPrice,
                        subtitle: Strings.saveYearlyFmt(offering.proYearlySavings),
                        features: Strings.proPlanFeatures,
                        isSelected: isPro,
                        onTap: () => setState(() => _selectedTier = AppConstants.entitlementPro),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text(Strings.monthly)),
                      ButtonSegment(value: true, label: Text(Strings.yearly)),
                    ],
                    selected: {_isYearly},
                    onSelectionChanged: (v) => setState(() => _isYearly = v.first),
                  ),
                ),
                const SizedBox(height: 24),
                PrismButton(
                  isLoading: _isLoading,
                  label: Strings.startPlanFmt(_selectedTier.toUpperCase(), _isYearly ? yearlyPrice : monthlyPrice),
                  onPressed: () { _handlePurchase(); },
                ),
                const SizedBox(height: 12),
                Center(
                  child: PrismButton(
                    variant: PrismButtonVariant.ghost,
                    isStretched: false,
                    label: Strings.orUnlockLifetimePro,
                    onPressed: () { _handleLifetimePurchase(); },
                  ),
                ),
                Center(
                  child: PrismButton(
                    variant: PrismButtonVariant.ghost,
                    isStretched: false,
                    label: Strings.restorePurchases,
                    onPressed: () { _restorePurchases(); },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    Strings.cancelAnytimeNoQuestionsAsked,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PrismCard(
      onTap: onTap,
      isGlass: true,
      borderRadius: PrismTokens.radiusMd,
      borderColor: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
      borderWidth: isSelected ? 2 : 1,
      backgroundColor: isSelected ? colorScheme.primary.withValues(alpha: 0.06) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              PrismChip(
                label: subtitle,
                color: AppTheme.incomeColor,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.check, size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
