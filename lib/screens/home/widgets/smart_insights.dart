import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/services/insights_service.dart';
import 'package:fintracker/services/forecasting_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SmartInsightsCard extends StatefulWidget {
  final List<Payment> payments;
  const SmartInsightsCard({super.key, required this.payments});

  @override
  State<SmartInsightsCard> createState() => _SmartInsightsCardState();
}

class _SmartInsightsCardState extends State<SmartInsightsCard> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final insights = InsightsService.analyze(widget.payments);
    final forecasts = ForecastingService.generateForecastInsights(widget.payments);
    final allInsights = [...forecasts, ...insights];
    if (allInsights.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Symbols.auto_awesome, size: 16, color: colorScheme.primary, fill: 1),
              const SizedBox(width: 6),
              Text(
                "Smart Insights",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
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
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: PageView.builder(
            controller: _controller,
            itemCount: allInsights.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _InsightCard(insight: allInsights[i]),
          ),
        ),
        if (allInsights.length > 1) ...[
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(allInsights.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _page == i ? 16 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? _insightColor(allInsights[i].type)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(60),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _insightColor(insight.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(_insightIcon(insight.type), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.35,
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

Color _insightColor(InsightType type) {
  switch (type) {
    case InsightType.positive:
      return const Color(0xFF34A853);
    case InsightType.warning:
      return const Color(0xFFEA4335);
    case InsightType.tip:
      return const Color(0xFF4285F4);
    case InsightType.neutral:
      return const Color(0xFFFBBC05);
  }
}

IconData _insightIcon(InsightType type) {
  switch (type) {
    case InsightType.positive:
      return Symbols.trending_up;
    case InsightType.warning:
      return Symbols.warning;
    case InsightType.tip:
      return Symbols.lightbulb;
    case InsightType.neutral:
      return Symbols.info;
  }
}
