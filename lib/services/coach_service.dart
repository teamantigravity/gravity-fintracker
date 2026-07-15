import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/model/payment.model.dart';

class CoachService {
  static Future<List<CoachMessage>> generateInsights() async {
    final payments = await PaymentDao().find();
    final accounts = await AccountDao().find(withSummery: true);
    final categories = await CategoryDao().find();
    final recurring = await RecurringDao().find();

    List<CoachMessage> messages = [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    double income = 0;
    double expense = 0;
    Map<String, double> categorySpend = {};
    for (final p in payments) {
      if (p.type == PaymentType.credit) {
        income += p.amount;
      }
      if (p.type == PaymentType.debit) {
        expense += p.amount;
        categorySpend[p.category.name] = (categorySpend[p.category.name] ?? 0) + p.amount;
      }
    }

    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    for (final p in payments) {
      if (p.datetime.isAfter(monthStart) || p.datetime.isAtSameMomentAs(monthStart)) {
        if (p.type == PaymentType.credit) {
          thisMonthIncome += p.amount;
        } else {
          thisMonthExpense += p.amount;
        }
      }
    }

    final balance = accounts.fold<double>(0, (s, a) => s + (a.balance ?? 0));
    final activeRecurring = recurring.where((r) => r.isActive).toList();
    final monthlyRecurringOut = activeRecurring
        .where((r) => r.type == 'DR')
        .fold<double>(0, (s, r) => s + r.amount);

    // Greeting
    messages.add(CoachMessage(
      type: CoachMessageType.greeting,
      text: "Here is your personalized financial summary. Everything is computed on your device.",
    ));

    // Summary
    messages.add(CoachMessage(
      type: CoachMessageType.insight,
      text: "Your current net balance across all accounts is ${_formatCurrency(balance)}. This month, you earned ${_formatCurrency(thisMonthIncome)} and spent ${_formatCurrency(thisMonthExpense)}.",
    ));

    // Savings
    if (thisMonthIncome > 0) {
      final rate = ((thisMonthIncome - thisMonthExpense) / thisMonthIncome) * 100;
      if (rate >= 20) {
        messages.add(CoachMessage(
          type: CoachMessageType.positive,
          text: "Great job! You're saving ${rate.toStringAsFixed(0)}% of your income. Keep it up.",
        ));
      } else if (rate < 0) {
        messages.add(CoachMessage(
          type: CoachMessageType.warning,
          text: "You're spending more than you earn this month. Consider reviewing non-essential expenses.",
        ));
      } else {
        messages.add(CoachMessage(
          type: CoachMessageType.tip,
          text: "You're saving ${rate.toStringAsFixed(0)}% of your income. Aim for 20% or more to build a healthy cushion.",
        ));
      }
    }

    // Recurring commitments
    if (monthlyRecurringOut > 0) {
      messages.add(CoachMessage(
        type: CoachMessageType.tip,
        text: "You have ${activeRecurring.where((r) => r.type == 'DR').length} active recurring expenses totaling ${_formatCurrency(monthlyRecurringOut)} each cycle.",
      ));
    }

    // Top category
    if (categorySpend.isNotEmpty) {
      final sorted = categorySpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      messages.add(CoachMessage(
        type: CoachMessageType.insight,
        text: "Your biggest spending category is ${top.key} at ${_formatCurrency(top.value)}. That's ${(top.value / max(expense, 1) * 100).toStringAsFixed(0)}% of your total spending.",
      ));
    }

    // Budget warnings
    for (final c in categories) {
      final budget = c.budget;
      if (budget == null || budget <= 0) continue;
      final spend = categorySpend[c.name] ?? 0;
      if (spend > budget) {
        messages.add(CoachMessage(
          type: CoachMessageType.warning,
          text: "${c.name} is over budget. You've spent ${_formatCurrency(spend)} of ${_formatCurrency(budget)}.",
        ));
      }
    }

    // Net cashflow forecast
    final projectedNet = income - expense;
    if (projectedNet >= 0) {
      messages.add(CoachMessage(
        type: CoachMessageType.positive,
        text: "Your tracked cashflow is positive. If you keep this pace, you will grow your balance by ${_formatCurrency(projectedNet)} over the current period.",
      ));
    } else {
      messages.add(CoachMessage(
        type: CoachMessageType.warning,
        text: "Your tracked cashflow is negative. Look for recurring subscriptions or discretionary spending you can reduce.",
      ));
    }

    // Personalized tip
    if (expense > income && monthlyRecurringOut > 0) {
      messages.add(CoachMessage(
        type: CoachMessageType.tip,
        text: "Try a 'subscription audit' — cancel services you haven't used in the last 30 days.",
      ));
    }

    return messages;
  }

  static String _formatCurrency(double value) {
    return value.toStringAsFixed(0);
  }

  static double max(double a, double b) => a > b ? a : b;
}

enum CoachMessageType { greeting, insight, positive, warning, tip }

class CoachMessage {
  final CoachMessageType type;
  final String text;

  CoachMessage({required this.type, required this.text});
}
