import 'package:fl_chart/fl_chart.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendChart extends StatelessWidget {
  final List<Payment> payments;
  const TrendChart({super.key, required this.payments});

  Map<String, _DayData> _getDailyBreakdown() {
    Map<String, _DayData> daily = {};
    List<Payment> sorted = [...payments]..sort((a, b) => a.datetime.compareTo(b.datetime));
    double runningBalance = 0;

    for (var payment in sorted) {
      String key = DateFormat('yyyy-MM-dd').format(payment.datetime);
      if (!daily.containsKey(key)) {
        daily[key] = _DayData(date: payment.datetime);
      }
      if (payment.type == PaymentType.credit) {
        daily[key]!.income += payment.amount;
        runningBalance += payment.amount;
      } else {
        daily[key]!.expense += payment.amount;
        runningBalance -= payment.amount;
      }
      daily[key]!.balance = runningBalance;
    }
    return daily;
  }

  @override
  Widget build(BuildContext context) {
    final daily = _getDailyBreakdown();
    if (daily.isEmpty) return const SizedBox.shrink();

    final sortedKeys = daily.keys.toList()..sort();
    final displayKeys = sortedKeys.length > 14
        ? sortedKeys.sublist(sortedKeys.length - 14)
        : sortedKeys;

    double maxY = 0;
    double minY = 0;
    for (var key in displayKeys) {
      double balance = daily[key]!.balance;
      if (balance > maxY) maxY = balance;
      if (balance < minY) minY = balance;
    }
    double range = maxY - minY;
    if (range == 0) range = 100;
    maxY += range * 0.1;
    minY -= range * 0.1;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Balance Trend",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              _LegendDot(color: AppTheme.incomeColor, label: "Income"),
              const SizedBox(width: 12),
              _LegendDot(color: AppTheme.expenseColor, label: "Expense"),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 0.8,
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
                          final day = daily[displayKeys[index]]!.date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('dd MMM').format(day),
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
                      interval: 1,
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
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toStringAsFixed(0),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(displayKeys.length, (i) {
                      return FlSpot(i.toDouble(), daily[displayKeys[i]]!.balance);
                    }),
                    isCurved: true,
                    color: AppTheme.incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.incomeColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(displayKeys.length, (i) {
                      return FlSpot(i.toDouble(), daily[displayKeys[i]]!.expense);
                    }),
                    isCurved: true,
                    color: AppTheme.expenseColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
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
  double balance = 0;

  _DayData({required this.date});
}
