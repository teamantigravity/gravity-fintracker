import 'package:fintracker/helpers/icon.helper.dart';
import 'package:flutter/material.dart';

class Account {
  int? id;
  String name;
  String holderName;
  String accountNumber;
  IconData icon;
  Color color;
  bool? isDefault;
  double? balance;
  double? income;
  double? expense;

  Account({
    this.id,
    required this.name,
    required this.holderName,
    required this.accountNumber,
    required this.icon,
    required this.color,
    this.isDefault,
    this.income,
    this.expense,
    this.balance
  });



  factory Account.fromJson(Map<String, dynamic> data) => Account(
    id: data["id"],
    name: data["name"] ?? 'Unknown',
    holderName: data["holderName"] ?? "",
    accountNumber: data["accountNumber"] ?? "",
    icon: data["icon"] is int ? IconHelper.lookup(data["icon"], fallback: Icons.account_balance) : Icons.account_balance,
    color: data["color"] is int ? Color(data["color"]) : Colors.grey,
    isDefault: data["isDefault"] == true || data["isDefault"] == 1,
    income: (data["income"] as num?)?.toDouble(),
    expense: (data["expense"] as num?)?.toDouble(),
    balance: (data["balance"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "holderName": holderName,
    "accountNumber": accountNumber,
    "icon": icon.codePoint,
    "color": color.toARGB32(),
    "isDefault": (isDefault??false) ? 1:0
  };
}