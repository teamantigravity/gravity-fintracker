import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/model/savings_goal.model.dart';

class SavingsGoalDao {
  Future<int> create(SavingsGoal goal) async {
    final db = await getDBInstance();
    return db.insert('savings_goals', goal.toJson());
  }

  Future<List<SavingsGoal>> find({bool includeArchived = false}) async {
    final db = await getDBInstance();
    final accounts = await AccountDao().find();
    final accountMap = {for (final a in accounts) a.id: a};
    final rows = await db.query(
      'savings_goals',
      orderBy: 'deadline ASC',
    );

    List<SavingsGoal> goals = [];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final accountId = map['account'];
      if (accountId != null) {
        final account = accountMap[accountId];
        map['account'] = account?.toJson();
      }
      final goal = SavingsGoal.fromJson(map);
      if (!goal.isArchived || includeArchived) goals.add(goal);
    }
    return goals;
  }

  Future<int> update(SavingsGoal goal) async {
    final db = await getDBInstance();
    return db.update('savings_goals', goal.toJson(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> upsert(SavingsGoal goal) async {
    if (goal.id != null) return update(goal);
    return create(goal);
  }

  Future<int> delete(int id) async {
    final db = await getDBInstance();
    return db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
