import 'package:fintracker/services/cashflow_forecast_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/services/what_if_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../premium/paywall.screen.dart';

class WhatIfScreen extends StatefulWidget {
  const WhatIfScreen({super.key});

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  double _incomeDelta = 0;
  double _expenseDelta = 0;
  double _recurringDelta = 0;
  Future<CashflowForecast>? _forecast;

  final bool _unlocked = SubscriptionService().canUseWhatIfPlanner;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!_unlocked) return;
    setState(() {
      _forecast = WhatIfService.simulate(
        incomeDelta: _incomeDelta,
        expenseDelta: _expenseDelta,
        recurringDelta: _recurringDelta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('What-If Planner')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.lock, size: 64, color: colorScheme.primary.withAlpha(60)),
                const SizedBox(height: 16),
                Text(
                  'What-If Planner is a Pro feature.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  child: const Text('Unlock Pro'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('What-If Planner', style: TextStyle(fontWeight: FontWeight.w600))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSlider(
            label: 'Daily income change',
            value: _incomeDelta,
            min: -100,
            max: 100,
            prefix: _incomeDelta >= 0 ? '+' : '',
            onChanged: (v) => setState(() {
              _incomeDelta = v;
              _load();
            }),
          ),
          _buildSlider(
            label: 'Daily expense change',
            value: _expenseDelta,
            min: -100,
            max: 100,
            prefix: _expenseDelta >= 0 ? '+' : '',
            onChanged: (v) => setState(() {
              _expenseDelta = v;
              _load();
            }),
          ),
          _buildSlider(
            label: 'Recurring payment change',
            value: _recurringDelta,
            min: -100,
            max: 100,
            prefix: _recurringDelta >= 0 ? '+' : '',
            onChanged: (v) => setState(() {
              _recurringDelta = v;
              _load();
            }),
          ),
          const SizedBox(height: 16),
          FutureBuilder<CashflowForecast>(
            future: _forecast,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              }
              final forecast = snapshot.data!;
              final min = forecast.minProjectedBalance;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectionCard(theme, forecast),
                  const SizedBox(height: 16),
                  Text(
                    'Projected minimum balance in 90 days:',
                    style: theme.textTheme.bodySmall,
                  ),
                  CurrencyText(
                    min,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: min < 0 ? AppTheme.expenseColor : AppTheme.incomeColor),
                  ),
                  if (forecast.lowBalanceDates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Potential low balance on ${forecast.lowBalanceDates.length} upcoming day(s).',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.expenseColor),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String prefix,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(
              '$prefix${value.toStringAsFixed(0)} / day',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 40,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildProjectionCard(ThemeData theme, CashflowForecast forecast) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('Daily Income', forecast.dailyIncome, AppTheme.incomeColor),
              _metric('Daily Expense', forecast.dailyExpense, AppTheme.expenseColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withAlpha(200))),
        CurrencyText(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
