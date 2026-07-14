import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fintracker/helpers/db.helper.dart' as dbHelper;
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  try {
      await dbHelper.import('C:\\Users\\varma\\OneDrive\\Desktop\\Projects\\fintracker-backup-1783997614028.json');
      print('Import executed');
      
      final dao = PaymentDao();
      var range = DateTimeRange(start: DateTime.parse('2026-07-01'), end: DateTime.parse('2026-07-15'));
      var payments = await dao.find(range: range);
      print('Found \ payments in July 2026');
      
      var allPayments = await dao.find();
      print('Found \ payments total');
  } catch (e, stack) {
      print('Failed: \\n\');
  }
}
