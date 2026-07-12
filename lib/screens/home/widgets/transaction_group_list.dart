import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/home/widgets/payment_list_item.dart';
import 'package:fintracker/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders transactions grouped under human-friendly date headers
/// (Today / Yesterday / weekday / date), instead of one flat list — gives
/// the list rhythm and makes scanning recent activity much faster.
class TransactionGroupList extends StatelessWidget {
  final List<Payment> payments;
  final void Function(Payment payment) onTap;

  const TransactionGroupList({super.key, required this.payments, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // `payments` is already sorted DESC by datetime from the DAO, so a
    // single linear pass is enough to build contiguous date groups.
    final List<_Group> groups = [];
    for (final payment in payments) {
      final label = _dateLabel(payment.datetime);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_Group(label));
      }
      groups.last.payments.add(payment);
    }

    int flatIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                group.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...group.payments.map((payment) {
              final item = StaggeredFadeIn(
                index: flatIndex,
                child: PaymentListItem(payment: payment, onTap: () => onTap(payment)),
              );
              flatIndex++;
              return item;
            }),
          ],
        );
      }).toList(),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    if (diff < 7 && diff > 0) return DateFormat('EEEE').format(date);
    return DateFormat('EEE, d MMM').format(date);
  }
}

class _Group {
  final String label;
  final List<Payment> payments = [];
  _Group(this.label);
}
