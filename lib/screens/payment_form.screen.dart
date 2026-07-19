import 'package:events_emitter/listener.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/events.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/theme/colors.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:fintracker/widgets/dialog/account_form.dialog.dart';
import 'package:fintracker/widgets/dialog/category_form.dialog.dart';
import 'package:fintracker/widgets/ai/receipt_scanner_button.dart';
import 'package:fintracker/widgets/ai/voice_input_button.dart';
import 'package:fintracker/widgets/buttons/button.dart';
import 'package:fintracker/widgets/dialog/confirm.modal.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/config/app_date_formats.dart';
import 'package:fintracker/config/strings.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final DateFormat formatter = DateFormat(AppDateFormats.fullDateTime);
class PaymentForm extends StatefulWidget{
  final PaymentType  type;
  final Payment?  payment;
  final String? prefillTitle;
  final double? prefillAmount;
  final DateTime? prefillDate;

  const PaymentForm({super.key, required this.type, this.payment, this.prefillTitle, this.prefillAmount, this.prefillDate});

  @override
  State<PaymentForm> createState() => _PaymentForm();
}

class _PaymentForm extends State<PaymentForm>{
  bool _initialised = false;
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  final CategoryDao _categoryDao = CategoryDao();

  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;

  List<Account> _accounts = [];
  List<Category> _categories = [];

  //values
  int? _id;
  String _title = '';
  String _description='';
  Account? _account;
  Category? _category;
  double _amount=0;
  PaymentType _type= PaymentType.credit;
  DateTime _datetime = DateTime.now();

  Future<void> loadAccounts() async {
    final List<Account> value = await _accountDao.find();
    if (mounted) {
      setState(() {
        _accounts = value;
      });
    }
  }

  Future<void> loadCategories() async {
    final List<Category> value = await _categoryDao.find();
    if (mounted) {
      setState(() {
        _categories = value;
      });
    }
  }

  void populateState() async {
    await loadAccounts();
    await loadCategories();
    if (!mounted) return;

    final payment = widget.payment;
    if (payment != null) {
      final paymentAccount = payment.account;
      final paymentCategory = payment.category;
      setState(() {
        _id = payment.id;
        _title = payment.title;
        _description = payment.description;
        _account = _accounts.cast<Account?>().firstWhere(
          (a) => a?.id == paymentAccount.id,
          orElse: () => paymentAccount,
        );
        _category = _categories.cast<Category?>().firstWhere(
          (c) => c?.id == paymentCategory.id,
          orElse: () => paymentCategory,
        );
        _amount = payment.amount;
        _type = payment.type;
        _datetime = payment.datetime;
        _initialised = true;
      });
    } else {
      setState(() {
        _type = widget.type;
        _title = widget.prefillTitle ?? '';
        _amount = widget.prefillAmount ?? 0;
        _datetime = widget.prefillDate ?? DateTime.now();
        _initialised = true;
      });
    }
  }

  Future<void> _suggestFromTitle(String title) async {
    if (title.trim().length < 3) return;
    final suggestion = await _paymentDao.findByTitle(title, _type);
    if (suggestion != null && mounted) {
      setState(() {
        _account = _accounts.cast<Account?>().firstWhere(
          (a) => a?.id == suggestion.account.id,
          orElse: () => _account,
        );
        _category = _categories.cast<Category?>().firstWhere(
          (c) => c?.id == suggestion.category.id,
          orElse: () => _category,
        );
      });
    }
  }

