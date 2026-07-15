import 'dart:async';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/rule.model.dart';

class RuleDao {
  Future<int> create(Rule rule) async {
    final db = await getDBInstance();
    final data = rule.toJson();
    data.remove("id");
    return await db.insert("rules", data);
  }

  Future<List<Rule>> find() async {
    final db = await getDBInstance();
    final rows = await db.query("rules", orderBy: "name ASC");
    return rows.map((r) => Rule.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<List<Rule>> findActive() async {
    final db = await getDBInstance();
    final rows = await db.query(
      "rules",
      where: "enabled = ?",
      whereArgs: [1],
    );
    return rows.map((r) => Rule.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<int> update(Rule rule) async {
    final db = await getDBInstance();
    return await db.update("rules", rule.toJson(), where: "id = ?", whereArgs: [rule.id]);
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    return await db.delete("rules", where: "id = ?", whereArgs: [id]);
  }
}
