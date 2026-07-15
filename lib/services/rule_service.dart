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
    if (rule.minAmount != null && payment.amount < rule.minAmount!) return false;
    if (rule.maxAmount != null && payment.amount > rule.maxAmount!) return false;
    return true;
  }

  static Future<Account?> _resolveAccount(int id) async {
    final accounts = await AccountDao().find();
    return accounts.cast<Account?>().firstWhere(
      (a) => a?.id == id,
      orElse: () => null,
    );
  }

  static Future<Category?> _resolveCategory(int id) async {
    final categories = await CategoryDao().find(withSummery: false);
    return categories.cast<Category?>().firstWhere(
      (c) => c?.id == id,
      orElse: () => null,
    );
  }

}
