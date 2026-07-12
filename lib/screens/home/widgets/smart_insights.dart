import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/services/insights_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SmartInsightsCard extends StatelessWidget {
  final List<Payment> payments;
  const SmartInsightsCard({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final insights = InsightsService.analyze(payments);
    if (insights.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.auto_awesome, size: 18, color: colorScheme.primary, fill: 1),
              const SizedBox(width: 8),
              Text(
                "Smart Insights",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "LOCAL",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.take(3).map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _insightColor(insight.type),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _insightColor(insight.type),
                        ),
                      ),
                      Text(
                        insight.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _insightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return const Color(0xFF2E7D32);
      case InsightType.warning:
        return const Color(0xFFC62828);
      case InsightType.tip:
        return const Color(0xFF1565C0);
      case InsightType.neutral:
        return const Color(0xFF757575);
    }
  }
}
