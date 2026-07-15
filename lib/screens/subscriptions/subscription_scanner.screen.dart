import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/recurring.model.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/screens/recurring/recurring.screen.dart';
import 'package:fintracker/services/receipt_scanner_service.dart';
import 'package:fintracker/services/subscription_scanner_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class SubscriptionScannerScreen extends StatefulWidget {
  const SubscriptionScannerScreen({super.key});

  @override
  State<SubscriptionScannerScreen> createState() => _SubscriptionScannerScreenState();
}

class _SubscriptionScannerScreenState extends State<SubscriptionScannerScreen> {
  final RecurringDao _recurringDao = RecurringDao();
  final bool _unlocked = SubscriptionService().canUseSubscriptionScanner;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  RecurringTransaction? _suggestion;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accounts = await AccountDao().find();
    final categories = await CategoryDao().find(withSummery: false);
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _categories = categories;
    });
  }

  Future<void> _scan(ImageSource source) async {
    if (!ReceiptScannerService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt scanning is only available on mobile devices.')),
      );
      return;
    }
    if (_accounts.isEmpty || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one account and category first')),
      );
      return;
    }

    setState(() => _scanning = true);
    final suggestion = await SubscriptionScannerService.scan(
      source: source,
      fallbackAccount: _accounts.first,
      fallbackCategory: _categories.first,
    );
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _suggestion = suggestion;
    });

    if (suggestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subscription details found. Try another image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Subscription')),
        body: _paywall(theme, colorScheme),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Subscription')),
      body: _scanning
          ? const Center(child: CircularProgressIndicator())
          : _suggestion != null
              ? _buildConfirmation(theme, colorScheme)
              : _buildSourcePicker(theme, colorScheme),
    );
  }

  Widget _paywall(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.receipt_long, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Subscription Scanner is a Plus feature',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Turn a receipt or bill into a recurring transaction in seconds. On-device OCR.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePicker(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Symbols.receipt_long, size: 64, color: colorScheme.primary, fill: 1),
          const SizedBox(height: 24),
          Text(
            'Scan a subscription receipt',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Snap a photo or choose an image. OCR runs on your device and creates a recurring transaction suggestion.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _scan(ImageSource.camera),
                  icon: const Icon(Symbols.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _scan(ImageSource.gallery),
                  icon: const Icon(Symbols.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(ThemeData theme, ColorScheme colorScheme) {
    final suggestion = _suggestion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm subscription', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Symbols.receipt_long, fill: 1),
              title: Text(suggestion.title),
              subtitle: Text('Amount: ${suggestion.amount.toStringAsFixed(2)} · Monthly · ${DateFormat('dd MMM yyyy').format(suggestion.startDate)}'),
            ),
          ),
          const SizedBox(height: 24),
          RecurringForm(
            categories: _categories,
            accounts: _accounts,
            initial: suggestion,
            onSave: (recurring) async {
              await _recurringDao.create(recurring);
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
