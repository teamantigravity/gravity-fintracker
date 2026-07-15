import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/subscription.model.dart';

class SubscriptionIntelligenceService {
  static Future<SubscriptionSummary> analyze() async {
    final payments = await PaymentDao().find();
    return _process(payments);
  }

  static SubscriptionSummary _process(List<Payment> payments) {
    // Group by normalized title and type
    final Map<String, List<Payment>> groups = {};
    for (final payment in payments) {
      final key = _normalize('${payment.title}_${payment.type == PaymentType.credit ? 'CR' : 'DR'}');
      groups.putIfAbsent(key, () => []).add(payment);
    }

    final List<Subscription> subscriptions = [];
    final Map<String, List<Payment>> duplicateGroups = {};

    for (final entry in groups.entries) {
      final list = entry.value;
      list.sort((a, b) => a.datetime.compareTo(b.datetime));

      if (list.length < 2) continue;

      final frequency = _estimateFrequency(list);
      final monthlyCost = _toMonthlyCost(list.last.amount, frequency);
      final yearlyCost = monthlyCost * 12;
      final last = list.last;
      final nextDue = _estimateNextDue(list, frequency);

      double? priceChangePercent;
      String? priceChangeDirection;
      if (list.length >= 2) {
        final prev = list[list.length - 2];
        if (prev.amount != 0 && last.amount != prev.amount) {
          priceChangePercent = ((last.amount - prev.amount) / prev.amount) * 100;
          priceChangeDirection = priceChangePercent > 0 ? 'up' : 'down';
        }
      }

      final isOverdue = nextDue != null && nextDue.isBefore(DateTime.now());
      final isPossiblyUnused = nextDue != null &&
          DateTime.now().difference(nextDue).inDays > 15;

      subscriptions.add(Subscription(
        title: last.title,
        amount: last.amount,
        type: last.type == PaymentType.credit ? 'CR' : 'DR',
        category: last.category,
        account: last.account,
        frequency: frequency,
        lastPaid: last.datetime,
        nextDue: nextDue,
        occurrenceCount: list.length,
        monthlyCost: monthlyCost,
        yearlyCost: yearlyCost,
        priceChangePercent: priceChangePercent,
        priceChangeDirection: priceChangeDirection,
        isOverdue: isOverdue,
        isPossiblyUnused: isPossiblyUnused,
      ));

      final dupKey = _normalize('${last.amount}_${last.type == PaymentType.credit ? 'CR' : 'DR'}');
      duplicateGroups.putIfAbsent(dupKey, () => []).add(last);
    }

    // Mark duplicates: same amount and same normalized title with different categories
    for (final subscription in subscriptions) {
      final dupKey = _normalize('${subscription.amount}_${subscription.type}');
      final group = duplicateGroups[dupKey];
      if (group != null && group.length > 1) {
        subscription.hasDuplicate = true;
      }
    }

    subscriptions.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));

    final priceChanges = subscriptions.where((s) => s.priceChangePercent != null).toList();
    final duplicates = subscriptions.where((s) => s.hasDuplicate).toList();
    final possiblyUnused = subscriptions.where((s) => s.isPossiblyUnused).toList();
    final overdue = subscriptions.where((s) => s.isOverdue).toList();

    final monthlySpend = subscriptions.where((s) => s.type == 'DR').fold<double>(0, (sum, s) => sum + s.monthlyCost);
    final yearlySpend = subscriptions.where((s) => s.type == 'DR').fold<double>(0, (sum, s) => sum + s.yearlyCost);

    return SubscriptionSummary(
      totalSubscriptions: subscriptions.length,
      monthlySpend: monthlySpend,
      yearlySpend: yearlySpend,
      subscriptions: subscriptions,
      priceChanges: priceChanges,
      duplicates: duplicates,
      possiblyUnused: possiblyUnused,
      overdue: overdue,
    );
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  static String _estimateFrequency(List<Payment> payments) {
    if (payments.length < 2) return 'irregular';
    final diffs = <int>[];
    for (int i = 1; i < payments.length; i++) {
      diffs.add(payments[i].datetime.difference(payments[i - 1].datetime).inDays);
    }
    final avg = diffs.reduce((a, b) => a + b) / diffs.length;

    if (avg < 2) return 'daily';
    if (avg < 10) return 'weekly';
    if (avg < 40) return 'monthly';
    if (avg < 80) return 'bi-monthly';
    if (avg < 400) return 'yearly';
    return 'irregular';
  }

  static DateTime? _estimateNextDue(List<Payment> payments, String frequency) {
    if (payments.isEmpty) return null;
    final last = payments.last.datetime;
    switch (frequency) {
      case 'daily':
        return last.add(const Duration(days: 1));
      case 'weekly':
        return last.add(const Duration(days: 7));
      case 'bi-monthly':
        return last.add(const Duration(days: 60));
      case 'monthly':
        return DateTime(last.year, last.month + 1, last.day);
      case 'yearly':
        return DateTime(last.year + 1, last.month, last.day);
      default:
        return null;
    }
  }

  static double _toMonthlyCost(double amount, String frequency) {
    if (amount <= 0) return 0;
    switch (frequency) {
      case 'daily':
        return amount * 30;
      case 'weekly':
        return amount * 4.33;
      case 'bi-monthly':
        return amount / 2;
      case 'monthly':
        return amount;
      case 'yearly':
        return amount / 12;
      default:
        return amount;
    }
  }
}
