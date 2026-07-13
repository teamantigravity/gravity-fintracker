import 'package:events_emitter/events_emitter.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/home/widgets/account_slider.dart';
import 'package:fintracker/screens/home/widgets/income_expense_chart.dart';
import 'package:fintracker/screens/home/widgets/payment_list_item.dart';
import 'package:fintracker/screens/home/widgets/smart_insights.dart';
import 'package:fintracker/screens/home/widgets/spending_chart.dart';
import 'package:fintracker/screens/home/widgets/trend_chart.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/services/haptic_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';


String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Morning';
  }
  if (hour < 17) {
    return 'Afternoon';
  }
  return 'Evening';
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  bool _showCharts = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _listAnimationController;
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day -1)),
      end: DateTime.now()
  );
  Account? _account;
  Category? _category;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchTransactions();

    _accountEventListener = globalEvent.on("account_update", (data){
      _fetchTransactions();
    });

    _categoryEventListener = globalEvent.on("category_update", (data){
      _fetchTransactions();
    });

    _paymentEventListener = globalEvent.on("payment_update", (data){
      _fetchTransactions();
    });

    _searchController.addListener(_filterPayments);
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredPayments = _payments);
      return;
    }
    setState(() {
      _filteredPayments = _payments.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.category.name.toLowerCase().contains(query) ||
            p.account.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  void openAddPaymentPage(PaymentType type) async {
    HapticService.light();
    Navigator.of(context).push(MaterialPageRoute(builder: (builder)=>PaymentForm(type: type)));
  }

  void handleChooseDateRange() async{
    HapticService.light();
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    );
    if(selected != null && mounted) {
      setState(() {
        _range = selected;
        _fetchTransactions();
      });
    }
  }

  Future<void> _fetchTransactions() async {
    List<Payment> trans = await _paymentDao.find(range: _range, category: _category, account:_account);
    double income = 0;
    double expense = 0;
    for (var payment in trans) {
      if(payment.type == PaymentType.credit) income += payment.amount;
      if(payment.type == PaymentType.debit) expense += payment.amount;
    }

    List<Account> accounts = await _accountDao.find(withSummery: true);

    if (!mounted) return;
    setState(() {
      _payments = trans;
      _filteredPayments = trans;
      _income = income;
      _expense = expense;
      _accounts = accounts;
    });
    _listAnimationController.forward(from: 0.0);
  }

  Future<void> _handleRefresh() async {
    HapticService.light();
    await _fetchTransactions();
  }

  Future<void> _deletePayment(Payment payment) async {
    HapticService.heavy();
    await _paymentDao.deleteTransaction(payment.id!);
    globalEvent.emit("payment_update");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Transaction deleted"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () async {
              payment.id = null;
              await _paymentDao.upsert(payment);
              globalEvent.emit("payment_update");
            },
          ),
        ),
      );
    }
  }

  void _editPayment(Payment payment) {
    HapticService.light();
    Navigator.of(context).push(MaterialPageRoute(builder: (builder)=>PaymentForm(type: payment.type, payment: payment,)));
  }

  @override
  void dispose() {
    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();
    _paymentEventListener?.cancel();
    _searchController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 60,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(colorScheme, theme),
                  const SizedBox(height: 16),
                  AccountsSlider(accounts: _accounts),
                  const SizedBox(height: 16),
                  _SummaryCards(income: _income, expense: _expense),
                  if (_showCharts && _payments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TrendChart(payments: _payments),
                    SpendingChart(payments: _payments),
                    IncomeExpenseChart(payments: _payments),
                  ],
                  if (_payments.isNotEmpty)
                    SmartInsightsCard(payments: _payments),
                  _buildTransactionsHeader(theme, colorScheme),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            _buildTransactionsList(theme, colorScheme),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search transactions...",
                      filled: true,
                      prefixIcon: const Icon(Symbols.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Symbols.close, size: 20),
                        onPressed: () {
                          HapticService.light();
                          _searchController.clear();
                          setState(() => _isSearching = false);
                        },
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good ${greeting()}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      BlocConsumer<AppCubit, AppState>(
                        listener: (context, state){},
                        builder: (context, state) => Text(
                          state.username ?? "Guest",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            onPressed: () {
              HapticService.light();
              setState(() => _isSearching = !_isSearching);
            },
            icon: Icon(_isSearching ? Symbols.close : Symbols.search, fill: 1, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _showCharts = !_showCharts),
            icon: Icon(_showCharts ? Symbols.list : Symbols.bar_chart, fill: 1, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "Transactions",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Expanded(child: SizedBox()),
          if (_filteredPayments.isNotEmpty)
            Text(
              "${_filteredPayments.length}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          const SizedBox(width: 8),
          InkWell(
            onTap: handleChooseDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${DateFormat("dd MMM").format(_range.start)} - ${DateFormat("dd MMM").format(_range.end)}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_outlined, size: 18, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ThemeData theme, ColorScheme colorScheme) {
    if (_filteredPayments.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Symbols.receipt_long,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.15),
                fill: 1,
              ),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty ? "No transactions yet" : "No matches found",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              if (_searchController.text.isEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Tap + to add your first transaction",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final payment = _filteredPayments[index];
          final begin = (index * 0.05).clamp(0.0, 1.0).toDouble();
          final animation = Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(begin, 1.0, curve: Curves.easeOut),
          ));
          final opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(begin, 1.0, curve: Curves.easeOut),
          ));

          return FadeTransition(
            opacity: opacity,
            child: SlideTransition(
              position: animation,
              child: Dismissible(
                key: ValueKey(payment.id ?? index),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: colorScheme.error,
                  child: const Icon(Symbols.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deletePayment(payment),
                child: PaymentListItem(
                  payment: payment,
                  onTap: () => _editPayment(payment),
                ),
              ),
            ),
          );
        },
        childCount: _filteredPayments.length,
      ),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Symbols.add,
      activeIcon: Symbols.close,
      spacing: 12,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 8,
      overlayColor: Colors.black,
      overlayOpacity: 0.3,
      children: [
        SpeedDialChild(
          child: const Icon(Symbols.arrow_downward, color: Colors.white),
          label: "Income",
          backgroundColor: AppTheme.incomeColor,
          onTap: () => openAddPaymentPage(PaymentType.credit),
        ),
        SpeedDialChild(
          child: const Icon(Symbols.arrow_upward, color: Colors.white),
          label: "Expense",
          backgroundColor: AppTheme.expenseColor,
          onTap: () => openAddPaymentPage(PaymentType.debit),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double income;
  final double expense;

  const _SummaryCards({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: "Income",
              amount: income,
              color: AppTheme.incomeColor,
              icon: Symbols.arrow_downward,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: "Expense",
              amount: expense,
              color: AppTheme.expenseColor,
              icon: Symbols.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CurrencyText(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
