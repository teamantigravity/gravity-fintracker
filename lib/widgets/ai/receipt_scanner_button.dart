import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/services/receipt_scanner_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../screens/premium/paywall.screen.dart';

class ReceiptScannerButton extends StatelessWidget {
  const ReceiptScannerButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService().canUseReceiptScanner) {
      return IconButton(
        icon: const Icon(Symbols.receipt_long),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
      );
    }

    return IconButton(
      icon: const Icon(Symbols.receipt_long),
      onPressed: () => _scan(context),
      tooltip: 'Scan receipt',
    );
  }

  Future<void> _scan(BuildContext context) async {
    if (!ReceiptScannerService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt scanning is only available on mobile devices.')));
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Symbols.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final result = source == ImageSource.camera
        ? await ReceiptScannerService.scanFromCamera()
        : await ReceiptScannerService.scanFromGallery();

    final error = result.error;
    if (error != null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (result.isEmpty) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No receipt details found. Please enter manually.')));
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentForm(
            type: PaymentType.debit,
            prefillTitle: result.merchant,
            prefillAmount: result.total,
            prefillDate: result.date,
          ),
        ),
      );
    }
  }
}

enum ImageSource { camera, gallery }
