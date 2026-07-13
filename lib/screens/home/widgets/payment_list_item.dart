import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';

class PaymentListItem extends StatelessWidget{
  final Payment payment;
  final VoidCallback onTap;
  const PaymentListItem({super.key, required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isCredit = payment.type == PaymentType.credit ;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onTap: onTap,
      leading: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: payment.category.color.withOpacity(0.12),
        ),
        child: Icon(payment.category.icon, size: 22, color: payment.category.color),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: payment.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              payment.category.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: payment.category.color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: DateFormat("dd MMM • HH:mm").format(payment.datetime)),
            if (payment.account.name.isNotEmpty)
              TextSpan(text: " • ${payment.account.name}"),
          ],
          style: theme.textTheme.bodySmall?.apply(color: colorScheme.onSurface.withOpacity(0.5), overflow: TextOverflow.ellipsis),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCredit ? ThemeColors.success.withOpacity(0.08) : ThemeColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CurrencyText(
          isCredit ? payment.amount : -payment.amount,
          style: theme.textTheme.bodyMedium?.apply(
            color: isCredit ? ThemeColors.success : ThemeColors.error,
            fontWeightDelta: 1,
          ),
        ),
      ),
    );
  }
}