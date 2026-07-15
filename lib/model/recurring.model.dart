import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:intl/intl.dart';

enum RecurringInterval { daily, weekly, monthly, yearly }

class RecurringTransaction {
  int? id;
  Account account;
  Category category;
  double amount;
  String type; // CR or DR
  String title;
  String description;
  RecurringInterval interval;
  DateTime startDate;
  DateTime? nextDueDate;
  bool isActive;

  RecurringTransaction({
    this.id,
    required this.account,
    required this.category,
    required this.amount,
    required this.type,
    required this.title,
    required this.description,
    required this.interval,
    required this.startDate,
    this.nextDueDate,
    this.isActive = true,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> data) {
    return RecurringTransaction(
      id: data["id"],
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      account: Account.fromJson(data["account"] is Map ? data["account"] : {"id": data["account"]}),
      category: Category.fromJson(data["category"] is Map ? data["category"] : {"id": data["category"]}),
      amount: (data["amount"] as num?)?.toDouble() ?? 0.0,
      type: data["type"] ?? "DR",
      interval: _parseInterval(data["interval"]),
      startDate: DateTime.tryParse(data["startDate"] ?? '') ?? DateTime.now(),
      nextDueDate: data["nextDueDate"] != null ? (DateTime.tryParse(data["nextDueDate"].toString()) ?? DateTime.now()) : null,
      isActive: data["isActive"] == true || data["isActive"] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "account": account.id,
        "category": category.id,
        "amount": amount,
        "type": type,
        "interval": interval.name,
        "startDate": DateFormat('yyyy-MM-dd').format(startDate),
        "nextDueDate": nextDueDate != null ? DateFormat('yyyy-MM-dd').format(nextDueDate!) : null,
        "isActive": isActive ? 1 : 0,
      };

  DateTime calculateNextDueDate() {
    DateTime from = nextDueDate ?? startDate;
    switch (interval) {
      case RecurringInterval.daily:
        return from.add(const Duration(days: 1));
      case RecurringInterval.weekly:
        return from.add(const Duration(days: 7));
      case RecurringInterval.monthly:
        final targetDay = startDate.day;
        final lastDay = DateTime(from.year, from.month + 2, 0).day;
        final day = targetDay <= lastDay ? targetDay : lastDay;
        return DateTime(from.year, from.month + 1, day);
      case RecurringInterval.yearly:
        final targetDay = startDate.day;
        final lastDay = DateTime(from.year + 1, from.month + 1, 0).day;
        final day = targetDay <= lastDay ? targetDay : lastDay;
        return DateTime(from.year + 1, from.month, day);
    }
  }

  static RecurringInterval _parseInterval(String? value) {
    switch (value) {
      case 'daily':
        return RecurringInterval.daily;
      case 'weekly':
        return RecurringInterval.weekly;
      case 'monthly':
        return RecurringInterval.monthly;
      case 'yearly':
        return RecurringInterval.yearly;
      default:
        return RecurringInterval.monthly;
    }
  }

  String get intervalLabel {
    switch (interval) {
      case RecurringInterval.daily:
        return 'Daily';
      case RecurringInterval.weekly:
        return 'Weekly';
      case RecurringInterval.monthly:
        return 'Monthly';
      case RecurringInterval.yearly:
        return 'Yearly';
    }
  }
}
