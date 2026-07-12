import 'package:fl_chart/fl_chart.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SpendingChart extends StatefulWidget {
  final List<Payment> payments;
  const SpendingChart({super.key, required this.payments});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _touchedIndex = -1;

  Map<String, _CategorySpend> _getCategoryBreakdown() {
    Map<String, _CategorySpend> breakdown = {};
    for (var payment in widget.payments) {
      if (payment.type == PaymentType.debit) {
        String name = payment.category.name;
        if (breakdown.containsKey(name)) {
          breakdown[name]!.amount += payment.amount;
        } else {
          breakdown[name] = _CategorySpend(
            name: name,
            amount: payment.amount,
            color: payment.category.color,
          );
        }
      }
    }
    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _getCategoryBreakdown();
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = breakdown.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = entries.fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spending Breakdown",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: List.generate(entries.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final fontSize = isTouched ? 14.0 : 11.0;
                        final radius = isTouched ? 50.0 : 42.0;
                        final percentage = (entries[i].amount / total * 100);

                        return PieChartSectionData(
                          color: entries[i].color.withOpacity(isTouched ? 1 : 0.85),
                          value: entries[i].amount,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          titlePositionPercentageOffset: 0.55,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      min(entries.length, 5),
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entries[i].color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entries[i].name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: _touchedIndex == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpend {
  final String name;
  double amount;
  final Color color;

  _CategorySpend({
    required this.name,
    required this.amount,
    required this.color,
  });
}
