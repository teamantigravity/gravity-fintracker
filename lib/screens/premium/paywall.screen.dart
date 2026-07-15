import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
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
  String _selectedTier = 'plus';
  bool _isYearly = true;
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      bool success;
      if (_selectedTier == 'plus') {
        success = await _subscriptionService.purchasePlus(yearly: _isYearly);
      } else {
        success = await _subscriptionService.purchasePro(yearly: _isYearly);
      }
      if (success && mounted) {
        if (_selectedTier == 'pro') {
          context.read<AppCubit>().updatePro(true);
        } else {
          context.read<AppCubit>().updatePlus(true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedTier == 'pro' ? "Welcome to Pro!" : "Welcome to Plus!")),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase failed: $e")),
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
    final isPro = _selectedTier == 'pro';
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
                    isPro ? "PRO" : "PLUS",
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
                  isPro ? "Unlock Everything" : "Unlock Smart Recurring",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Privacy-first finance, everywhere.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _PlanCard(
                        title: "Plus",
                        price: _isYearly ? offering.plusYearlyPrice : offering.plusMonthlyPrice,
                        subtitle: "Save ${offering.plusYearlySavings}",
                        features: const [
                          'Subscription intelligence',
                          'Smart recurring rules',
                          'Advanced reports',
                          'Receipt & voice input',
                          'Savings goals',
                        ],
                        isSelected: !isPro,
                        onTap: () => setState(() => _selectedTier = 'plus'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlanCard(
                        title: "Pro",
                        price: _isYearly ? offering.proYearlyPrice : offering.proMonthlyPrice,
                        subtitle: "Save ${offering.proYearlySavings}",
                        features: const [
                          'Everything in Plus',
                          'E2E encrypted sync',
                          'Household P2P sync',
                          'AI financial coach',
                          'Document vault',
                        ],
                        isSelected: isPro,
                        onTap: () => setState(() => _selectedTier = 'pro'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Monthly')),
                      ButtonSegment(value: true, label: Text('Yearly')),
                    ],
                    selected: {_isYearly},
                    onSelectionChanged: (v) => setState(() => _isYearly = v.first),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handlePurchase,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Start ${_selectedTier.toUpperCase()} — ${_isYearly ? yearlyPrice : monthlyPrice}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _subscriptionService.restorePurchases();
                      if (!context.mounted) return;
                      if (_subscriptionService.isPro) {
                        context.read<AppCubit>().updatePro(true);
                      } else if (_subscriptionService.isPlus) {
                        context.read<AppCubit>().updatePlus(true);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Purchases restored")),
                      );
                    },
                    child: const Text("Restore Purchases"),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Cancel anytime. No questions asked.",
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      ),
    );
  }
}
