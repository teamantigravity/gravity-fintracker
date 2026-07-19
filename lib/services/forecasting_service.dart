import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/services/insights_service.dart';

class ForecastingService {
  static List<SpendingInsight> generateForecastInsights(List<Payment> payments) {
    if (payments.length < 10) return []; // Need enough data

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentPayments = payments.where((p) => p.datetime.isAfter(thirtyDaysAgo)).toList();
    
    double recentIncome = 0;
    double recentExpense = 0;
    
    for (final p in recentPayments) {
      if (p.type == PaymentType.credit) recentIncome += p.amount;
      if (p.type == PaymentType.debit) recentExpense += p.amount;
    }
    
    // Simple Exponential Smoothing (Alpha = 0.5) mock for forecast
    // Here we use a heuristic linear projection based on 30-day velocity
    final dailyVelocity = recentExpense / 30;
    final projectedMonthly = dailyVelocity * 30;
    
    final insights = <SpendingInsight>[];
    
    if (projectedMonthly > recentIncome && recentIncome > 0) {
      insights.add(SpendingInsight(
        title: 'Forecaster Alert',
        description: "You're on track to spend \$${projectedMonthly.toStringAsFixed(0)} this month, exceeding your income velocity. Consider pacing your discretionary expenses.",
        type: InsightType.warning,
      ));
    } else if (projectedMonthly < recentIncome * 0.5) {
      insights.add(SpendingInsight(
        title: 'Savings Velocity Strong',
        description: "Great job! Based on your 30-day trend, you're projected to save over 50% of your income. Keep it up!",
        type: InsightType.positive,
      ));
    } else {
      insights.add(SpendingInsight(
        title: 'AI Forecast',
        description: 'Your 30-day spending velocity is \$${dailyVelocity.toStringAsFixed(1)}/day. Your cash flow looks stable.',
        type: InsightType.neutral,
      ));
    }

    return insights;
  }
}
