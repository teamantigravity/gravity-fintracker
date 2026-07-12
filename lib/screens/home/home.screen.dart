import 'package:events_emitter/events_emitter.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/home/widgets/account_slider.dart';
import 'package:fintracker/screens/home/widgets/hero_header.dart';
import 'package:fintracker/screens/home/widgets/income_expense_chart.dart';
import 'package:fintracker/screens/home/widgets/quick_actions.dart';
import 'package:fintracker/screens/home/widgets/smart_insights.dart';
import 'package:fintracker/screens/home/widgets/spending_chart.dart';
import 'package:fintracker/screens/home/widgets/transaction_group_list.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/services/streak_service.dart';
import 'package:fintracker/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Payment> _allPayments = []; // unfiltered, used for the logging streak
  List<Account> _accounts = [];
  bool _showCharts = false;
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day -1)),
      end: DateTime.now()
  );
  Account? _account;
  Category? _category;

  double get _income => _payments.where((p) => p.type == PaymentType.credit).fold(0.0, (s, p) => s + p.amount);
  double get _expense => _payments.where((p) => p.type == PaymentType.debit).fold(0.0, (s, p) => s + p.amount);
  double get _netWorth => _accounts.fold(0.0, (s, a) => s + (a.balance ?? 0));
  int get _streak => StreakService.currentStreak(_allPayments);

  void openAddPaymentPage(PaymentType type) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (builder)=>PaymentForm(type: type)));
  }

  void handleChooseDateRange() async{
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    );
    if(selected != null) {
      setState(() {
        _range = selected;
        _fetchTransactions();
      });
    }
  }

  Future<void> _fetchTransactions() async {
    List<Payment> trans = await _paymentDao.find(range: _range, category: _category, account:_account);
    List<Payment> all = await _paymentDao.find();
    List<Account> accounts = await _accountDao.find(withSummery: true);

    setState(() {
      _payments = trans;
      _allPayments = all;
      _accounts = accounts;
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchTransactions();

    _accountEventListener = globalEvent.on("account_update", (data){
      debugPrint("accounts are changed");
      _fetchTransactions();
    });

    _categoryEventListener = globalEvent.on("category_update", (data){
      debugPrint("categories are changed");
      _fetchTransactions();
    });

    _paymentEventListener = globalEvent.on("payment_update", (data){
      debugPrint("payments are changed");
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();
    _paymentEventListener?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredFadeIn(
                index: 0,
                child: BlocBuilder<AppCubit, AppState>(
                  builder: (context, state) => HeroHeader(
                    username: state.username ?? "Guest",
                    netWorth: _netWorth,
                    periodIncome: _income,
                    periodExpense: _expense,
                    streak: _streak,
                    showingCharts: _showCharts,
                    onToggleCharts: () => setState(() => _showCharts = !_showCharts),
                  ),
                ),
              ),

              // Account cards
              StaggeredFadeIn(index: 1, child: AccountsSlider(accounts: _accounts)),
              const SizedBox(height: 20),

              // Quick actions — unambiguous, unlike a single default-typed FAB
              StaggeredFadeIn(
                index: 2,
                child: QuickActions(
                  onAddExpense: () => openAddPaymentPage(PaymentType.debit),
                  onAddIncome: () => openAddPaymentPage(PaymentType.credit),
                ),
              ),
              const SizedBox(height: 20),

              // Charts section
              if (_showCharts && _payments.isNotEmpty) ...[
                SpendingChart(payments: _payments),
                IncomeExpenseChart(payments: _payments),
                const SizedBox(height: 8),
              ],

              // Smart Insights
              if (_payments.isNotEmpty) ...[
                StaggeredFadeIn(index: 3, child: SmartInsightsCard(payments: _payments)),
                const SizedBox(height: 12),
              ],

              // Payments header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                    children: [
                      Text("Transactions",
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Expanded(child: SizedBox()),
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
                    ]
                ),
              ),

              // Payments list
              _payments.isNotEmpty ? TransactionGroupList(
                payments: _payments,
                onTap: (payment) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (builder)=>PaymentForm(type: payment.type, payment: payment,)));
                },
              ) : Container(
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
                      "No transactions yet",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Use the buttons above to add your first transaction",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
