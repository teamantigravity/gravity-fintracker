import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/recurring.model.dart';
import 'package:fintracker/screens/rules/rules_screen.dart';
import 'package:fintracker/screens/subscriptions/subscription_dashboard.screen.dart';
import 'package:fintracker/screens/subscriptions/subscription_scanner.screen.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final RecurringDao _recurringDao = RecurringDao();
  List<RecurringTransaction> _recurring = [];

  Future<void> _loadData() async {
    List<RecurringTransaction> recurring = await _recurringDao.find();
    if (!mounted) return;
    setState(() {
      _recurring = recurring;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showAddRecurringDialog() async {
    List<Category> categories = await CategoryDao().find(withSummery: false);
    List<Account> accounts = await AccountDao().find();

    if (!mounted) return;
    if (categories.isEmpty || accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create at least one category and account first")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RecurringForm(
        categories: categories,
        accounts: accounts,
        onSave: (recurring) async {
          await _recurringDao.create(recurring);
          _loadData();
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  void _toggleActive(RecurringTransaction recurring) async {
    final id = recurring.id;
    if (id == null) return;
    if (recurring.isActive) {
      await _recurringDao.deactivate(id);
    } else {
      await _recurringDao.update(RecurringTransaction(
        id: recurring.id,
        account: recurring.account,
        category: recurring.category,
        amount: recurring.amount,
        type: recurring.type,
        title: recurring.title,
        description: recurring.description,
        interval: recurring.interval,
        startDate: recurring.startDate,
        nextDueDate: recurring.nextDueDate,
        isActive: true,
      ));
    }
    _loadData();
  }

  void _deleteRecurring(int id) async {
    await _recurringDao.delete(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recurring"),
        actions: [
          IconButton(
            icon: const Icon(Symbols.insights, fill: 1),
            tooltip: 'Subscription Intelligence',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionDashboardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.rule),
            tooltip: 'Automation Rules',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.receipt_long, fill: 1),
            tooltip: 'Scan Subscription',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScannerScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: _recurring.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.repeat,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    fill: 1,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No recurring transactions",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Automate your bills, subscriptions,\nand income tracking",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _recurring.length,
              separatorBuilder: (_, __) => Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 72, right: 16),
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final item = _recurring[index];
                final isCredit = item.type == "CR";
                return Dismissible(
                  key: Key('recurring_${item.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppTheme.expenseColor.withValues(alpha: 0.1),
                    child: const Icon(Symbols.delete, color: AppTheme.expenseColor),
                  ),
                  onDismissed: (_) {
                    final id = item.id;
                    if (id != null) _deleteRecurring(id);
                  },
                  child: ListTile(
                    leading: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: item.category.color.withValues(alpha: 0.1),
                      ),
                      child: Icon(item.category.icon, size: 20, color: item.category.color),
                    ),
                    title: Text(
                      item.title.isEmpty ? item.category.name : item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: item.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      "${item.intervalLabel} · Next: ${() {
                        final nextDueDate = item.nextDueDate;
                        return nextDueDate != null ? DateFormat('dd MMM').format(nextDueDate) : 'N/A';
                      }()}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CurrencyText(
                          isCredit ? item.amount : -item.amount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isCredit ? AppTheme.incomeColor : AppTheme.expenseColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: item.isActive,
                          onChanged: (_) => _toggleActive(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecurringDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RecurringForm extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final RecurringTransaction? initial;
  final Function(RecurringTransaction) onSave;

  const RecurringForm({
    super.key,
    required this.categories,
    required this.accounts,
    this.initial,
    required this.onSave,
  });

  @override
  State<RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<RecurringForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount;
  RecurringInterval _interval = RecurringInterval.monthly;
  String _type = "DR";
  DateTime _startDate = DateTime.now();
  DateTime _nextDueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _titleController.text = initial.title;
      _amountController.text = initial.amount.toString();
      _descriptionController.text = initial.description;
      _selectedCategory = widget.categories.cast<Category?>().firstWhere((c) => c?.id == initial.category.id, orElse: () => null) ?? (widget.categories.isNotEmpty ? widget.categories.first : null);
      _selectedAccount = widget.accounts.cast<Account?>().firstWhere((a) => a?.id == initial.account.id, orElse: () => null) ?? (widget.accounts.isNotEmpty ? widget.accounts.first : null);
      _interval = initial.interval;
      _type = initial.type;
      _startDate = initial.startDate;
      _nextDueDate = initial.nextDueDate ?? initial.startDate;
    } else {
      if (widget.categories.isNotEmpty) _selectedCategory = widget.categories.first;
      if (widget.accounts.isNotEmpty) _selectedAccount = widget.accounts.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "New Recurring Transaction",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "DR", label: Text("Expense"), icon: Icon(Symbols.arrow_upward)),
                ButtonSegment(value: "CR", label: Text("Income"), icon: Icon(Symbols.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: "Category"),
              items: widget.categories.map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Icon(c.icon, size: 18, color: c.color),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),

            // Account dropdown
            DropdownButtonFormField<Account>(
              initialValue: _selectedAccount,
              decoration: const InputDecoration(labelText: "Account"),
              items: widget.accounts.map((a) => DropdownMenuItem(
                value: a,
                child: Text(a.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedAccount = v),
            ),
            const SizedBox(height: 12),

            // Interval dropdown
            DropdownButtonFormField<RecurringInterval>(
              initialValue: _interval,
              decoration: const InputDecoration(labelText: "Frequency"),
              items: RecurringInterval.values.map((i) => DropdownMenuItem(
                value: i,
                child: Text(i.name[0].toUpperCase() + i.name.substring(1)),
              )).toList(),
              onChanged: (v) => setState(() => _interval = v ?? RecurringInterval.monthly),
            ),
            const SizedBox(height: 12),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Start Date"),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
              trailing: const Icon(Symbols.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _startDate = picked;
                    if (widget.initial == null) _nextDueDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description (optional)"),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  if (_amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter an amount")),
                    );
                    return;
                  }

                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a valid amount")),
                    );
                    return;
                  }

                  final account = _selectedAccount;
                  final category = _selectedCategory;
                  if (account == null || category == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select an account and category")),
                    );
                    return;
                  }

                  final recurring = RecurringTransaction(
                    account: account,
                    category: category,
                    amount: amount,
                    type: _type,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    interval: _interval,
                    startDate: _startDate,
                    nextDueDate: _nextDueDate,
                    isActive: true,
                  );

                  await widget.onSave(recurring);
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
