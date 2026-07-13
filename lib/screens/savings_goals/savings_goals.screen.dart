import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/dao/savings_goal_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/savings_goal.model.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final SavingsGoalDao _dao = SavingsGoalDao();
  List<SavingsGoal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await _dao.find();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.w600))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _WhatIfPlanner(),
                  const SizedBox(height: 20),
                  if (_goals.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Symbols.savings, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('No savings goals yet', style: theme.textTheme.bodyLarge),
                          Text('Tap + to create a goal and track progress.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    )
                  else
                    ..._goals.map((g) => _GoalCard(goal: g, onRefresh: _load)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showGoalForm({SavingsGoal? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _GoalForm(
        goal: goal,
        onSave: (g) async {
          await _dao.upsert(g);
          _load();
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onRefresh;
  const _GoalCard({required this.goal, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = goal.color != null ? Color(goal.color!) : theme.colorScheme.primary;
    final progress = goal.progress;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: goal.icon != null
                    ? Text(String.fromCharCode(goal.icon!), style: TextStyle(fontFamily: 'MaterialIcons', fontSize: 24, color: color))
                    : Icon(Symbols.savings, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(goal.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'add') {
                    _showAddContribution(context, goal);
                  } else if (value == 'delete') {
                    await SavingsGoalDao().delete(goal.id!);
                    onRefresh();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'add', child: Text('Add contribution')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.expenseColor))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CurrencyText(goal.savedAmount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              CurrencyText(goal.targetAmount, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          if (goal.dailyRequired > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Save ${goal.dailyRequired.toStringAsFixed(0)}/day to reach goal by deadline',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddContribution(BuildContext context, SavingsGoal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contribution'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                goal.savedAmount += amount;
                await SavingsGoalDao().update(goal);
                onRefresh();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _GoalForm extends StatefulWidget {
  final SavingsGoal? goal;
  final Function(SavingsGoal) onSave;
  const _GoalForm({this.goal, required this.onSave});

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 365));
  final List<int> _colors = [Colors.teal.toARGB32(), Colors.purple.toARGB32(), Colors.orange.toARGB32(), Colors.pink.toARGB32(), Colors.blue.toARGB32()];
  int _selectedColor = Colors.teal.toARGB32();
  final List<int> _icons = [Icons.savings.codePoint, Icons.home.codePoint, Icons.directions_car.codePoint, Icons.flight.codePoint, Icons.shopping_bag.codePoint];
  int _selectedIcon = Icons.savings.codePoint;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = widget.goal!.targetAmount.toString();
      _deadline = widget.goal!.deadline;
      _selectedColor = widget.goal!.color ?? _selectedColor;
      _selectedIcon = widget.goal!.icon ?? _selectedIcon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.goal == null ? 'New Goal' : 'Edit Goal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Goal name')),
            const SizedBox(height: 12),
            TextField(controller: _targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target amount')),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text('${_deadline.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Symbols.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _deadline, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = _colors[i]),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: Color(_colors[i]), shape: BoxShape.circle, border: _selectedColor == _colors[i] ? Border.all(color: Colors.white, width: 2) : null),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = _icons[i]),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: _selectedIcon == _icons[i] ? theme.colorScheme.primary.withOpacity(0.1) : null, borderRadius: BorderRadius.circular(10)),
                    child: Text(String.fromCharCode(_icons[i]), style: TextStyle(fontFamily: 'MaterialIcons', fontSize: 22, color: theme.colorScheme.primary)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  final target = double.tryParse(_targetController.text) ?? 0;
                  if (_nameController.text.trim().isEmpty || target <= 0) return;
                  widget.onSave(SavingsGoal(
                    id: widget.goal?.id,
                    name: _nameController.text.trim(),
                    targetAmount: target,
                    savedAmount: widget.goal?.savedAmount ?? 0,
                    deadline: _deadline,
                    color: _selectedColor,
                    icon: _selectedIcon,
                  ));
                },
                child: const Text('Save Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatIfPlanner extends StatefulWidget {
  @override
  State<_WhatIfPlanner> createState() => _WhatIfPlannerState();
}

class _WhatIfPlannerState extends State<_WhatIfPlanner> {
  double _percent = 10;
  double _monthlyExpense = 0;
  double _monthlySavings = 0;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final payments = await PaymentDao().find(range: DateTimeRange(start: start, end: now));
    double expense = 0;
    for (final p in payments) {
      if (p.type == PaymentType.debit) expense += p.amount;
    }
    if (mounted) {
      setState(() {
        _monthlyExpense = expense;
        _monthlySavings = expense * (_percent / 100);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What-if Planner', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Reduce discretionary spending by ${_percent.toStringAsFixed(0)}% and save:', style: theme.textTheme.bodySmall),
          Slider(
            value: _percent,
            min: 0,
            max: 50,
            divisions: 10,
            label: '${_percent.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() {
              _percent = v;
              _monthlySavings = _monthlyExpense * (v / 100);
            }),
          ),
          CurrencyText(_monthlySavings, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.incomeColor)),
        ],
      ),
    );
  }
}
