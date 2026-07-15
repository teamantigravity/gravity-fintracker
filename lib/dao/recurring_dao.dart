import 'dart:async';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/recurring.model.dart';
import 'package:fintracker/services/notification_service.dart';
import 'package:fintracker/services/rule_service.dart';

class RecurringDao {
  Future<int> create(RecurringTransaction recurring) async {
    final db = await getDBInstance();
    Map<String, dynamic> data = recurring.toJson();
    data.remove("id");
    return await db.insert("recurring_transactions", data);
  }

  Future<List<RecurringTransaction>> find({bool activeOnly = false}) async {
    final db = await getDBInstance();
    List<Category> categories = await CategoryDao().find(withSummery: false);
    List<Account> accounts = await AccountDao().find();

    final accountMap = {for (final a in accounts) a.id: a};
    final categoryMap = {for (final c in categories) c.id: c};

    String? where;
    if (activeOnly) {
      where = "isActive = 1";
    }

    List<Map<String, Object?>> rows = await db.query(
      "recurring_transactions",
      where: where,
      orderBy: "nextDueDate ASC",
    );

    List<RecurringTransaction> results = [];
    for (var row in rows) {
      Map<String, dynamic> data = Map<String, dynamic>.from(row);
      final Account? account = accountMap[data["account"]];
      final Category? category = categoryMap[data["category"]];
      if (account == null || category == null) continue;
      data["account"] = account.toJson();
      data["category"] = category.toJson();
      results.add(RecurringTransaction.fromJson(data));
    }
    return results;
  }

  Future<List<RecurringTransaction>> findDue() async {
    final db = await getDBInstance();
    List<Category> categories = await CategoryDao().find(withSummery: false);
    List<Account> accounts = await AccountDao().find();

    final accountMap = {for (final a in accounts) a.id: a};
    final categoryMap = {for (final c in categories) c.id: c};

    final now = DateTime.now().toIso8601String().substring(0, 10);
    List<Map<String, Object?>> rows = await db.query(
      "recurring_transactions",
      where: "isActive = 1 AND nextDueDate <= ?",
      whereArgs: [now],
    );

    List<RecurringTransaction> results = [];
    for (var row in rows) {
      Map<String, dynamic> data = Map<String, dynamic>.from(row);
      final Account? account = accountMap[data["account"]];
      final Category? category = categoryMap[data["category"]];
      if (account == null || category == null) continue;
      data["account"] = account.toJson();
      data["category"] = category.toJson();
      results.add(RecurringTransaction.fromJson(data));
    }
    return results;
  }

  Future<int> update(RecurringTransaction recurring) async {
    final db = await getDBInstance();
    return await db.update(
      "recurring_transactions",
      recurring.toJson(),
      where: "id = ?",
      whereArgs: [recurring.id],
    );
  }

  Future<int> updateNextDueDate(int id, DateTime nextDueDate) async {
    final db = await getDBInstance();
    return await db.update(
      "recurring_transactions",
      {"nextDueDate": nextDueDate.toIso8601String().substring(0, 10)},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> deactivate(int id) async {
    final db = await getDBInstance();
    return await db.update(
      "recurring_transactions",
      {"isActive": 0},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    return await db.delete(
      "recurring_transactions",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> processDueTransactions() async {
    List<RecurringTransaction> due = await findDue();
    if (due.isEmpty) return 0;

    final db = await getDBInstance();
    int processed = 0;
    for (RecurringTransaction recurring in due) {
      Payment payment = Payment(
        account: recurring.account,
        category: recurring.category,
        amount: recurring.amount,
        type: recurring.type == "CR" ? PaymentType.credit : PaymentType.debit,
        datetime: DateTime.now(),
        title: recurring.title,
        description: recurring.description,
      );

      DateTime next = recurring.calculateNextDueDate();
      recurring.nextDueDate = next;

      await db.transaction((txn) async {
        payment.id = await txn.insert("payments", payment.toJson());
        await txn.update(
          "recurring_transactions",
          recurring.toJson(),
          where: "id = ?",
          whereArgs: [recurring.id],
        );
      });

      await RuleService.evaluate(payment);

      await NotificationService().showDueBill(
        title: recurring.title,
        body: '${recurring.type == 'CR' ? 'Income' : 'Expense'} of ${recurring.amount} processed',
      );

      processed++;
    }
    return processed;
  }
}
