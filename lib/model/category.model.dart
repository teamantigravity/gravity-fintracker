import 'package:fintracker/helpers/icon.helper.dart';
import 'package:flutter/material.dart';

class Category {
  int? id;
  String name;
  IconData icon;
  Color color;
  double? budget;
  double? expense;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
    this.expense
  });

  factory Category.fromJson(Map<String, dynamic> data) => Category(
    id: data['id'],
    name: data['name'] ?? 'Unknown',
    icon: data['icon'] is int ? IconHelper.lookup(data['icon'], fallback: Icons.category) : Icons.category,
    color: data['color'] is int ? Color(data['color']) : Colors.grey,
    budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
    expense: (data['expense'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'budget': budget,
  };
}