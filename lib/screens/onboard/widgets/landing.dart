import 'package:fintracker/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class LandingPage extends StatelessWidget{
  final VoidCallback onGetStarted;
  const LandingPage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Symbols.account_balance_wallet, size: 36, color: colorScheme.primary, fill: 1),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              _FeatureRow(
                icon: Symbols.shield,
                text: "Your data stays on your device. Always.",
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Symbols.bar_chart,
                text: "Beautiful charts and spending insights.",
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Symbols.sync,
                text: "Quantum-encrypted sync across all your devices.",
                color: colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              _FeatureRow(
                icon: Symbols.visibility_off,
                text: "Zero analytics. Zero tracking. Zero ads.",
                color: const Color(0xFFC62828),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onGetStarted,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Get Started", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Symbols.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "No account required. No data collected.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _FeatureRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18, fill: 1),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}