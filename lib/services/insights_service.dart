import 'package:fintracker/model/payment.model.dart';

/// Local-only smart insights engine
/// All computation happens on-device — zero data leaves the app
class InsightsService {
  static List<SpendingInsight> analyze(List<Payment> payments) {
    if (payments.isEmpty) return [];
    List<SpendingInsight> insights = [];

    // Separate income and expenses
    final expenses = payments.where((p) => p.type == PaymentType.debit).toList();
    final income = payments.where((p) => p.type == PaymentType.credit).toList();

    double totalExpense = expenses.fold(0.0, (sum, p) => sum + p.amount);
    double totalIncome = income.fold(0.0, (sum, p) => sum + p.amount);

    // Insight: Savings rate
    if (totalIncome > 0) {
      double savingsRate = ((totalIncome - totalExpense) / totalIncome * 100);
      if (savingsRate > 30) {
        insights.add(SpendingInsight(
          type: InsightType.positive,
          title: "Great savings!",
          description: "You're saving ${savingsRate.toStringAsFixed(0)}% of your income. Keep it up!",
        ));
      } else if (savingsRate > 0) {
        insights.add(SpendingInsight(
          type: InsightType.neutral,
          title: "Room to save",
          description: "You're saving ${savingsRate.toStringAsFixed(0)}% — aim for 20%+ for financial health.",
        ));
      } else {
        insights.add(SpendingInsight(
          type: InsightType.warning,
          title: "Spending exceeds income",
          description: "You've spent more than you earned this period. Review your budget.",
        ));
      }
    }

    // Insight: Top spending category
    if (expenses.isNotEmpty) {
      Map<String, double> categorySpend = {};
      for (var p in expenses) {
        categorySpend[p.category.name] = (categorySpend[p.category.name] ?? 0) + p.amount;
      }
      var sorted = categorySpend.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sorted.isNotEmpty && totalExpense > 0) {
        double pct = (sorted.first.value / totalExpense * 100);
        insights.add(SpendingInsight(
          type: pct > 50 ? InsightType.warning : InsightType.neutral,
          title: "Top: ${sorted.first.key}",
          description: "${pct.toStringAsFixed(0)}% of spending goes to ${sorted.first.key}.",
        ));
      }

      // Insight: Spending diversity
      if (sorted.length >= 3 && totalExpense > 0 && sorted.first.value / totalExpense > 0.6) {
        insights.add(SpendingInsight(
          type: InsightType.tip,
          title: "Concentrated spending",
          description: "Most of your budget goes to one category. Consider diversifying.",
        ));
      }
    }

    // Insight: Transaction frequency
    if (expenses.length > 20) {
      insights.add(SpendingInsight(
        type: InsightType.neutral,
        title: "${expenses.length} transactions",
        description: "You're tracking actively — that's the first step to financial mastery.",
      ));
    }

    // Insight: Large transactions
    if (expenses.isNotEmpty) {
      double avg = totalExpense / expenses.length;
      var largeOnes = expenses.where((p) => p.amount > avg * 3).toList();
      if (largeOnes.isNotEmpty) {
        insights.add(SpendingInsight(
          type: InsightType.tip,
          title: "${largeOnes.length} large expense${largeOnes.length > 1 ? 's' : ''}",
          description: "You had ${largeOnes.length} transaction${largeOnes.length > 1 ? 's' : ''} over 3x your average. Worth reviewing.",
        ));
      }
    }

    return insights;
  }
}

enum InsightType { positive, neutral, warning, tip }

class SpendingInsight {
  final InsightType type;
  final String title;
  final String description;

  SpendingInsight({
    required this.type,
    required this.title,
    required this.description,
  });
}
