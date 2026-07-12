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
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  bool _showCharts = false;
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day -1)),
      end: DateTime.now()
  );
  Account? _account;
  Category? _category;

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

  void _fetchTransactions() async {
    List<Payment> trans = await _paymentDao.find(range: _range, category: _category, account:_account);
    double income = 0;
    double expense = 0;
    for (var payment in trans) {
      if(payment.type == PaymentType.credit) income += payment.amount;
      if(payment.type == PaymentType.debit) expense += payment.amount;
    }

    List<Account> accounts = await _accountDao.find(withSummery: true);

    setState(() {
      _payments = trans;
      _income = income;
      _expense = expense;
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
      body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 60),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
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
                              )
                          )
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _showCharts = !_showCharts),
                        icon: Icon(
                          _showCharts ? Symbols.list : Symbols.bar_chart,
                          fill: 1,
                          size: 22,
                        ),
                        tooltip: _showCharts ? "Show list" : "Show charts",
                      ),
                    ),
                  ],
                ),
              ),

              // Account cards
              AccountsSlider(accounts: _accounts),
              const SizedBox(height: 16),

              // Income/Expense summary cards
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: "Income",
                        amount: _income,
                        color: AppTheme.incomeColor,
                        icon: Symbols.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: "Expense",
                        amount: _expense,
                        color: AppTheme.expenseColor,
                        icon: Symbols.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),

              // Charts section
              if (_showCharts && _payments.isNotEmpty) ...[
                const SizedBox(height: 8),
                SpendingChart(payments: _payments),
                IncomeExpenseChart(payments: _payments),
              ],

              // Smart Insights
              if (_payments.isNotEmpty)
                SmartInsightsCard(payments: _payments),

              // Payments header
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),

              // Payments list
              _payments.isNotEmpty ? ListView.separated(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (BuildContext context, index){
                  return PaymentListItem(payment: _payments[index], onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (builder)=>PaymentForm(type: _payments[index].type, payment: _payments[index],)));
                  });
                },
                separatorBuilder: (BuildContext context, int index){
                  return Container(
                    width: double.infinity,
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 75, right: 20),
                  );
                },
                itemCount: _payments.length,
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
                      "Tap + to add your first transaction",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=> openAddPaymentPage(PaymentType.credit),
        child: const Icon(Icons.add),
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
