import 'dart:async';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PaymentDao {
  Future<int> create(Payment payment) async {
    final db = await getDBInstance();
    var result = await db.insert("payments", payment.toJson());
    return result;
  }

  Future<List<Payment>> find({
    DateTimeRange? range,
    PaymentType? type,
    Category? category,
    Account? account
}) async {
    final db = await getDBInstance();
    String where = "";

    if(range!=null){
      where += "AND datetime BETWEEN DATE('${DateFormat('yyyy-MM-dd HH:mm:ss').format(range.start)}') AND DATE('${DateFormat('yyyy-MM-dd HH:mm:ss').format(range.end.add(const Duration(days: 1)))}')";
    }

    //type check
    if(type != null){
      where += "AND type='${type == PaymentType.credit?"CR":"DR"}' ";
    }

    //account check
    if(account != null && account.id != null){
      where += "AND account='${account.id}' ";
    }

    //category check
    if(category != null && category.id != null){
      where += "AND category='${category.id}' ";
    }

    //categories
    List<Category> categories = await CategoryDao().find();
    List<Account> accounts = await AccountDao().find();


    List<Payment> payments = [];
    List<Map<String, Object?>> rows =  await db.query(
        "payments",
        orderBy: "datetime DESC, id DESC",
        where: "1=1 $where"
    );
    for (var row in rows) {
      Map<String, dynamic> payment = Map<String, dynamic>.from(row);
      try {
        Account account = accounts.firstWhere((a) => a.id == payment["account"]);
        Category category = categories.firstWhere((c) => c.id == payment["category"]);
        payment["category"] = category.toJson();
        payment["account"] = account.toJson();
        payments.add(Payment.fromJson(payment));
      } catch (_) {
        // Skip orphaned payments whose account/category no longer exists
      }
    }

    return payments;
  }

  Future<Payment?> findByTitle(String title, PaymentType type) async {
    final db = await getDBInstance();
    List<Category> categories = await CategoryDao().find();
    List<Account> accounts = await AccountDao().find();

    List<Map<String, Object?>> rows = await db.query(
      "payments",
      where: "LOWER(title) = LOWER(?) AND type = ?",
      whereArgs: [title, type == PaymentType.credit ? "CR" : "DR"],
      orderBy: "datetime DESC, id DESC",
      limit: 1,
    );
    if (rows.isEmpty) return null;
    Map<String, dynamic> payment = Map<String, dynamic>.from(rows.first);
    try {
      Account account = accounts.firstWhere((a) => a.id == payment["account"]);
      Category category = categories.firstWhere((c) => c.id == payment["category"]);
      payment["category"] = category.toJson();
      payment["account"] = account.toJson();
      return Payment.fromJson(payment);
    } catch (_) {
      return null;
    }
  }

  Future<int> update(Payment payment) async {
    final db = await getDBInstance();

    var result = await db.update("payments", payment.toJson(), where: "id = ?", whereArgs: [payment.id]);

    return result;
  }

  Future<int> upsert(Payment payment) async {
    final db = await getDBInstance();
    int result;
    if(payment.id != null) {
      result = await db.update(
          "payments", payment.toJson(), where: "id = ?",
          whereArgs: [payment.id]);
    } else {
      result = await db.insert("payments", payment.toJson());
    }

    return result;
  }


  Future<int> deleteTransaction(int id) async {
    final db = await getDBInstance();
    var result = await db.delete("payments", where: 'id = ?', whereArgs: [id]);
    return result;
  }
}