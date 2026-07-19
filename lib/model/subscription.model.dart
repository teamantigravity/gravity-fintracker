import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';

class Subscription {
  final String title;
  final double amount;
  final String type; // CR or DR
  final Category? category;
  final Account? account;
  final String frequency; // daily, weekly, monthly, yearly, irregular
  final DateTime lastPaid;
  final DateTime? nextDue;
  final int occurrenceCount;
  final double monthlyCost;
  final double yearlyCost;
  final double? priceChangePercent;
  final String? priceChangeDirection;
  bool hasDuplicate;
  final bool isPossiblyUnused;
  final bool isOverdue;

  Subscription({
    required this.title,
    required this.amount,
    required this.type,
    this.category,
    this.account,
    required this.frequency,
    required this.lastPaid,
    this.nextDue,
    required this.occurrenceCount,
    required this.monthlyCost,
    required this.yearlyCost,
    this.priceChangePercent,
    this.priceChangeDirection,
    this.hasDuplicate = false,
    this.isPossiblyUnused = false,
    this.isOverdue = false,
  });
}

class SubscriptionSummary {
  final int totalSubscriptions;
  final double monthlySpend;
  final double yearlySpend;
  final List<Subscription> subscriptions;
  final List<Subscription> priceChanges;
  final List<Subscription> duplicates;
  final List<Subscription> possiblyUnused;
  final List<Subscription> overdue;

  SubscriptionSummary({
    required this.totalSubscriptions,
    required this.monthlySpend,
    required this.yearlySpend,
    required this.subscriptions,
    required this.priceChanges,
    required this.duplicates,
    required this.possiblyUnused,
    required this.overdue,
  });
}
