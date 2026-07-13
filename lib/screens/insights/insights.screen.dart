import 'package:fintracker/services/anomaly_detection_service.dart';
import 'package:fintracker/services/cashflow_forecast_service.dart';
import 'package:fintracker/services/coach_service.dart';
import 'package:fintracker/services/financial_health_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../premium/paywall.screen.dart';
import '../savings_goals/savings_goals.screen.dart';
import 'coach.screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Future<FinancialHealth>? _health;
  Future<List<Anomaly>>? _anomalies;
  Future<CashflowForecast>? _forecast;
  final bool _pro = SubscriptionService().isPro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _health = FinancialHealthService.compute();
      _anomalies = AnomalyDetectionService.detect();
      if (_pro && SubscriptionService().canUseCashFlowForecast) {
        _forecast = CashflowForecastService.forecast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialHealthCard(theme, colorScheme),
              const SizedBox(height: 16),
              _buildAnomaliesCard(theme, colorScheme),
              const SizedBox(height: 16),
              _buildForecastCard(theme, colorScheme),
              const SizedBox(height: 16),
              _buildCoachCard(theme, colorScheme),
              const SizedBox(height: 16),
              _buildSavingsGoalsCard(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealthCard(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<FinancialHealth>(
      future: _health,
      builder: (context, snapshot) {
        final score = snapshot.data?.score ?? 0;
        final color = score >= 80 ? AppTheme.incomeColor : score >= 50 ? Colors.orange : AppTheme.expenseColor;
        return _card(
          title: 'Financial Health',
          child: snapshot.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _scoreRing(score, color),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                score >= 80 ? 'Excellent' : score >= 50 ? 'Fair' : 'Needs Attention',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
                              ),
                              Text(
                                'Savings ${snapshot.data?.savingsRate.toStringAsFixed(0)}% · Budget ${snapshot.data?.budgetScore} · Liquidity ${snapshot.data?.liquidityScore}',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.suggestions.take(2).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Symbols.lightbulb, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s, style: theme.textTheme.bodySmall)),
                            ],
                          ),
                        )),
                  ],
                )
              : const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }

  Widget _buildAnomaliesCard(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<List<Anomaly>>(
      future: _anomalies,
      builder: (context, snapshot) {
        final anomalies = snapshot.data ?? [];
        return _card(
          title: 'Smart Alerts',
          child: anomalies.isEmpty
              ? Row(
                  children: [
                    Icon(Symbols.check_circle, color: AppTheme.incomeColor),
                    const SizedBox(width: 8),
                    Text('No anomalies detected', style: theme.textTheme.bodyMedium),
                  ],
                )
              : Column(
                  children: anomalies.take(3).map((a) => _anomalyTile(a, theme)).toList(),
                ),
        );
      },
    );
  }

  Widget _buildForecastCard(ThemeData theme, ColorScheme colorScheme) {
    final unlocked = SubscriptionService().canUseCashFlowForecast;
    return _card(
      title: 'Cash Flow Forecast',
      pro: !_pro,
      child: unlocked
          ? FutureBuilder<CashflowForecast>(
              future: _forecast,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                final forecast = snapshot.data!;
                final min = forecast.minProjectedBalance;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _forecastMetric('Daily Income', CurrencyText(forecast.dailyIncome), AppTheme.incomeColor),
                        _forecastMetric('Daily Expense', CurrencyText(forecast.dailyExpense), AppTheme.expenseColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Projected minimum balance in 90 days:',
                      style: theme.textTheme.bodySmall,
                    ),
                    CurrencyText(min, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: min < 0 ? AppTheme.expenseColor : AppTheme.incomeColor)),
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
            )
          : _proTile('Get a 90-day balance forecast and low-balance alerts', theme, () => _openPaywall()),
    );
  }

  Widget _buildCoachCard(ThemeData theme, ColorScheme colorScheme) {
    final unlocked = SubscriptionService().canUseFinancialCoach;
    return _card(
      title: 'Financial Coach',
      pro: !_pro,
      child: unlocked
          ? FutureBuilder<List<CoachMessage>>(
              future: CoachService.generateInsights(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
                final messages = snapshot.data!;
                return _proTile('${messages.length} personalized insights ready', theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachScreen())));
              },
            )
          : _proTile('Ask your on-device financial coach for personalized advice', theme, () => _openPaywall()),
    );
  }

  Widget _buildSavingsGoalsCard(ThemeData theme, ColorScheme colorScheme) {
    final unlocked = SubscriptionService().canUseSavingsGoals;
    return _card(
      title: 'Savings Goals',
      pro: !_pro,
      child: unlocked
          ? _proTile('Track goals and run what-if scenarios', theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingsGoalsScreen())))
          : _proTile('Create savings goals and what-if plans', theme, () => _openPaywall()),
    );
  }

  Widget _card({required String title, required Widget child, bool pro = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (pro) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colorScheme.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _scoreRing(int score, Color color) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Center(child: Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color))),
        ],
      ),
    );
  }

  Widget _anomalyTile(Anomaly anomaly, ThemeData theme) {
    final color = anomaly.severity == Severity.high ? AppTheme.expenseColor : anomaly.severity == Severity.medium ? Colors.orange : Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.warning, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anomaly.title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(anomaly.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastMetric(String label, Widget value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        value,
      ],
    );
  }

  Widget _proTile(String text, ThemeData theme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
            Icon(Symbols.arrow_forward, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _openPaywall() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }
}
