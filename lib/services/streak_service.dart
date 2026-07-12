import 'package:fintracker/model/payment.model.dart';

/// Computes a genuine daily-logging streak from real transaction history —
/// no fake numbers. A day "counts" if at least one transaction was logged
/// on it. Used to encourage consistent tracking (a well-established
/// retention mechanic), always grounded in the user's actual data.
class StreakService {
  /// Current streak, counting backwards from today (or yesterday, so a
  /// streak isn't lost just because today hasn't been logged *yet*).
  static int currentStreak(List<Payment> allPayments) {
    if (allPayments.isEmpty) return 0;

    final Set<DateTime> loggedDays = allPayments
        .map((p) => DateTime(p.datetime.year, p.datetime.month, p.datetime.day))
        .toSet();

    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);

    // If nothing logged today, the streak can still be "alive" through
    // yesterday — start counting from there instead.
    if (!loggedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!loggedDays.contains(cursor)) return 0;
    }

    int streak = 0;
    while (loggedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest streak ever achieved, for a small "personal best" nudge.
  static int longestStreak(List<Payment> allPayments) {
    if (allPayments.isEmpty) return 0;

    final sortedDays = allPayments
        .map((p) => DateTime(p.datetime.year, p.datetime.month, p.datetime.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int running = 1;
    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        running++;
        longest = running > longest ? running : longest;
      } else if (diff > 1) {
        running = 1;
      }
    }
    return longest;
  }

  /// Milestones worth celebrating. Returns true only the first time a
  /// streak reaches one of these values (caller is responsible for tracking
  /// which milestones have already been shown, e.g. via SharedPreferences).
  static bool isMilestone(int streak) => const [3, 7, 14, 30, 60, 100, 365].contains(streak);
}
