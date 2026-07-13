import 'package:fl_chart/fl_chart.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<Payment> payments;
  const IncomeExpenseChart({super.key, required this.payments});

  Map<String, _DayData> _getDailyBreakdown() {
    Map<String, _DayData> daily = {};
    for (var payment in payments) {
      String key = DateFormat('yyyy-MM-dd').format(payment.datetime);
      if (!daily.containsKey(key)) {
        daily[key] = _DayData(date: payment.datetime);
      }
      if (payment.type == PaymentType.credit) {
        daily[key]!.income += payment.amount;
      } else {
        daily[key]!.expense += payment.amount;
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
    for (var key in displayKeys) {
      double income = daily[key]!.income;
      double expense = daily[key]!.expense;
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;
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
                "Daily Overview",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              const _LegendDot(color: AppTheme.incomeColor, label: "Income"),
              const SizedBox(width: 12),
              const _LegendDot(color: AppTheme.expenseColor, label: "Expense"),
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
                      String label = rodIndex == 0 ? 'Income' : 'Expense';
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
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < displayKeys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('dd MMM').format(daily[displayKeys[index]]!.date),
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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayKeys.length, (i) {
                  final data = daily[displayKeys[i]]!;
                  return BarChartGroupData(
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
                  );
                }),
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
