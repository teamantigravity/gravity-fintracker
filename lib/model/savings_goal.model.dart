import 'package:fintracker/model/account.model.dart';

class SavingsGoal {
  int? id;
  String name;
  double targetAmount;
  double savedAmount;
  DateTime deadline;
  Account? account;
  int? icon;
  int? color;
  bool isArchived;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.deadline,
    this.account,
    this.icon,
    this.color,
    this.isArchived = false,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> data) {
    return SavingsGoal(
      id: data['id'],
      name: data['name'] ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: data['deadline'] != null ? DateTime.tryParse(data['deadline'].toString()) ?? DateTime.now() : DateTime.now(),
      account: data['account'] != null ? Account.fromJson(data['account'] is Map ? data['account'] : {'id': data['account']}) : null,
      icon: data['icon'],
      color: data['color'],
      isArchived: data['isArchived'] == 1 || data['isArchived'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline.toIso8601String(),
    'account': account?.id,
    'icon': icon,
    'color': color,
    'isArchived': isArchived ? 1 : 0,
  };

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => targetAmount - savedAmount;
  double get dailyRequired {
    final days = deadline.difference(DateTime.now()).inDays;
    if (days <= 0) return remainingAmount;
    return remainingAmount / days;
  }
}
