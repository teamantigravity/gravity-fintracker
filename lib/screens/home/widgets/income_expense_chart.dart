import 'package:fl_chart/fl_chart.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/config/app_date_formats.dart';
import 'package:fintracker/config/strings.dart';
import 'package:intl/intl.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<Payment> payments;
  const IncomeExpenseChart({super.key, required this.payments});

  Map<String, _DayData> _getDailyBreakdown() {
    final Map<String, _DayData> daily = {};
    for (final payment in payments) {
      final String key = DateFormat(AppDateFormats.isoDate).format(payment.datetime);
      final day = daily.putIfAbsent(key, () => _DayData(date: payment.datetime));
      if (payment.type == PaymentType.credit) {
        day.income += payment.amount;
      } else {
        day.expense += payment.amount;
      }
    }
    return daily;
  }

  @override
  Widget build(BuildContext context) {
    final daily = _getDailyBreakdown();
    if (daily.isEmpty) return const SizedBox.shrink();

    final sortedKeys = daily.keys.toList()..sort();
    final displayKeys = sortedKeys.length > 7
        ? sortedKeys.sublist(sortedKeys.length - 7)
        : sortedKeys;

    double maxY = 0;
    for (final key in displayKeys) {
      final data = daily[key];
      if (data == null) continue;
      if (data.income > maxY) maxY = data.income;
      if (data.expense > maxY) maxY = data.expense;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                Strings.dailyOverview,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              const _LegendDot(color: AppTheme.incomeColor, label: 'Income'),
              const SizedBox(width: 12),
              const _LegendDot(color: AppTheme.expenseColor, label: 'Expense'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final String label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label\n${rod.toY.toStringAsFixed(0)}',
                        TextStyle(
                          color: rod.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < displayKeys.length) {
                          final day = daily[displayKeys[index]];
                          if (day == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat(AppDateFormats.shortDate).format(day.date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: () {
                  final groups = <BarChartGroupData>[];
                  for (int i = 0; i < displayKeys.length; i++) {
                    final data = daily[displayKeys[i]];
                    if (data == null) continue;
                    groups.add(BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.income,
                          color: AppTheme.incomeColor.withValues(alpha: 0.8),
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: data.expense,
                          color: AppTheme.expenseColor.withValues(alpha: 0.8),
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ));
                  }
                  return groups;
                }(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _DayData {
  final DateTime date;
  double income = 0;
  double expense = 0;

  _DayData({required this.date});
}
