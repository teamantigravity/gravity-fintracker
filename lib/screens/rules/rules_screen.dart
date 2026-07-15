import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/rule_dao.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/rule.model.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final RuleDao _ruleDao = RuleDao();
  List<Rule> _rules = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  final bool _unlocked = SubscriptionService().canUseRecurringRules;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = _unlocked ? await _ruleDao.find() : <Rule>[];
    final accounts = await AccountDao().find();
    final categories = await CategoryDao().find(withSummery: false);
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _accounts = accounts;
      _categories = categories;
    });
  }

  void _openForm({Rule? rule}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _RuleForm(
        rule: rule,
        accounts: _accounts,
        categories: _categories,
        onSave: (r) async {
          if (r.id == null) {
            await _ruleDao.create(r);
          } else {
            await _ruleDao.update(r);
          }
          _load();
        },
      ),
    );
  }

  Future<void> _toggleEnabled(Rule rule) async {
    rule.enabled = !rule.enabled;
    await _ruleDao.update(rule);
    _load();
  }

  Future<void> _delete(Rule rule) async {
    if (rule.id == null) return;
    await _ruleDao.delete(rule.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Automation Rules')),
        body: _paywall(theme, colorScheme),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Rules'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add, fill: 1),
            onPressed: _openForm,
          ),
        ],
      ),
      body: _rules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No automation rules',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-save a percentage of income or route\nexpenses to a specific account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _rules.length,
              separatorBuilder: (_, __) => Container(height: 0.5, margin: const EdgeInsets.only(left: 72, right: 16), color: theme.dividerColor.withValues(alpha: 0.3)),
              itemBuilder: (context, index) {
                final rule = _rules[index];
                return ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.rule, color: colorScheme.primary, size: 20),
                  ),
                  title: Text(rule.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${_describeRule(rule)}${rule.minAmount != null || rule.maxAmount != null ? ' · amount filter' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  trailing: Switch(
                    value: rule.enabled,
                    onChanged: (_) => _toggleEnabled(rule),
                  ),
                  onTap: () => _openForm(rule: rule),
                  onLongPress: () => _delete(rule),
                );
              },
            ),
    );
  }

  Widget _paywall(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Automation Rules are a Plus feature',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-save, auto-allocate, and route transactions on-device without lifting a finger.',
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

  String _describeRule(Rule rule) {
    final source = rule.sourceAccountId != null
        ? _accounts.firstWhere((a) => a.id == rule.sourceAccountId, orElse: () => Account(name: 'Unknown', holderName: '', accountNumber: '', icon: Icons.account_balance, color: Colors.grey)).name
        : 'any account';
    final target = _accounts.firstWhere((a) => a.id == rule.targetAccountId, orElse: () => Account(name: 'Unknown', holderName: '', accountNumber: '', icon: Icons.account_balance, color: Colors.grey)).name;
    return 'When $source receives ${rule.percentage * 100}% → $target';
  }
}

class _RuleForm extends StatefulWidget {
  final Rule? rule;
  final List<Account> accounts;
  final List<Category> categories;
  final Function(Rule) onSave;

  const _RuleForm({this.rule, required this.accounts, required this.categories, required this.onSave});

