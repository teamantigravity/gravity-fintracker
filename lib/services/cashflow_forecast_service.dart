import 'dart:math';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/recurring.model.dart';

class CashflowForecastService {
  static Future<CashflowForecast> forecast({int days = 90}) async {
    final payments = await PaymentDao().find();
    final accounts = await AccountDao().find(withSummery: true);
    final recurring = await RecurringDao().find();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double currentBalance = accounts.fold<double>(0, (s, a) => s + (a.balance ?? 0));

    // Daily averages from last 90 days
    final rangeStart = today.subtract(const Duration(days: 90));
    final creditDays = <String, double>{};
    final debitDays = <String, double>{};
    for (final p in payments) {
      if (p.datetime.isBefore(rangeStart) || p.datetime.isAfter(today)) continue;
      final key = _dateKey(p.datetime);
      if (p.type == PaymentType.credit) {
        creditDays[key] = (creditDays[key] ?? 0) + p.amount;
      } else {
        debitDays[key] = (debitDays[key] ?? 0) + p.amount;
      }
    }
    final dailyIncome = creditDays.isEmpty ? 0.0 : creditDays.values.reduce((a, b) => a + b) / max(1, creditDays.length);
    final dailyExpense = debitDays.isEmpty ? 0.0 : debitDays.values.reduce((a, b) => a + b) / max(1, debitDays.length);

    List<DailyBalance> forecast = [];
    double running = currentBalance;
    forecast.add(DailyBalance(date: today, balance: running));

    for (int i = 1; i <= days; i++) {
      final date = today.add(Duration(days: i));
      double recurringNet = 0;
      for (final r in recurring) {
        if (!r.isActive) continue;
        final next = _nextDueDateOnOrBefore(r, date, r.startDate);
        if (next != null && next.year == date.year && next.month == date.month && next.day == date.day) {
          if (r.type == 'CR') {
            recurringNet += r.amount;
          } else {
            recurringNet -= r.amount;
          }
        }
      }
      running += dailyIncome - dailyExpense + recurringNet;
      forecast.add(DailyBalance(date: date, balance: running));
    }

    final minBalance = forecast.map((f) => f.balance).reduce(min);
    final lowBalanceDates = forecast.where((f) => f.balance < 0).map((f) => f.date).toList();

    return CashflowForecast(
      currentBalance: currentBalance,
      dailyIncome: dailyIncome,
      dailyExpense: dailyExpense,
      forecast: forecast,
      minProjectedBalance: minBalance,
      lowBalanceDates: lowBalanceDates,
    );
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static DateTime? _nextDueDateOnOrBefore(RecurringTransaction r, DateTime target, DateTime start) {
    if (target.isBefore(start)) return null;
    final current = r.nextDueDate ?? start;
    if (current.isAfter(target)) return null;
    // Use the recurring object's own logic to project the next occurrence.
    // We approximate by taking the start date and adding intervals.
    DateTime cursor = DateTime(start.year, start.month, start.day);
    while (cursor.isBefore(target) || cursor.isAtSameMomentAs(target)) {
      final candidate = DateTime(cursor.year, cursor.month, cursor.day);
      if (candidate.year == target.year && candidate.month == target.month && candidate.day == target.day) return candidate;
      cursor = _addInterval(cursor, r.interval);
    }
    return null;
  }

  static DateTime _addInterval(DateTime d, RecurringInterval interval) {
    switch (interval) {
      case RecurringInterval.daily:
        return d.add(const Duration(days: 1));
      case RecurringInterval.weekly:
        return d.add(const Duration(days: 7));
      case RecurringInterval.monthly:
        final lastDay = DateTime(d.year, d.month + 2, 0).day;
        final day = d.day <= lastDay ? d.day : lastDay;
        return DateTime(d.year, d.month + 1, day);
      case RecurringInterval.yearly:
        final lastDay = DateTime(d.year + 1, d.month + 1, 0).day;
        final day = d.day <= lastDay ? d.day : lastDay;
        return DateTime(d.year + 1, d.month, day);
    }
  }
}

class CashflowForecast {
  final double currentBalance;
  final double dailyIncome;
  final double dailyExpense;
  final List<DailyBalance> forecast;
  final double minProjectedBalance;
  final List<DateTime> lowBalanceDates;

  CashflowForecast({
    required this.currentBalance,
    required this.dailyIncome,
    required this.dailyExpense,
    required this.forecast,
    required this.minProjectedBalance,
    required this.lowBalanceDates,
  });
}

class DailyBalance {
  final DateTime date;
  final double balance;

  DailyBalance({required this.date, required this.balance});
}
