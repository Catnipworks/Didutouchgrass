import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatsService {
  static const String _statsKey = 'activity_stats';
  static const String _historyKey = 'activity_history';

  // Load all-time stats
  Future<Map<String, int>> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        final decoded = json.decode(statsJson);
        return Map<String, int>.from(decoded);
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
    return {};
  }

  // Load activity history
  Future<Map<String, List<Map<String, dynamic>>>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final decoded = json.decode(historyJson) as Map<String, dynamic>;
        return decoded.map(
          (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
        );
      }
    } catch (e) {
      print('Error loading history: $e');
    }
    return {};
  }

  // Save stats and history
  Future<void> saveStats(
    Map<String, int> stats,
    Map<String, List<Map<String, dynamic>>> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, json.encode(stats));
      await prefs.setString(_historyKey, json.encode(history));
      print('Stats saved: $stats');
    } catch (e) {
      print('Error saving stats: $e');
    }
  }

  // Get weekly stats (last 7 days)
  Map<String, int> getWeeklyStats(
    Map<String, List<Map<String, dynamic>>> history,
  ) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyStats = <String, int>{};

    history.forEach((activityName, entries) {
      int weekTotal = 0;
      for (var entry in entries) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          entry['timestamp'],
        );
        if (timestamp.isAfter(weekAgo)) {
          weekTotal += entry['time'] as int;
        }
      }
      if (weekTotal > 0) {
        weeklyStats[activityName] = weekTotal;
      }
    });

    return weeklyStats;
  }

  // Get total time from stats
  int getTotalTime(Map<String, int> stats) {
    return stats.values.fold(0, (sum, time) => sum + time);
  }
}
