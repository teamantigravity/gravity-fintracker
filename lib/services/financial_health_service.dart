import 'dart:math';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/model/payment.model.dart';

class FinancialHealthService {
  static Future<FinancialHealth> compute() async {
    final payments = await PaymentDao().find();
    final accounts = await AccountDao().find();
    final recurring = await RecurringDao().find();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthExpense = 0;
    Map<int, double> categorySpend = {};

    for (final p in payments) {
      if (p.type == PaymentType.credit) {
        if (p.datetime.isAfter(monthStart) || p.datetime.isAtSameMomentAs(monthStart)) {
          thisMonthIncome += p.amount;
        }
      } else {
        categorySpend[p.category.id ?? 0] = (categorySpend[p.category.id ?? 0] ?? 0) + p.amount;
        if (p.datetime.isAfter(monthStart) || p.datetime.isAtSameMomentAs(monthStart)) {
          thisMonthExpense += p.amount;
        }
        if (p.datetime.isAfter(lastMonthStart) && p.datetime.isBefore(monthStart)) {
          lastMonthExpense += p.amount;
        }
      }
    }

    final totalBalance = accounts.fold<double>(0, (s, a) => s + (a.balance ?? 0));
    final recurringTotal = recurring.where((r) => r.isActive && r.type == 'DR').fold<double>(0, (s, r) => s + r.amount);

    final savingsRate = thisMonthIncome > 0 ? ((thisMonthIncome - thisMonthExpense) / thisMonthIncome) * 100 : 0.0;
    final savingsScore = _savingsRateScore(savingsRate);
    final budgetScore = await _budgetScore(categorySpend);
    final trendScore = _expenseTrendScore(thisMonthExpense, lastMonthExpense);
    final liquidityScore = _liquidityScore(totalBalance, recurringTotal);
    final diversificationScore = _diversificationScore(categorySpend, thisMonthExpense);

    final score = (savingsScore + budgetScore + trendScore + liquidityScore + diversificationScore) / 5;

    return FinancialHealth(
      score: score.round(),
      savingsRate: savingsRate,
      savingsScore: savingsScore.round(),
      budgetScore: budgetScore.round(),
      trendScore: trendScore.round(),
      liquidityScore: liquidityScore.round(),
      diversificationScore: diversificationScore.round(),
      suggestions: _suggestions(savingsRate, budgetScore, trendScore, liquidityScore, diversificationScore),
    );
  }

  static double _savingsRateScore(double rate) {
    if (rate >= 30) return 100;
    if (rate >= 20) return 90;
    if (rate >= 10) return 75;
    if (rate >= 0) return 60;
    if (rate >= -10) return 40;
    return 20;
  }

  static Future<double> _budgetScore(Map<int, double> categorySpend) async {
    final categories = await CategoryDao().find();
    int overBudget = 0;
    int withBudget = 0;
    for (final c in categories) {
      if (c.budget != null && c.budget! > 0) {
        withBudget++;
        final spend = categorySpend[c.id ?? 0] ?? 0;
        if (spend > c.budget!) overBudget++;
      }
    }
    if (withBudget == 0) return 75;
    final ratio = overBudget / withBudget;
    return (1 - ratio) * 100;
  }

  static double _expenseTrendScore(double current, double previous) {
    if (previous == 0) return current == 0 ? 75 : 60;
    final change = (current - previous) / previous;
    if (change <= -0.1) return 100;
    if (change <= 0) return 90;
    if (change <= 0.1) return 75;
    if (change <= 0.25) return 55;
    return 35;
  }

  static double _liquidityScore(double balance, double recurring) {
    if (recurring == 0) return balance > 0 ? 90 : 50;
    final months = balance / recurring;
    if (months >= 3) return 100;
    if (months >= 1) return 80;
    if (months >= 0.5) return 55;
    return 30;
  }

  static double _diversificationScore(Map<int, double> categorySpend, double totalExpense) {
    if (totalExpense == 0 || categorySpend.isEmpty) return 75;
    final values = categorySpend.values.toList();
    final maxCat = values.reduce(max);
    final ratio = maxCat / totalExpense;
    if (ratio <= 0.25) return 100;
    if (ratio <= 0.4) return 85;
    if (ratio <= 0.55) return 70;
    if (ratio <= 0.7) return 50;
    return 35;
  }

  static List<String> _suggestions(double savingsRate, double budgetScore, double trendScore, double liquidityScore, double diversificationScore) {
    List<String> suggestions = [];
    if (savingsRate < 10) suggestions.add("Try to save at least 10% of your income each month.");
    if (budgetScore < 70) suggestions.add("Some categories are over budget. Review your budget limits.");
    if (trendScore < 70) suggestions.add("Your spending is trending up. Look for areas to cut back.");
    if (liquidityScore < 70) suggestions.add("Build an emergency fund covering at least 3 months of expenses.");
    if (diversificationScore < 70) suggestions.add("A large portion of spending is in one category. Diversify if possible.");
    if (suggestions.isEmpty) suggestions.add("Great financial health! Keep up the good habits.");
    return suggestions;
  }
}

class FinancialHealth {
  final int score;
  final double savingsRate;
  final int savingsScore;
  final int budgetScore;
  final int trendScore;
  final int liquidityScore;
  final int diversificationScore;
  final List<String> suggestions;

  FinancialHealth({
    required this.score,
    required this.savingsRate,
    required this.savingsScore,
    required this.budgetScore,
    required this.trendScore,
    required this.liquidityScore,
    required this.diversificationScore,
    required this.suggestions,
  });
}
