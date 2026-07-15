import 'package:file_picker/file_picker.dart';
import 'package:fintracker/services/reports_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:fintracker/widgets/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../premium/paywall.screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime(DateTime.now().year, 1, 1),
    end: DateTime.now(),
  );
  Future<ReportSummary>? _summary;

  final bool _unlocked = SubscriptionService().canUseTaxReports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!_unlocked) return;
    setState(() {
      _summary = ReportsService.generateSummary(_range);
    });
  }

  Future<void> _selectRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
    _load();
  }

  Future<void> _export() async {
    if (!_unlocked) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Tax & Export Report',
      fileName: 'gravity-tax-report.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path == null || path.isEmpty || !mounted) return;

    if (mounted) LoadingModal.showLoadingDialog(context, content: const Text('Exporting report...'));
    try {
      final value = await ReportsService.exportTaxReportCsv(_range, filePath: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $value')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tax & Export Reports')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.lock, size: 64, color: colorScheme.primary.withAlpha(60)),
                const SizedBox(height: 16),
                Text(
                  'Tax & export reports are a Plus feature.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  child: const Text('Unlock Plus'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax & Export Reports', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Symbols.calendar_month),
            onPressed: _selectRange,
          ),
          IconButton(
            icon: const Icon(Symbols.download),
            onPressed: _export,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<ReportSummary>(
          future: _summary,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final summary = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildRangeChip(theme, colorScheme),
                const SizedBox(height: 16),
                _buildTotalsCard(theme, summary),
                const SizedBox(height: 16),
                Text('By Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...summary.categories.map((c) => _buildCategoryTile(c, theme)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRangeChip(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        ActionChip(
          avatar: const Icon(Symbols.calendar_month, size: 16),
          label: Text('${_formatDate(_range.start)} - ${_formatDate(_range.end)}'),
          onPressed: _selectRange,
        ),
      ],
    );
  }

  Widget _buildTotalsCard(ThemeData theme, ReportSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('Income', summary.totalIncome, AppTheme.incomeColor),
              _metric('Expense', summary.totalExpense, AppTheme.expenseColor),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              CurrencyText(
                summary.net,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: summary.net >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withAlpha(200))),
        CurrencyText(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildCategoryTile(CategorySummary category, ThemeData theme) {
    final color = category.net >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(category.categoryName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: CurrencyText(
        category.net,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(
        'In: ${category.income.toStringAsFixed(2)}  Out: ${category.expense.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
