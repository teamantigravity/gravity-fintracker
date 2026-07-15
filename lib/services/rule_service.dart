import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/rule_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/rule.model.dart';
import 'package:intl/intl.dart';

class RuleService {
  static final RuleDao _ruleDao = RuleDao();

  static Future<List<Payment>> evaluate(Payment payment) async {
    final rules = await _ruleDao.findActive();
    final created = <Payment>[];

    for (final rule in rules) {
      if (!_matches(payment, rule)) continue;

      final targetAmount = payment.amount * rule.percentage;
      if (targetAmount <= 0) continue;

      final targetAccount = await _resolveAccount(rule.targetAccountId);
      final targetCategory = await _resolveCategory(rule.targetCategoryId);
      if (targetAccount == null || targetCategory == null) continue;

      final targetTypeString = rule.targetType ?? (payment.type == PaymentType.credit ? 'DR' : 'CR');

      final child = Payment(
        account: targetAccount,
        category: targetCategory,
        amount: targetAmount,
        type: targetTypeString == 'CR' ? PaymentType.credit : PaymentType.debit,
        datetime: payment.datetime,
        title: 'Auto: ${rule.name}',
        description: rule.description.isNotEmpty
            ? rule.description
            : 'Generated from ${payment.title}',
      );

      final db = await getDBInstance();
      await db.insert("payments", child.toJson());
      created.add(child);
    }

    return created;
  }

  static Future<List<Payment>> evaluateAll() async {
    final payments = await _allPayments();
    final all = <Payment>[];
    for (final payment in payments) {
      all.addAll(await evaluate(payment));
    }
    return all;
  }

  static bool _matches(Payment payment, Rule rule) {
    if (rule.sourceAccountId != null && payment.account.id != rule.sourceAccountId) return false;
    if (rule.sourceCategoryId != null && payment.category.id != rule.sourceCategoryId) return false;
    if (rule.type != null) {
      final paymentType = payment.type == PaymentType.credit ? 'CR' : 'DR';
      if (paymentType != rule.type) return false;
    }
    if (rule.minAmount != null && payment.amount < rule.minAmount!) return false;
    if (rule.maxAmount != null && payment.amount > rule.maxAmount!) return false;
    return true;
  }

  static Future<Account?> _resolveAccount(int id) async {
    final accounts = await AccountDao().find();
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Category?> _resolveCategory(int id) async {
    final categories = await CategoryDao().find(withSummery: false);
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Payment>> _allPayments() async {
    final db = await getDBInstance();
    final accounts = await AccountDao().find();
    final categories = await CategoryDao().find(withSummery: false);
    final rows = await db.query("payments", orderBy: "datetime DESC, id DESC");

    final payments = <Payment>[];
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row);
      try {
        final account = accounts.firstWhere((a) => a.id == data["account"]);
        final category = categories.firstWhere((c) => c.id == data["category"]);
        data["account"] = account.toJson();
        data["category"] = category.toJson();
        data["datetime"] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(data["datetime"]));
        payments.add(Payment.fromJson(data));
      } catch (_) {
        // skip orphaned
      }
    }
    return payments;
  }
}
