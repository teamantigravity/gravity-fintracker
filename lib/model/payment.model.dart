import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:intl/intl.dart';

enum PaymentType {
  debit,
  credit
}
class Payment {
  int? id;
  Account account;
  Category category;
  double amount;
  PaymentType type;
  DateTime datetime;
  String title;
  String description;

  Payment({
    this.id,
    required this.account,
    required this.category,
    required this.amount,
    required this.type,
    required this.datetime,
    required this.title,
    required this.description
  });


  factory Payment.fromJson(Map<String, dynamic> data) {
    return Payment(
      id: data["id"],
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      account: Account.fromJson(data["account"] is Map ? data["account"] : {"id": data["account"]}),
      category: Category.fromJson(data["category"] is Map ? data["category"] : {"id": data["category"]}),
      amount: (data["amount"] as num?)?.toDouble() ?? 0.0,
      type: data["type"] == "CR" ? PaymentType.credit : PaymentType.debit,
      datetime: DateTime.tryParse(data["datetime"] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "account": account.id,
    "category": category.id,
    "amount": amount,
    "datetime": DateFormat('yyyy-MM-dd HH:mm:ss').format(datetime),
    "type": type == PaymentType.credit ? "CR": "DR",
  };
}