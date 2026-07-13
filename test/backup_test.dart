import 'dart:io';
import 'dart:convert';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );
  });

  tearDownAll(() async {
    await database?.close();
  });

  tearDown(() async {
    await database?.rawDelete('DELETE FROM payments');
    await database?.rawDelete('DELETE FROM accounts');
    await database?.rawDelete('DELETE FROM categories');
    await database?.rawDelete('DELETE FROM recurring_transactions');
  });

  group('JSON export/import', () {
    test('export and import roundtrip preserves data', () async {
      final tempDir = await Directory.systemTemp.createTemp('fintracker_backup');

      final account = Account(
        name: 'Cash',
        holderName: 'Test',
        accountNumber: '1234',
        icon: Icons.wallet,
        color: Colors.teal,
      );
      final accountId = await AccountDao().create(account);

      final category = Category(
        name: 'Food',
        icon: Icons.restaurant,
        color: Colors.orange,
        budget: 500,
      );
      final categoryId = await CategoryDao().create(category);

      final payment = Payment(
        account: Account(
          id: accountId,
          name: 'Cash',
          holderName: 'Test',
          accountNumber: '1234',
          icon: Icons.wallet,
          color: Colors.teal,
        ),
        category: Category(
          id: categoryId,
          name: 'Food',
          icon: Icons.restaurant,
          color: Colors.orange,
          budget: 500,
        ),
        amount: 42.50,
        type: PaymentType.debit,
        datetime: DateTime(2026, 7, 13, 10, 30),
        title: 'Lunch',
        description: 'Burger',
      );
      await PaymentDao().create(payment);

      final backupPath = await export(directory: tempDir.path);
      expect(File(backupPath).existsSync(), true);

      final backupContent = await File(backupPath).readAsString();
      final backup = jsonDecode(backupContent) as Map<String, dynamic>;
      expect(backup['accounts'], hasLength(1));
      expect(backup['categories'], hasLength(1));
      expect(backup['payments'], hasLength(1));

      // clear and re-import
      await database?.rawDelete('DELETE FROM payments');
      await database?.rawDelete('DELETE FROM accounts');
      await database?.rawDelete('DELETE FROM categories');

      await import(backupPath);

      final importedAccounts = await AccountDao().find();
      final importedCategories = await CategoryDao().find(withSummery: false);
      final importedPayments = await PaymentDao().find();

      expect(importedAccounts, hasLength(1));
      expect(importedCategories, hasLength(1));
      expect(importedPayments, hasLength(1));

      expect(importedAccounts.first.name, 'Cash');
      expect(importedCategories.first.name, 'Food');
      expect(importedPayments.first.amount, 42.50);
      expect(importedPayments.first.title, 'Lunch');
      expect(importedPayments.first.category.id, importedCategories.first.id);
      expect(importedPayments.first.account.id, importedAccounts.first.id);

      await tempDir.delete(recursive: true);
    });
  });
}
