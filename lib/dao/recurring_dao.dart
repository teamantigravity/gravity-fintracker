import 'dart:async';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/recurring.model.dart';

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
      try {
        Account account = accounts.firstWhere((a) => a.id == data["account"]);
        Category category = categories.firstWhere((c) => c.id == data["category"]);
        data["account"] = account.toJson();
        data["category"] = category.toJson();
        results.add(RecurringTransaction.fromJson(data));
      } catch (_) {
        // Skip if account/category was deleted
        continue;
      }
    }
    return results;
  }

  Future<List<RecurringTransaction>> findDue() async {
    final db = await getDBInstance();
    List<Category> categories = await CategoryDao().find(withSummery: false);
    List<Account> accounts = await AccountDao().find();

    final now = DateTime.now().toIso8601String().substring(0, 10);
    List<Map<String, Object?>> rows = await db.query(
      "recurring_transactions",
      where: "isActive = 1 AND nextDueDate <= ?",
      whereArgs: [now],
    );

    List<RecurringTransaction> results = [];
    for (var row in rows) {
      Map<String, dynamic> data = Map<String, dynamic>.from(row);
      try {
        Account account = accounts.firstWhere((a) => a.id == data["account"]);
        Category category = categories.firstWhere((c) => c.id == data["category"]);
        data["account"] = account.toJson();
        data["category"] = category.toJson();
        results.add(RecurringTransaction.fromJson(data));
      } catch (_) {
        continue;
      }
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
}