  Future<void> chooseDate(BuildContext context) async {
    final DateTime initialDate = _datetime;
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now()
    );
    if(picked!=null  && initialDate != picked) {
      if (!mounted) return;
      setState(() {
        _datetime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            initialDate.hour,
            initialDate.minute
        );
      });
    }
  }

  Future<void> chooseTime(BuildContext context) async {
    final DateTime initialDate = _datetime;
    final TimeOfDay initialTime = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
    final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: initialTime,
        initialEntryMode: TimePickerEntryMode.input
    );
    if (time != null && initialTime !=time) {
      if (!mounted) return;
      setState(() {
        _datetime = DateTime(
            initialDate.year,
            initialDate.month,
            initialDate.day,
            time.hour,
            time.minute
        );
      });
    }
  }

  void handleSaveTransaction(BuildContext context) async {
    final account = _account;
    final category = _category;
    if (account == null || category == null) return;
    final Payment payment = Payment(id: _id,
        account: account,
        category: category,
        amount: _amount,
        type: _type,
        datetime: _datetime,
        title: _title,
        description: _description
    );
    await _paymentDao.upsert(payment);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    globalEvent.emit('payment_update');
  }


  @override
  void initState()  {
    super.initState();
    populateState();
    _accountEventListener = globalEvent.on('account_update', (data){
      debugPrint('accounts are changed');
      loadAccounts();
    });

    _categoryEventListener = globalEvent.on('category_update', (data){
      debugPrint('categories are changed');
      loadCategories();
    });
  }

  @override
  void dispose() {

    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(!_initialised) return const CircularProgressIndicator();

    return
      Scaffold(
          appBar: AppBar(
            title: Text(widget.payment == null ? Strings.newTransaction : Strings.editTransaction, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),),
            actions: [
              if (widget.payment == null) const ReceiptScannerButton(),
              if (widget.payment == null) const VoiceInputButton(),
              _id!=null ? IconButton(
                  onPressed: (){
                    ConfirmModal.showConfirmDialog(context, title: Strings.areYouSure, content: const Text(Strings.afterDeletingPaymentCanTBe),
                        onConfirm: () async {
                          final id = _id;
                          if (id != null) await _paymentDao.deleteTransaction(id);
                          globalEvent.emit('payment_update');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        onCancel: (){
                          Navigator.pop(context);
                        }
                    );

                  }, icon: const Icon(Icons.delete, size: 20,), color: ThemeColors.error
              ) : const SizedBox()
            ],
          ),
          body: Column(
            children: [
              Expanded(
                  child:SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 25,),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.only(left: 15, right: 15, bottom:20),
                                child: Wrap(
                                  spacing: 10,
                                  children: [
                                    AppButton(
                                      onPressed: (){
                                        setState(() {
                                          _type = PaymentType.credit;
                                        });
                                      },
                                      label: 'Income',
                                      color: Theme.of(context).colorScheme.primary,
                                      type: _type == PaymentType.credit? AppButtonType.filled: AppButtonType.outlined,
                                      borderRadius: BorderRadius.circular(45),
                                    ),

                                    AppButton(
                                      onPressed: (){
                                        setState(() {
                                          _type = PaymentType.debit;
                                        });
                                      },
                                      label: 'Expense',
                                      color: Theme.of(context).colorScheme.primary,
                                      type: _type == PaymentType.debit? AppButtonType.filled: AppButtonType.outlined,
                                      borderRadius: BorderRadius.circular(45),
                                    )
                                  ],
                                )
                            ),

                            Container(
                              margin: const EdgeInsets.only(left: 15, right: 15, bottom:25),
                              child: TextFormField(
                                decoration:  InputDecoration(
                                    filled: true,
                                    hintText: Strings.title,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15)
                                ),
                                initialValue: _title,
                                onChanged: (text){
                                  _title = text;
                                  _suggestFromTitle(text);
                                },
                              ),
                            ),

                            Container(
                              margin: const EdgeInsets.only(left: 15, right: 15, bottom:25),
                              child: TextFormField(
                                maxLines: null,
                                decoration: InputDecoration(
                                    filled: true,
                                    hintText: Strings.description,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15)
                                ),
                                initialValue: _description,
                                onChanged: (text){
                                  setState(() {
                                    _description = text;
                                  });
                                },
                              ),
                            ),
                            Container(
                                margin: const EdgeInsets.only(left: 15, right: 15, bottom:25),
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                                  ],
                                  decoration: InputDecoration(
                                      filled: true,
                                      hintText: Strings.s00,
                                      prefixIcon: Padding(padding: const EdgeInsets.only(left: 15), child: CurrencyText(null)),
                                      prefixIconConstraints: const BoxConstraints(),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15)
                                  ),
                                  initialValue: _amount == 0 ? '' : _amount.toString(),
                                  onChanged: (String text){
                                    setState(() {
                                      _amount = double.tryParse(text) ?? 0.0;
                                    });
                                  },
                                )
                            ),

                            Container(
                                margin: const EdgeInsets.only(left: 15, right: 15, bottom:25),
                                child:   Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                        child: InkWell(
                                            onTap: (){
                                              chooseDate(context);
                                            },
                                            child:Wrap(
                                              spacing: 10,
                                              children: [
                                                Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary,),
                                                Text(DateFormat(AppDateFormats.numericShortDate).format(_datetime))
                                              ],
                                            )
                                        )
                                    ),

                                    Expanded(
                                        child: InkWell(
                                            onTap: (){
                                              chooseTime(context);
                                            },
                                            child:Wrap(
                                              spacing: 10,
                                              children: [
                                                Icon(Icons.watch_later_outlined, size: 18, color: Theme.of(context).colorScheme.primary,),
                                                Text(DateFormat(AppDateFormats.time12Hour).format(_datetime))
                                              ],
                                            )
                                        )
                                    ),
                                  ],
                                )
                            ),

                            Container(
                              padding: const EdgeInsets.only(left: 15, bottom: 15),
                              child: const Text(Strings.selectAccount, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                            ),
                            Container(
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 25),
                              width: double.infinity,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(left: 10, right: 10,),
                                children:List.generate(_accounts.length +1, (index){
                                  if(index == 0){
                                    return Container(
                                      margin: const EdgeInsets.only(right: 5, left: 5),
                                      width: 190,
                                      child: MaterialButton(
                                          minWidth: double.infinity,
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                              side: const BorderSide(
                                                  width: 1.5,
                                                  color: Colors.transparent
                                              )
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                          elevation: 0,
                                          focusElevation: 0,
                                          hoverElevation: 0,
                                          highlightElevation: 0,
                                          disabledElevation: 0,
                                          onPressed: (){
                                            showDialog(context: context, builder: (builder)=>const AccountForm());
                                          },
                                          child:  SizedBox(
                                            width: double.infinity,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                                  child: const Icon(Icons.add, color: Colors.white),
                                                ),
                                                const SizedBox(width: 10,),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(Strings.newText, style: Theme.of(context).textTheme.bodyMedium?.apply(fontWeightDelta: 2)),
                                                    Text(Strings.createAccount, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis,),
                                                  ],
                                                )
                                              ],
                                            ),
                                          )
                                      ),
                                    );
                                  }
                                  final Account account = _accounts[index-1];
                                  return Container(
                                      margin: const EdgeInsets.only(right: 5, left: 5),
                                      child: ConstrainedBox(
                                          constraints:   const BoxConstraints(),
                                          child:  IntrinsicWidth(
                                            child:MaterialButton(
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(18),
                                                    side: BorderSide(
                                                        width: 1.5,
                                                        color: _account?.id == account.id ? Theme.of(context).colorScheme.primary : Colors.transparent
                                                    )
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                                elevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                                disabledElevation: 0,
                                                onPressed: (){
                                                  setState(() {
                                                    _account = account;
                                                  });
                                                },
                                                child:  SizedBox(
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor: account.color.withValues(alpha: 0.2),
                                                        child: Icon(account.icon, color: account.color),
                                                      ),
                                                      const SizedBox(width: 10,),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Visibility(visible: account.holderName.isNotEmpty,child: Text(account.holderName, style: Theme.of(context).textTheme.bodyMedium?.apply(fontWeightDelta: 2)),),
                                                          Text(account.name, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis,),
                                                        ],
                                                      )

                                                    ],
                                                  ),
                                                )
                                            ),
                                          )
                                      )
                                  );
                                }),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.only(left: 15, bottom: 15),
                              child: const Text(Strings.selectCategory, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
                              width: double.infinity,
                              child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(_categories.length + 1, (index){
                                    if(_categories.length == index){
                                      return ConstrainedBox(
                                          constraints:   const BoxConstraints(),
                                          child:  IntrinsicWidth(
                                            child:MaterialButton(
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    side: const BorderSide(
                                                        width: 1.5,
                                                        color: Colors.transparent
                                                    )
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                                elevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                                disabledElevation: 0,
                                                onPressed: (){
                                                  showDialog(context: context, builder: (builder)=> const CategoryForm());
                                                },
                                                child:  SizedBox(
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.add, color: Theme.of(context).colorScheme.primary,),
                                                      const SizedBox(width: 10,),
                                                      Text(Strings.newCategory, style: Theme.of(context).textTheme.bodyMedium),
                                                    ],
                                                  ),
                                                )
                                            ),
                                          )
                                      );
                                    }
                                    final Category category = _categories[index];
                                    return ConstrainedBox(
                                        constraints:   const BoxConstraints(),
                                        child:  IntrinsicWidth(
                                            child:MaterialButton(
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                    side: BorderSide(
                                                        width: 1.5,
                                                        color: _category?.id == category.id ? Theme.of(context).colorScheme.primary : Colors.transparent
                                                    )
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                                elevation: 0,
                                                focusElevation: 0,
                                                hoverElevation: 0,
                                                highlightElevation: 0,
                                                disabledElevation: 0,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                onPressed: (){
                                                  setState(() {
                                                    _category = category;
                                                  });
                                                },
                                                onLongPress: (){
                                                  showDialog(context: context, builder: (builder)=>CategoryForm(category: category,));
                                                },
                                                child:  SizedBox(
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      Icon(category.icon, color: category.color),
                                                      const SizedBox(width: 10,),
                                                      Text(category.name, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis,),
                                                    ],
                                                  ),
                                                )
                                            )
                                        )
                                    );

                                  })

                              ),
                            )
                          ],
                        ) ,
                      )
                  )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: AppButton(
                  label: 'Save Transaction',
                  height: 50,
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  isFullWidth: true,
                  onPressed: _amount > 0 && _account!=null && _category!=null ? (){
                    handleSaveTransaction(context);
                  } : null,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            ],
          )
      );
  }
}