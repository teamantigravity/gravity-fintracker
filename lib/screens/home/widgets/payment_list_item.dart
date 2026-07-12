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
    final hasTitle = payment.title.trim().isNotEmpty;
    final primaryText = hasTitle ? payment.title : payment.category.name;
    final time = DateFormat("HH:mm").format(payment.datetime);
    final subtitleText = hasTitle ? "${payment.category.name} · $time" : time;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      onTap: onTap,
      leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: payment.category.color.withOpacity(0.1),
          ),
          child:  Icon( payment.category.icon, size: 22, color: payment.category.color,)
      ),
      title: Text(primaryText, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500)),),
      subtitle: Text(
        subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.grey),
      ),
      trailing: CurrencyText(
          isCredit? payment.amount : -payment.amount,
          style: Theme.of(context).textTheme.bodyMedium?.apply(color: isCredit? ThemeColors.success:ThemeColors.error, fontWeightDelta: 1)
      ),
    ) ;
  }

}