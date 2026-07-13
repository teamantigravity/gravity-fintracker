import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/services/voice_transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../screens/premium/paywall.screen.dart';

class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService().canUseVoiceInput) {
      return IconButton(
        icon: const Icon(Symbols.mic),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
      );
    }

    return IconButton(
      icon: const Icon(Symbols.mic),
      onPressed: () => _listen(context),
      tooltip: 'Voice input',
    );
  }

  Future<void> _listen(BuildContext context) async {
    if (!VoiceTransactionService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input is not supported on this device.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Listening...'),
          ],
        ),
      ),
    );

    final result = await VoiceTransactionService.listen();

    if (context.mounted) Navigator.pop(context);

    if (result.error != null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentForm(
            type: result.type == 'CR' ? PaymentType.credit : PaymentType.debit,
            prefillTitle: result.title,
            prefillAmount: result.amount,
          ),
        ),
      );
    }
  }
}