  @override
  State<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends State<_RuleForm> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _percentageController = TextEditingController();
  bool _enabled = true;
  Account? _sourceAccount;
  Category? _sourceCategory;
  String? _type;
  Account? _targetAccount;
  Category? _targetCategory;
  String? _targetType;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule != null) {
      _nameController.text = rule.name;
      _descController.text = rule.description;
      _minController.text = rule.minAmount?.toString() ?? '';
      _maxController.text = rule.maxAmount?.toString() ?? '';
      _percentageController.text = (rule.percentage * 100).toStringAsFixed(0);
      _enabled = rule.enabled;
      _sourceAccount = widget.accounts.cast<Account?>().firstWhere((a) => a?.id == rule.sourceAccountId, orElse: () => null);
      _sourceCategory = widget.categories.cast<Category?>().firstWhere((c) => c?.id == rule.sourceCategoryId, orElse: () => null);
      _type = rule.type;
      _targetAccount = widget.accounts.cast<Account?>().firstWhere((a) => a?.id == rule.targetAccountId, orElse: () => null);
      _targetCategory = widget.categories.cast<Category?>().firstWhere((c) => c?.id == rule.targetCategoryId, orElse: () => null);
      _targetType = rule.targetType;
    } else {
      _percentageController.text = '20';
      if (widget.accounts.isNotEmpty) _targetAccount = widget.accounts.first;
      if (widget.categories.isNotEmpty) _targetCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text(widget.rule == null ? 'New Automation Rule' : 'Edit Rule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Rule name')),
            const SizedBox(height: 12),
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Any type')),
                ButtonSegment(value: 'CR', label: Text('Income')),
                ButtonSegment(value: 'DR', label: Text('Expense')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Account?>(
              initialValue: _sourceAccount,
              decoration: const InputDecoration(labelText: 'Source account (optional)'),
              items: [
                const DropdownMenuItem<Account?>(value: null, child: Text('Any account')),
                ...widget.accounts.map<DropdownMenuItem<Account?>>((a) => DropdownMenuItem<Account?>(value: a, child: Text(a.name))),
              ],
              onChanged: (v) => setState(() => _sourceAccount = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category?>(
              initialValue: _sourceCategory,
              decoration: const InputDecoration(labelText: 'Source category (optional)'),
              items: [
                const DropdownMenuItem<Category?>(value: null, child: Text('Any category')),
                ...widget.categories.map<DropdownMenuItem<Category?>>((c) => DropdownMenuItem<Category?>(value: c, child: Row(children: [Icon(c.icon, size: 18, color: c.color), const SizedBox(width: 8), Text(c.name)]))),
              ],
              onChanged: (v) => setState(() => _sourceCategory = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min amount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Max amount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percentageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Percentage to route (%)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Account?>(
              initialValue: _targetAccount,
              decoration: const InputDecoration(labelText: 'Target account'),
              items: widget.accounts.map<DropdownMenuItem<Account?>>((a) => DropdownMenuItem<Account?>(value: a, child: Text(a.name))).toList(),
              onChanged: (v) => setState(() => _targetAccount = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category?>(
              initialValue: _targetCategory,
              decoration: const InputDecoration(labelText: 'Target category'),
              items: widget.categories.map<DropdownMenuItem<Category?>>((c) => DropdownMenuItem<Category?>(value: c, child: Row(children: [Icon(c.icon, size: 18, color: c.color), const SizedBox(width: 8), Text(c.name)]))).toList(),
              onChanged: (v) => setState(() => _targetCategory = v),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: 'DR', label: Text('Debit')),
                ButtonSegment(value: 'CR', label: Text('Credit')),
              ],
              selected: {_targetType},
              onSelectionChanged: (v) => setState(() => _targetType = v.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 2),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Enabled', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final targetAccount = _targetAccount;
    final targetCategory = _targetCategory;
    if (name.isEmpty || targetAccount == null || targetCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, target account, and target category are required')));
      return;
    }
    final targetAccountId = targetAccount.id;
    final targetCategoryId = targetCategory.id;
    if (targetAccountId == null || targetCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected account or category has no ID')));
      return;
    }
    final percentage = double.tryParse(_percentageController.text) ?? 0;
    if (percentage <= 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Percentage must be between 1 and 100')));
      return;
    }
    final rule = widget.rule ?? Rule(name: name, targetAccountId: targetAccountId, targetCategoryId: targetCategoryId);
    rule.name = name;
    rule.description = _descController.text;
    rule.enabled = _enabled;
    rule.sourceAccountId = _sourceAccount?.id;
    rule.sourceCategoryId = _sourceCategory?.id;
    rule.type = _type;
    rule.minAmount = double.tryParse(_minController.text);
    rule.maxAmount = double.tryParse(_maxController.text);
    rule.percentage = percentage / 100;
    rule.targetAccountId = targetAccountId;
    rule.targetCategoryId = targetCategoryId;
    rule.targetType = _targetType ?? 'DR';
    widget.onSave(rule);
    Navigator.of(context).pop();
  }
}
