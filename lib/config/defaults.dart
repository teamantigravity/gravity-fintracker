import 'package:flutter/material.dart';

import 'package:fintracker/theme/prism_colors.dart';

/// Centralized default seed data for new installs.
///
/// Keeping account / category / color defaults here makes them easy to localize,
/// re-brand, or theme without touching database logic.
class AppDefaults {
  AppDefaults._();

  /// Default account created when the database is reset.
  static final Map<String, dynamic> defaultAccount = {
    'name': 'Cash',
    'icon': Icons.wallet.codePoint,
    'color': Colors.teal.toARGB32(),
    'isDefault': 1,
  };

  /// Tokenized color palette used for default category chips.
  static const List<Color> categoryPalette = [
    PrismColors.income,
    PrismColors.expense,
    PrismColors.info,
    PrismColors.warning,
    PrismColors.googleBlue,
    PrismColors.googleRed,
    PrismColors.googleYellow,
    PrismColors.googleGreen,
    PrismColors.primary,
    PrismColors.success,
  ];

  /// Default categories created when the database is reset.
  static final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Housing', 'icon': Icons.house.codePoint},
    {'name': 'Transportation', 'icon': Icons.emoji_transportation.codePoint},
    {'name': 'Food', 'icon': Icons.restaurant.codePoint},
    {'name': 'Utilities', 'icon': Icons.category.codePoint},
    {'name': 'Insurance', 'icon': Icons.health_and_safety.codePoint},
    {'name': 'Medical & Healthcare', 'icon': Icons.medical_information.codePoint},
    {'name': 'Saving, Investing, & Debt Payments', 'icon': Icons.attach_money.codePoint},
    {'name': 'Personal Spending', 'icon': Icons.shopping_bag.codePoint},
    {'name': 'Recreation & Entertainment', 'icon': Icons.tv.codePoint},
    {'name': 'Miscellaneous', 'icon': Icons.library_books_sharp.codePoint},
  ];

  /// CSV export column headers.
  static const List<String> csvHeaders = [
    'ID',
    'Date',
    'Title',
    'Description',
    'Category',
    'Account',
    'Type',
    'Amount',
  ];

  /// Labels used inside CSV rows for the transaction type.
  static const String csvIncomeLabel = 'Income';
  static const String csvExpenseLabel = 'Expense';

  /// Filename prefixes used for exports.
  static const String csvFileNamePrefix = 'gravity-fintracker-';
  static const String jsonBackupFileNamePrefix = 'fintracker-backup-';
}
