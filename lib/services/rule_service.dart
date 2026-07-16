import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/rule_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/rule.model.dart';

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

  static bool _matches(Payment payment, Rule rule) {
    if (rule.sourceAccountId != null && payment.account.id != rule.sourceAccountId) return false;
    if (rule.sourceCategoryId != null && payment.category.id != rule.sourceCategoryId) return false;
    if (rule.type != null) {
      final paymentType = payment.type == PaymentType.credit ? 'CR' : 'DR';
      if (paymentType != rule.type) return false;
    }
    final minAmount = rule.minAmount;
    final maxAmount = rule.maxAmount;
    if (minAmount != null && payment.amount < minAmount) return false;
    if (maxAmount != null && payment.amount > maxAmount) return false;
    return true;
  }

  static Future<Account?> _resolveAccount(int? id) async {
    if (id == null) return null;
    final accounts = await AccountDao().find();
    return {for (final a in accounts) a.id: a}[id];
  }

  static Future<Category?> _resolveCategory(int? id) async {
    if (id == null) return null;
    final categories = await CategoryDao().find(withSummery: false);
    return {for (final c in categories) c.id: c}[id];
  }

}
