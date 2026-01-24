import '../models/activity.dart';
import '../services/custom_activities_service.dart';

class ActivitiesConfig {
  static List<Activity> getDefaultActivities() {
    return [
      Activity(
        title: 'Reach Out',
        description:
            'Call a friend or family member.\nTry to listen without distractions.',
        duration: '20 min',
      ),
      Activity(
        title: 'Turn a Few Pages',
        description:
            'Pick up a book, magazine, or article. No rush. Just read.',
        duration: '30 min',
      ),
      Activity(
        title: 'Any Movement Counts',
        description:
            'Notice what your body is asking for and stretch, walk, or sway.',
        duration: '10 min',
      ),
      Activity(
        title: 'Create Something',
        description: 'Scribble, write, cook, build. No goal needed- just start.',
        duration: '45 min',
      ),
      Activity(
        title: 'Sit in Silence',
        description:
            'Find a comfortable spot. Breathe. Let the world pass.',
        duration: '10 min',
      ),
      Activity(
        title: 'Touch Grass',
        description:
            'Step outside if you can. Feel grass, soil, a leaf, or just notice the sun on your face.',
        duration: '5 min',
      ),
      Activity(
        title: 'Tend Your Space',
        description:
            'Organize something, wash dishes, arrange what you can reach. Shape your environment.',
        duration: '20 min',
      ),
      Activity(
        title: 'Screen Free w/ Friends',
        description:
            'Get together IRL, press start simultaneously, and see how long you can stay screen-free.',
        duration: '',
      ),
    ];
  }

  // Get all activities respecting user's custom order and removed list
  static Future<List<Activity>> getAllActivities() async {
    final customService = CustomActivitiesService();
    final defaultActivities = getDefaultActivities();
    final customActivities = await customService.loadCustomActivities();
    final storedOrder = await customService.getActivityOrder();
    final removedActivities = await customService.getRemovedActivities();

    // Build a map of all available activities by title
    final allActivities = <String, Activity>{};
    for (final a in defaultActivities) {
      allActivities[a.title] = a;
    }
    for (final a in customActivities) {
      allActivities[a.title] = a;
    }

    // If no custom order set, use default behavior
    if (storedOrder.isEmpty) {
      final result = [...defaultActivities, ...customActivities];
      return result.where((a) => !removedActivities.contains(a.title)).toList();
    }

    // Build ordered list from stored order
    final orderedList = <Activity>[];
    for (final title in storedOrder) {
      if (allActivities.containsKey(title) && !removedActivities.contains(title)) {
        orderedList.add(allActivities[title]!);
      }
    }

    // Append any new activities not yet in stored order
    for (final a in allActivities.values) {
      if (!storedOrder.contains(a.title) && !removedActivities.contains(a.title)) {
        orderedList.add(a);
      }
    }

    return orderedList;
  }
}