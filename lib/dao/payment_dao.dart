import 'dart:async';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/services/rule_service.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/config/app_date_formats.dart';
import 'package:intl/intl.dart';


class PaymentDao {
  Future<int> create(Payment payment) async {
    final db = await getDBInstance();
    final result = await db.insert('payments', payment.toJson());
    payment.id = result;
    await RuleService.evaluate(payment);
    return result;
  }

  Future<List<Payment>> find({
    DateTimeRange? range,
    PaymentType? type,
    Category? category,
    Account? account
}) async {
    final db = await getDBInstance();
    final List<String> whereClauses = [];
    final List<Object> whereArgs = [];
    final dateFormatter = DateFormat(AppDateFormats.sqlDateTimeSecond);

    if(range!=null){
      whereClauses.add('datetime BETWEEN DATE(?) AND DATE(?)');
      whereArgs.add(dateFormatter.format(range.start));
      whereArgs.add(dateFormatter.format(range.end.add(const Duration(days: 1))));
    }

    //type check
    if(type != null){
      whereClauses.add('type = ?');
      whereArgs.add(type == PaymentType.credit?'CR':'DR');
    }

    //account check
    final accountId = account?.id;
    if(accountId != null){
      whereClauses.add('account = ?');
      whereArgs.add(accountId);
    }

    //category check
    final categoryId = category?.id;
    if(categoryId != null){
      whereClauses.add('category = ?');
      whereArgs.add(categoryId);
    }

    //categories
    final List<Category> categories = await CategoryDao().find();
    final List<Account> accounts = await AccountDao().find();

    final accountMap = {for (final a in accounts) a.id: a};
    final categoryMap = {for (final c in categories) c.id: c};

    final List<Payment> payments = [];
    final List<Map<String, Object?>> rows =  await db.query(
        'payments',
        orderBy: 'datetime DESC, id DESC',
        where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null
    );
    for (final row in rows) {
      final Map<String, dynamic> payment = Map<String, dynamic>.from(row);
      final Account? account = accountMap[payment['account']];
      final Category? category = categoryMap[payment['category']];
      if (account == null || category == null) continue;
      payment['category'] = category.toJson();
      payment['account'] = account.toJson();
      payments.add(Payment.fromJson(payment));
    }

    return payments;
  }

  Future<Payment?> findByTitle(String title, PaymentType type) async {
    final db = await getDBInstance();
    final List<Category> categories = await CategoryDao().find();
    final List<Account> accounts = await AccountDao().find();

    final accountMap = {for (final a in accounts) a.id: a};
    final categoryMap = {for (final c in categories) c.id: c};

    final List<Map<String, Object?>> rows = await db.query(
      'payments',
      where: 'LOWER(title) = LOWER(?) AND type = ?',
      whereArgs: [title, type == PaymentType.credit ? 'CR' : 'DR'],
      orderBy: 'datetime DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final Map<String, dynamic> payment = Map<String, dynamic>.from(rows.first);
    final Account? account = accountMap[payment['account']];
    final Category? category = categoryMap[payment['category']];
    if (account == null || category == null) return null;
    payment['category'] = category.toJson();
    payment['account'] = account.toJson();
    return Payment.fromJson(payment);
  }

  Future<int> upsert(Payment payment) async {
    final db = await getDBInstance();
    int result;
    final wasNew = payment.id == null;
    if(payment.id != null) {
      result = await db.update(
          'payments', payment.toJson(), where: 'id = ?',
          whereArgs: [payment.id]);
    } else {
      result = await db.insert('payments', payment.toJson());
      payment.id = result;
    }

    if (wasNew) {
      await RuleService.evaluate(payment);
    }

    return result;
  }


  Future<int> deleteTransaction(int id) async {
    final db = await getDBInstance();
    final result = await db.delete('payments', where: 'id = ?', whereArgs: [id]);
    return result;
  }
}