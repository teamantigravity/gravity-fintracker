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
  bool _isYearly = true;
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      bool success;
      if (_isYearly) {
        success = await _subscriptionService.purchaseYearly();
      } else {
        success = await _subscriptionService.purchaseMonthly();
      }
      if (success && mounted) {
        context.read<AppCubit>().updatePro(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Welcome to Pro!")),
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Symbols.close),
                  ),
                ),

                const SizedBox(height: 8),

                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "PRO",
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
                  "Unlock the\nFull Experience",
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

                // Features
                _FeatureItem(
                  icon: Symbols.sync,
                  title: "E2E Encrypted Sync",
                  description: "Your data, encrypted on your device. We can't read it. Nobody can.",
                  color: colorScheme.primary,
                ),
                _FeatureItem(
                  icon: Symbols.devices,
                  title: "Multi-Device",
                  description: "Phone, tablet, desktop — all in sync.",
                  color: colorScheme.tertiary,
                ),
                const _FeatureItem(
                  icon: Symbols.repeat,
                  title: "Recurring Transactions",
                  description: "Automate bills, subscriptions, and income tracking.",
                  color: AppTheme.incomeColor,
                ),
                _FeatureItem(
                  icon: Symbols.bar_chart,
                  title: "Advanced Reports",
                  description: "PDF & CSV export, year-over-year analysis.",
                  color: colorScheme.secondary,
                ),
                const _FeatureItem(
                  icon: Symbols.cloud_upload,
                  title: "Automatic Backups",
                  description: "Daily encrypted backups. Never lose your data.",
                  color: AppTheme.expenseColor,
                ),
                const _FeatureItem(
                  icon: Symbols.shield,
                  title: "Zero Knowledge",
                  description: "We literally cannot see your financial data.",
                  color: Color(0xFF6750A4),
                ),

                const SizedBox(height: 32),

                // Plan selector
                Row(
                  children: [
                    Expanded(
                      child: _PlanCard(
                        title: "Monthly",
                        price: offering.monthlyPrice,
                        isSelected: !_isYearly,
                        onTap: () => setState(() => _isYearly = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _PlanCard(
                            title: "Yearly",
                            price: offering.yearlyPrice,
                            isSelected: _isYearly,
                            onTap: () => setState(() => _isYearly = true),
                          ),
                          Positioned(
                            top: -10,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.incomeColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Save ${offering.yearlySavings}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CTA
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
                            "Start Pro — ${_isYearly ? offering.yearlyPrice : offering.monthlyPrice}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Restore
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await _subscriptionService.restorePurchases();
                      if (!context.mounted) return;
                      if (_subscriptionService.isPro) {
                        context.read<AppCubit>().updatePro(true);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Purchases restored")),
                      );
                    },
                    child: const Text("Restore Purchases"),
                  ),
                ),

                const SizedBox(height: 8),

                // Privacy note
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20, fill: 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
