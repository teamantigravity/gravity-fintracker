
import "dart:convert";
import "dart:io";
import "package:csv/csv.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:path/path.dart";
import "package:fintracker/helpers/migrations/migrations.dart";
import "package:sqflite/sqflite.dart";

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Database? database;
Future<Database> getDBInstance() async {
  if(database == null) {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'database.db');
    Database db = await openDatabase(dbPath, version: 2, onCreate: onCreate, onUpgrade: onUpgrade);

    database = db;
    return db;
  } else {
    Database db = database!;
    return db;
  }
}

typedef MigrationCallback = Function(Database database);
List<MigrationCallback>migrations = [
  v1,
  v2
];
void onCreate(Database database,  int version) async {
  for(MigrationCallback callback in migrations){
    await callback(database);
  }
}

void onUpgrade(Database database, int oldVersion, int version) async {
  for(int index = oldVersion; index < version; index++){
    MigrationCallback callback = migrations[index];
    await callback(database);
  }
}

Future<void> resetDatabase() async {
  Database database = await getDBInstance();
  await database.delete("payments", where: "id>0");
  await database.delete("recurring_transactions", where: "id>0");
  await database.delete("accounts", where: "id>0");
  await database.delete("categories", where: "id>0");

  await database.insert("accounts", {
    "name": "Cash",
    "icon": Icons.wallet.codePoint,
    "color": Colors.teal.toARGB32(),
    "isDefault": 1
  });

  //prefill all categories
  List<Map<String, dynamic>> categories = [
    {"name": "Housing", "icon": Icons.house.codePoint},
    {"name": "Transportation", "icon": Icons.emoji_transportation.codePoint},
    {"name": "Food", "icon": Icons.restaurant.codePoint},
    {"name": "Utilities", "icon": Icons.category.codePoint},
    {"name": "Insurance", "icon": Icons.health_and_safety.codePoint},
    {"name": "Medical & Healthcare", "icon": Icons.medical_information.codePoint},
    {"name": "Saving, Investing, & Debt Payments", "icon": Icons.attach_money.codePoint},
    {"name": "Personal Spending", "icon": Icons.house.codePoint},
    {"name": "Recreation & Entertainment", "icon": Icons.tv.codePoint},
    {"name": "Miscellaneous", "icon": Icons.library_books_sharp.codePoint},
  ];

  int index = 0;
  for(Map<String, dynamic> category in categories){
    await database.insert("categories", {
      "name": category["name"],
      "icon": category["icon"],
      "color": Colors.primaries[index].toARGB32(),
    });
    index++;
  }
}


Future<String> getExternalDocumentPath({String? fallbackPath}) async {
  // To check whether permission is given for this app or not.
  Directory? directory;
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      directory = Directory("/storage/emulated/0/Download");
    }
  }

  if (directory == null) {
    if (fallbackPath != null && fallbackPath.isNotEmpty) {
      directory = Directory(fallbackPath);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
  }

  final exPath = directory.path;
  await Directory(exPath).create(recursive: true);
  return exPath;
}
Future<String> export({String? directory, String? filePath}) async {
  await getDBInstance();
  List<dynamic> accounts = await database!.query("accounts",);
  List<dynamic> categories = await database!.query("categories",);
  List<dynamic> payments = await database!.query("payments",);
  List<dynamic> recurring = await database!.query("recurring_transactions",);
  Map<String, dynamic> data = {};
  data["accounts"] = accounts;
  data["categories"] = categories;
  data["payments"] = payments;
  data["recurring_transactions"] = recurring;

  if (filePath != null && filePath.isNotEmpty) {
    File file = File(filePath);
    await file.writeAsString(jsonEncode(data));
    return file.path;
  }

  final path = await getExternalDocumentPath(fallbackPath: directory);
  String name = "fintracker-backup-${DateTime.now().millisecondsSinceEpoch}.json";
  File file= File('$path/$name');
  await file.writeAsString(jsonEncode(data));
  return file.path;
}


Future<String> exportCsv({String? directory, String? filePath}) async {
  await getDBInstance();
  List<dynamic> payments = await database!.rawQuery(
    "SELECT p.id, p.title, p.description, p.amount, p.type, p.datetime, "
    "c.name as categoryName, a.name as accountName "
    "FROM payments p "
    "LEFT JOIN categories c ON c.id = p.category "
    "LEFT JOIN accounts a ON a.id = p.account "
    "ORDER BY p.datetime DESC"
  );

  List<List<dynamic>> rows = [
    ['ID', 'Date', 'Title', 'Description', 'Category', 'Account', 'Type', 'Amount']
  ];

  for (var payment in payments) {
    rows.add([
      payment['id'],
      payment['datetime'],
      payment['title'] ?? '',
      payment['description'] ?? '',
      payment['categoryName'] ?? '',
      payment['accountName'] ?? '',
      payment['type'] == 'CR' ? 'Income' : 'Expense',
      payment['amount'],
    ]);
  }

  String csvData = const ListToCsvConverter().convert(rows);

  if (filePath != null && filePath.isNotEmpty) {
    File file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  final path = await getExternalDocumentPath(fallbackPath: directory);
  String name = "gravity-fintracker-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.csv";
  File file = File('$path/$name');
  await file.writeAsString(csvData);
  return file.path;
}

Future<void> import(String path) async {
  File file = File(path);
  Map<int, int> accountsMap = {};
  Map<int, int> categoriesMap = {};

  try{
    final String content = await file.readAsString();
    Map<String, dynamic> data = jsonDecode(content);
    await getDBInstance();
    await database!.transaction((transaction) async{
      await transaction.delete("recurring_transactions");
      await transaction.delete("payments");
      await transaction.delete("categories");
      await transaction.delete("accounts");

      List<dynamic> categories = (data["categories"] ?? []);
      List<dynamic> accounts = (data["accounts"] ?? []);
      List<dynamic> payments = (data["payments"] ?? []);
      List<dynamic> recurring = (data["recurring_transactions"] ?? []);

      for(Map<String, dynamic> category in categories.cast<Map<String, dynamic>>()){
        int id0 = category["id"] ?? 0;
        category.remove("id");
        int id = await transaction.insert("categories", category);
        categoriesMap[id0] = id;
      }

      for(Map<String, dynamic> account in accounts.cast<Map<String, dynamic>>()){
        int id0 = account["id"] ?? 0;
        account.remove("id");
        int id = await transaction.insert("accounts", account);
        accountsMap[id0] = id;
      }

      for(Map<String, dynamic> payment in payments.cast<Map<String, dynamic>>()){
        payment.remove("id");
        payment["account"] = accountsMap[payment["account"]];
        payment["category"] = categoriesMap[payment["category"]];
        await transaction.insert("payments", payment);
      }

      for(Map<String, dynamic> item in recurring.cast<Map<String, dynamic>>()){
        item.remove("id");
        item["account"] = accountsMap[item["account"]];
        item["category"] = categoriesMap[item["category"]];
        await transaction.insert("recurring_transactions", item);
      }

      return transaction;
    });
  } catch(err){
    rethrow;
  }
}

