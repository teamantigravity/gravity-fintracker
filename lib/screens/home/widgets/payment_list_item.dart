import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/theme/colors.dart';
import 'package:fintracker/ui/prism.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/config/app_date_formats.dart';
import 'package:intl/intl.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;
  const PaymentListItem({super.key, required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = payment.type == PaymentType.credit;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountColor = isCredit ? ThemeColors.success : ThemeColors.error;

    return PrismListTile(
      onTap: onTap,
      leading: PrismAvatar(
        icon: payment.category.icon,
        color: payment.category.color,
        size: 48,
        shape: BoxShape.rectangle,
        borderRadius: PrismTokens.radiusSm,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              payment.title.isNotEmpty ? payment.title : payment.category.name,
              style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w600)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PrismChip(
            label: payment.category.name,
            color: payment.category.color,
            isSmall: true,
          ),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: DateFormat(AppDateFormats.mediumDateTime).format(payment.datetime)),
            if (payment.account.name.isNotEmpty)
              TextSpan(text: ' • ${payment.account.name}'),
          ],
          style: theme.textTheme.bodySmall?.apply(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CurrencyText(
          isCredit ? payment.amount : -payment.amount,
          style: theme.textTheme.bodyMedium?.apply(
            color: amountColor,
            fontWeightDelta: 1,
          ),
        ),
      ),
    );
  }
}