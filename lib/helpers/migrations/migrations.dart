import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

void v1(Database database) async {
  debugPrint('Running first migration....');
  await database.execute('CREATE TABLE payments ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NULL, '
      'description TEXT NULL, '
      'account INTEGER,'
      'category INTEGER,'
      'amount REAL,'
      'type TEXT,'
      'datetime DATETIME'
      ')');

  await database.execute('CREATE TABLE categories ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT,'
      'icon INTEGER,'
      'color INTEGER,'
      'budget REAL NULL, '
      'type TEXT'
      ')');

  await database.execute('CREATE TABLE accounts ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT,'
      'holderName TEXT NULL, '
      'accountNumber TEXT NULL, '
      'icon INTEGER,'
      'color INTEGER,'
      'isDefault INTEGER'
      ')');
}

void v2(Database database) async {
  debugPrint('Running second migration — recurring transactions....');
  await database.execute('CREATE TABLE IF NOT EXISTS recurring_transactions ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NULL, '
      'description TEXT NULL, '
      'account INTEGER,'
      'category INTEGER,'
      'amount REAL,'
      'type TEXT,'
      'interval TEXT,'
      'startDate TEXT,'
      'nextDueDate TEXT,'
      'isActive INTEGER DEFAULT 1'
      ')');
}

void v3(Database database) async {
  debugPrint('Running third migration — savings goals....');
  await database.execute('CREATE TABLE IF NOT EXISTS savings_goals ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT,'
      'targetAmount REAL,'
      'savedAmount REAL DEFAULT 0,'
      'deadline TEXT,'
      'account INTEGER,'
      'icon INTEGER,'
      'color INTEGER,'
      'isArchived INTEGER DEFAULT 0'
      ')');
}

void v4(Database database) async {
  debugPrint('Running fourth migration — automation rules....');
  await database.execute('CREATE TABLE IF NOT EXISTS rules ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT,'
      'enabled INTEGER DEFAULT 1,'
      'sourceAccount INTEGER,'
      'sourceCategory INTEGER,'
      'type TEXT,'
      'minAmount REAL,'
      'maxAmount REAL,'
      'percentage REAL,'
      'targetAccount INTEGER,'
      'targetCategory INTEGER,'
      'targetType TEXT,'
      'description TEXT'
      ')');
}