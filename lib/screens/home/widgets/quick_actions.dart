import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Two unambiguous primary actions, replacing a single FAB that silently
/// defaulted every tap to an income entry (the less common action for most
/// users logging day-to-day spending).
class QuickActions extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;

  const QuickActions({super.key, required this.onAddExpense, required this.onAddIncome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: "Add Expense",
              icon: Symbols.remove_circle,
              color: const Color(0xFFEA4335),
              onTap: onAddExpense,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: "Add Income",
              icon: Symbols.add_circle,
              color: const Color(0xFF34A853),
              onTap: onAddIncome,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color, fill: 1),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
