import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity.dart';

class CustomActivitiesService {
  static const String _customActivitiesKey = 'custom_activities';
  static const String _activityOrderKey = 'activity_order';
  static const String _removedActivitiesKey = 'removed_activities';

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

  // Get stored activity order (list of titles)
  Future<List<String>> getActivityOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = prefs.getString(_activityOrderKey);
      if (orderJson != null) {
        final List<dynamic> decoded = json.decode(orderJson);
        return decoded.cast<String>();
      }
    } catch (e) {
      print('Error loading activity order: $e');
    }
    return [];
  }

  // Save activity order
  Future<void> setActivityOrder(List<String> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activityOrderKey, json.encode(order));
    } catch (e) {
      print('Error saving activity order: $e');
    }
  }

  // Get removed activity titles
  Future<List<String>> getRemovedActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removedJson = prefs.getString(_removedActivitiesKey);
      if (removedJson != null) {
        final List<dynamic> decoded = json.decode(removedJson);
        return decoded.cast<String>();
      }
    } catch (e) {
      print('Error loading removed activities: $e');
    }
    return [];
  }

  // Save removed activities
  Future<void> setRemovedActivities(List<String> removed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_removedActivitiesKey, json.encode(removed));
    } catch (e) {
      print('Error saving removed activities: $e');
    }
  }

  // Remove an activity by title
  Future<void> removeActivityByTitle(String title) async {
    final removed = await getRemovedActivities();
    if (!removed.contains(title)) {
      removed.add(title);
      await setRemovedActivities(removed);
    }
  }

  // Restore a removed activity
  Future<void> restoreActivity(String title) async {
    final removed = await getRemovedActivities();
    removed.remove(title);
    await setRemovedActivities(removed);
  }
}
