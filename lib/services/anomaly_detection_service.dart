import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/model/payment.model.dart';

class AnomalyDetectionService {
  static Future<List<Anomaly>> detect() async {
    final payments = await PaymentDao().find();
    final List<Anomaly> anomalies = [];

    if (payments.isEmpty) return anomalies;

    // Unusual expense > 3x average expense
    final expenses = payments.where((p) => p.type == PaymentType.debit).toList();
    if (expenses.isNotEmpty) {
      final total = expenses.fold<double>(0, (s, p) => s + p.amount);
      final avg = total / expenses.length;
      for (final p in expenses) {
        if (p.amount > avg * 3 && p.amount > avg + 10) {
          anomalies.add(Anomaly(
            type: AnomalyType.unusualAmount,
            title: 'Unusual expense',
            description: '${p.title} is ${p.amount.toStringAsFixed(0)} — more than 3x your average of ${avg.toStringAsFixed(0)}.',
            payment: p,
            severity: Severity.high,
          ));
        }
      }
    }

    // Category spike: month-over-month category spend > 50% increase
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final prevMonthStart = DateTime(now.year, now.month - 1);
    final Map<int, double> thisMonth = {};
    final Map<int, double> lastMonth = {};
    for (final p in expenses) {
      if (p.datetime.isAfter(monthStart) || p.datetime.isAtSameMomentAs(monthStart)) {
        thisMonth[p.category.id ?? 0] = (thisMonth[p.category.id ?? 0] ?? 0) + p.amount;
      } else if (p.datetime.isAfter(prevMonthStart) && p.datetime.isBefore(monthStart)) {
        lastMonth[p.category.id ?? 0] = (lastMonth[p.category.id ?? 0] ?? 0) + p.amount;
      }
    }
    for (final entry in thisMonth.entries) {
      final prev = lastMonth[entry.key] ?? 0;
      if (prev > 0 && entry.value > prev * 1.5) {
        final catPayment = expenses.firstWhere(
          (p) => p.category.id == entry.key,
          orElse: () => expenses.first,
        );
        final catName = catPayment.category.name;
        anomalies.add(Anomaly(
          type: AnomalyType.categorySpike,
          title: 'Spike in $catName',
          description: 'This month you spent ${entry.value.toStringAsFixed(0)} — up ${((entry.value / prev - 1) * 100).toStringAsFixed(0)}% from last month.',
          severity: Severity.medium,
        ));
      }
    }

    // Duplicate detection: same amount, title, and category within same day
    final Map<String, List<Payment>> buckets = {};
    for (final p in payments) {
      final key = '${p.amount}_${p.title.toLowerCase().trim()}_${p.category.id}_${DateTime(p.datetime.year, p.datetime.month, p.datetime.day)}';
      buckets.putIfAbsent(key, () => []).add(p);
    }
    for (final entry in buckets.entries) {
      if (entry.value.length > 1) {
        final p = entry.value.first;
        anomalies.add(Anomaly(
          type: AnomalyType.duplicate,
          title: 'Possible duplicate',
          description: 'Found ${entry.value.length} transactions for "${p.title}" of ${p.amount.toStringAsFixed(0)} on the same day.',
          payment: p,
          severity: Severity.low,
        ));
      }
    }

    // Daily streak: spending 7+ days in a row
    final spendDays = expenses.map((p) => DateTime(p.datetime.year, p.datetime.month, p.datetime.day)).toSet().toList();
    spendDays.sort();
    int streak = 0;
    for (int i = 1; i < spendDays.length; i++) {
      if (spendDays[i].difference(spendDays[i - 1]).inDays == 1) {
        streak++;
      } else {
        streak = 0;
      }
      if (streak >= 6) {
        anomalies.add(Anomaly(
          type: AnomalyType.spendingStreak,
          title: 'Spending streak',
          description: 'You spent money on ${streak + 1} consecutive days. Consider a no-spend day to reset.',
          severity: Severity.low,
        ));
        break;
      }
    }

    return anomalies;
  }
}

enum AnomalyType { unusualAmount, categorySpike, duplicate, spendingStreak }
enum Severity { low, medium, high }

class Anomaly {
  final AnomalyType type;
  final String title;
  final String description;
  final Payment? payment;
  final Severity severity;

  Anomaly({
    required this.type,
    required this.title,
    required this.description,
    this.payment,
    required this.severity,
  });
}
