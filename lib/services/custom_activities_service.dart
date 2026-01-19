import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity.dart';

class CustomActivitiesService {
  static const String _customActivitiesKey = 'custom_activities';

  // Load custom activities
  Future<List<Activity>> loadCustomActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString(_customActivitiesKey);
      if (customJson != null) {
        final List<dynamic> decoded = json.decode(customJson);
        return decoded
            .map(
              (item) => Activity(
                title: item['title'],
                description: item['description'],
                duration: item['duration'],
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Error loading custom activities: $e');
    }
    return [];
  }

  // Save custom activities
  Future<void> saveCustomActivities(List<Activity> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJson = json.encode(
        activities
            .map(
              (a) => {
                'title': a.title,
                'description': a.description,
                'duration': a.duration,
              },
            )
            .toList(),
      );
      await prefs.setString(_customActivitiesKey, customJson);
      print('Custom activities saved');
    } catch (e) {
      print('Error saving custom activities: $e');
    }
  }

  // Add a custom activity
  Future<void> addActivity(Activity activity) async {
    final activities = await loadCustomActivities();
    activities.add(activity);
    await saveCustomActivities(activities);
  }

  // Delete a custom activity
  Future<void> deleteActivity(int index) async {
    final activities = await loadCustomActivities();
    if (index >= 0 && index < activities.length) {
      activities.removeAt(index);
      await saveCustomActivities(activities);
    }
  }

  // Update a custom activity
  Future<void> updateActivity(int index, Activity activity) async {
    final activities = await loadCustomActivities();
    if (index >= 0 && index < activities.length) {
      activities[index] = activity;
      await saveCustomActivities(activities);
    }
  }
}
