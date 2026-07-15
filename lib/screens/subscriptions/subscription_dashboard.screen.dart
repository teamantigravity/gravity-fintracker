import 'package:fintracker/model/subscription.model.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/screens/subscriptions/subscription_scanner.screen.dart';
import 'package:fintracker/services/subscription_intelligence_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> {
  Future<SubscriptionSummary>? _summary;
  final bool _unlocked = SubscriptionService().canUseSubscriptionDashboard;

  @override
  void initState() {
    super.initState();
    if (_unlocked) _load();
  }

  void _load() {
    setState(() => _summary = SubscriptionIntelligenceService.analyze());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscriptions')),
        body: _paywall(theme, colorScheme),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.receipt_long, fill: 1),
            tooltip: 'Scan Subscription',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScannerScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: FutureBuilder<SubscriptionSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSpendCard(summary, theme, colorScheme),
                        const SizedBox(height: 16),
                        if (summary.priceChanges.isNotEmpty) ...[
                          _buildSectionTitle('Price changes'),
                          ...summary.priceChanges.take(3).map((s) => _buildAlertTile(s, theme, colorScheme, 'Price ${s.priceChangeDirection} ${s.priceChangePercent?.toStringAsFixed(0) ?? '0'}%')),
                          const SizedBox(height: 16),
                        ],
                        if (summary.duplicates.isNotEmpty) ...[
                          _buildSectionTitle('Possible duplicates'),
                          ...summary.duplicates.take(3).map((s) => _buildAlertTile(s, theme, colorScheme, 'Duplicate amount detected')),
                          const SizedBox(height: 16),
                        ],
                        if (summary.possiblyUnused.isNotEmpty) ...[
                          _buildSectionTitle('Possibly unused'),
                          ...summary.possiblyUnused.take(3).map((s) => _buildAlertTile(s, theme, colorScheme, 'No payment since ${DateFormat('dd MMM').format(s.nextDue ?? DateTime.now())}')),
                          const SizedBox(height: 16),
                        ],
                        if (summary.overdue.isNotEmpty) ...[
                          _buildSectionTitle('Overdue'),
                          ...summary.overdue.take(3).map((s) => _buildAlertTile(s, theme, colorScheme, 'Due ${DateFormat('dd MMM').format(s.nextDue ?? DateTime.now())}')),
                          const SizedBox(height: 16),
                        ],
                        _buildSectionTitle('All subscriptions'),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSubscriptionTile(summary.subscriptions[index], theme, colorScheme),
                    childCount: summary.subscriptions.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _paywall(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.workspace_premium, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Subscription Intelligence is a Plus feature',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Detect recurring bills, price changes, duplicates, and unused subscriptions on-device.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendCard(SubscriptionSummary summary, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly subscription spend', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          CurrencyText(
            -summary.monthlySpend,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${summary.totalSubscriptions} subscriptions · ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              CurrencyText(-summary.yearlySpend, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              Text(' / year', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAlertTile(Subscription sub, ThemeData theme, ColorScheme colorScheme, String subtitle) {
    final isCredit = sub.type == 'CR';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.expenseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Symbols.warning, color: AppTheme.expenseColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.expenseColor)),
              ],
            ),
          ),
          CurrencyText(isCredit ? sub.amount : -sub.amount, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTile(Subscription sub, ThemeData theme, ColorScheme colorScheme) {
    final isCredit = sub.type == 'CR';
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: (sub.category?.color ?? colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(sub.category?.icon ?? Symbols.repeat, color: sub.category?.color ?? colorScheme.primary, size: 20),
      ),
      title: Text(sub.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${sub.frequency} · Last paid ${DateFormat('dd MMM').format(sub.lastPaid)}${sub.nextDue != null ? ' · Next ${DateFormat('dd MMM').format(sub.nextDue!)}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CurrencyText(
            isCredit ? sub.amount : -sub.amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isCredit ? AppTheme.incomeColor : AppTheme.expenseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CurrencyText(
                isCredit ? sub.monthlyCost : -sub.monthlyCost,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              Text('/mo', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }
}
