import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/recurring.model.dart';
import 'package:fintracker/services/receipt_scanner_service.dart';
import 'package:image_picker/image_picker.dart';

class SubscriptionScannerService {
  static Future<RecurringTransaction?> scan({
    required ImageSource source,
    required Account fallbackAccount,
    required Category fallbackCategory,
  }) async {
    final result = source == ImageSource.camera
        ? await ReceiptScannerService.scanFromCamera()
        : await ReceiptScannerService.scanFromGallery();

    if (result.error != null || result.isEmpty || result.total == 0) return null;

    return RecurringTransaction(
      account: fallbackAccount,
      category: fallbackCategory,
      amount: result.total,
      type: 'DR',
      title: result.merchant.isNotEmpty ? result.merchant : 'Scanned subscription',
      description: 'Scanned from receipt',
      interval: RecurringInterval.monthly,
      startDate: result.date,
      nextDueDate: result.date,
    );
  }
}
