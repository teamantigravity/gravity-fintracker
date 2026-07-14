import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fintracker/helpers/db.helper.dart' as dbHelper;
import 'dart:io';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Import Backup', () async {
    try {
      await dbHelper.import('C:\\Users\\varma\\OneDrive\\Desktop\\Projects\\fintracker-backup-1783997614028.json');
      final db = await dbHelper.getDBInstance();
      final accounts = await db.query('accounts');
      final categories = await db.query('categories');
      final payments = await db.query('payments');
      print('Import succeeded: \ accounts, \ categories, \ payments');
    } catch (e, stack) {
      print('Import failed: \\n\');
    }
  });
}
