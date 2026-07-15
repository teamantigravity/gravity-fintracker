import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategorySummary {
  final String categoryName;
  final double income;
  final double expense;

  CategorySummary({
    required this.categoryName,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

class ReportSummary {
  final DateTime startDate;
  final DateTime endDate;
  final List<CategorySummary> categories;
  final double totalIncome;
  final double totalExpense;
  final double net;

  ReportSummary({
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });
}

class ReportsService {
  static Future<ReportSummary> generateSummary(DateTimeRange range) async {
    final payments = await PaymentDao().find(range: range);

    final map = <String, CategorySummary>{};
    double totalIncome = 0;
    double totalExpense = 0;

    for (final payment in payments) {
      final name = payment.category.name;
      final summary = map.putIfAbsent(
        name,
        () => CategorySummary(categoryName: name, income: 0, expense: 0),
      );

      if (payment.type == PaymentType.credit) {
        totalIncome += payment.amount;
        map[name] = CategorySummary(
          categoryName: name,
          income: summary.income + payment.amount,
          expense: summary.expense,
        );
      } else {
        totalExpense += payment.amount;
        map[name] = CategorySummary(
          categoryName: name,
          income: summary.income,
          expense: summary.expense + payment.amount,
        );
      }
    }

    final categories = map.values.toList()
      ..sort((a, b) => b.net.abs().compareTo(a.net.abs()));

    return ReportSummary(
      startDate: range.start,
      endDate: range.end,
      categories: categories,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      net: totalIncome - totalExpense,
    );
  }

  static Future<String> exportTaxReportCsv(DateTimeRange range, {String? filePath}) async {
    if (kIsWeb) throw UnsupportedError('CSV export is not supported on web.');

    final summary = await generateSummary(range);
    final payments = await PaymentDao().find(range: range);

    final rows = <List<dynamic>>[];
    rows.add(['Tax & Export Report']);
    rows.add(['Start Date', _formatDate(summary.startDate)]);
    rows.add(['End Date', _formatDate(summary.endDate)]);
    rows.add([]);

    rows.add(['Category', 'Income', 'Expense', 'Net']);
    for (final category in summary.categories) {
      rows.add([
        category.categoryName,
        _formatCurrency(category.income),
        _formatCurrency(category.expense),
        _formatCurrency(category.net),
      ]);
    }
    rows.add(['TOTAL', _formatCurrency(summary.totalIncome), _formatCurrency(summary.totalExpense), _formatCurrency(summary.net)]);
    rows.add([]);

    rows.add(['Date', 'Title', 'Category', 'Account', 'Type', 'Amount']);
    for (final payment in payments) {
      rows.add([
        _formatDateTime(payment.datetime),
        payment.title,
        payment.category.name,
        payment.account.name,
        payment.type == PaymentType.credit ? 'Income' : 'Expense',
        _formatCurrency(payment.amount),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final targetPath = filePath ?? '${await getExternalDocumentPath()}/${_generateFileName()}';
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(csvData);
    return file.path;
  }

  static String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  static String _formatDateTime(DateTime date) => DateFormat('yyyy-MM-dd HH:mm').format(date);
  static String _formatCurrency(double value) => value.toStringAsFixed(2);
  static String _generateFileName() => 'gravity-tax-report-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.csv';
}
