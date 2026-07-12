import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

/// The home screen's hero moment: one confident net-worth number, a
/// contextual delta, a genuine streak badge, and soft ambient color blobs
/// (in the four Google brand colors) for depth without noise.
class HeroHeader extends StatelessWidget {
  final String username;
  final double netWorth;
  final double periodIncome;
  final double periodExpense;
  final int streak;
  final bool showingCharts;
  final VoidCallback onToggleCharts;

  const HeroHeader({
    super.key,
    required this.username,
    required this.netWorth,
    required this.periodIncome,
    required this.periodExpense,
    required this.streak,
    required this.showingCharts,
    required this.onToggleCharts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double delta = periodIncome - periodExpense;
    final bool isPositive = delta >= 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ambient brand-color blobs — pure decoration, kept far below the
        // text in opacity so contrast/readability is never compromised.
        Positioned(
          top: -60,
          right: -40,
          child: _blob(const Color(0xFF4285F4), 160),
        ),
        Positioned(
          top: 10,
          left: -50,
          child: _blob(const Color(0xFF34A853), 120),
        ),

        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          username,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0) _StreakBadge(streak: streak),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: onToggleCharts,
                      icon: Icon(
                        showingCharts ? Symbols.list : Symbols.bar_chart,
                        fill: 1,
                        size: 22,
                      ),
                      tooltip: showingCharts ? "Show list" : "Show charts",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                "NET WORTH",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: netWorth),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CurrencyText(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isPositive ? Symbols.trending_up : Symbols.trending_down,
                    size: 16,
                    color: isPositive ? const Color(0xFF34A853) : const Color(0xFFEA4335),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: CurrencyText(
                      delta.abs(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPositive ? const Color(0xFF34A853) : const Color(0xFFEA4335),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    isPositive ? " saved this period" : " over budget this period",
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.16), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBC05).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.local_fire_department, size: 15, color: Color(0xFFFBBC05), fill: 1),
          const SizedBox(width: 3),
          Text(
            "$streak",
            style: const TextStyle(
              color: Color(0xFFFBBC05),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
