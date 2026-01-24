import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/premium_service.dart';
import '../services/custom_activities_service.dart';
import '../config/activities_config.dart';
import '../providers/theme_provider.dart';
import 'paywall_screen.dart';

class CustomActivitiesScreen extends StatefulWidget {
  const CustomActivitiesScreen({super.key});

  @override
  State<CustomActivitiesScreen> createState() => _CustomActivitiesScreenState();
}

class _CustomActivitiesScreenState extends State<CustomActivitiesScreen> {
  final PremiumService _premiumService = PremiumService();
  final CustomActivitiesService _customActivitiesService = CustomActivitiesService();
  List<Activity> _activities = [];
  List<Activity> _removedActivities = [];
  Set<String> _defaultTitles = {};
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _defaultTitles = ActivitiesConfig.getDefaultActivities().map((a) => a.title).toSet();
    _loadData();
  }

  Future<void> _loadData() async {
    final isPremium = await _premiumService.isPremium();
    final activities = await ActivitiesConfig.getAllActivities();
    final removedTitles = await _customActivitiesService.getRemovedActivities();

    // Build removed activities list from defaults + custom
    final allDefaults = ActivitiesConfig.getDefaultActivities();
    final allCustom = await _customActivitiesService.loadCustomActivities();
    final allMap = <String, Activity>{};
    for (final a in allDefaults) {
      allMap[a.title] = a;
    }
    for (final a in allCustom) {
      allMap[a.title] = a;
    }
    final removedActivities = removedTitles
        .where((t) => allMap.containsKey(t))
        .map((t) => allMap[t]!)
        .toList();

    setState(() {
      _isPremium = isPremium;
      _activities = activities;
      _removedActivities = removedActivities;
    });
  }

  Future<void> _saveOrder() async {
    final order = _activities.map((a) => a.title).toList();
    await _customActivitiesService.setActivityOrder(order);
  }

  Future<void> _removeActivity(Activity activity) async {
    if (_defaultTitles.contains(activity.title) && !_isPremium) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      );
      if (result == true) {
        await _loadData();
      }
      return;
    }

    if (!_defaultTitles.contains(activity.title)) {
      // Custom activity: delete entirely
      final customActivities = await _customActivitiesService.loadCustomActivities();
      final index = customActivities.indexWhere((a) => a.title == activity.title);
      if (index >= 0) {
        await _customActivitiesService.deleteActivity(index);
      }
    } else {
      // Default activity: add to removed list (can be restored later)
      await _customActivitiesService.removeActivityByTitle(activity.title);
    }

    await _saveOrder();
    await _loadData();
  }

  Future<void> _restoreActivity(String title) async {
    await _customActivitiesService.restoreActivity(title);
    await _loadData();
    await _saveOrder();
  }

  void _showAddActivityDialog() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.borderColor, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD ACTIVITY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  fontFamily: 'DotGothic16',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Activity Name',
                  labelStyle: TextStyle(
                    fontFamily: 'Courier Prime',
                    color: theme.textColor.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                ),
                style: TextStyle(fontFamily: 'Courier Prime', color: theme.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    fontFamily: 'Courier Prime',
                    color: theme.textColor.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: theme.borderColor, width: 2),
                  ),
                ),
                style: TextStyle(fontFamily: 'Courier Prime', color: theme.textColor),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'Courier Prime',
                        fontWeight: FontWeight.w600,
                        color: theme.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      if (titleController.text.isNotEmpty) {
                        final activity = Activity(
                          title: titleController.text,
                          description: descriptionController.text.isEmpty
                              ? 'Custom activity'
                              : descriptionController.text,
                          duration: '',
                        );
                        await _customActivitiesService.addActivity(activity);
                        if (context.mounted) Navigator.pop(context);
                        await _loadData();
                        await _saveOrder();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        border: Border.all(color: theme.borderColor, width: 2),
                      ),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          fontFamily: 'Courier Prime',
                          fontWeight: FontWeight.w900,
                          color: theme.borderColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(color: theme.borderColor, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: theme.textColor,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ADD/EDIT ACTIVITIES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.textColor,
                        fontFamily: 'Courier Prime',
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Activity list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Reorderable list
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: _activities.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _activities.removeAt(oldIndex);
                            _activities.insert(newIndex, item);
                          });
                          _saveOrder();
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            elevation: 0,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          final isDefault = _defaultTitles.contains(activity.title);
                          return _buildActivityRow(activity, isDefault, index);
                        },
                      ),
                    ),
                    // Add button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap: () async {
                          if (!_isPremium) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaywallScreen()),
                            );
                            if (result == true) {
                              await _loadData();
                            }
                            return;
                          }
                          _showAddActivityDialog();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            border: Border.all(color: theme.borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.borderColor,
                                offset: const Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'ADD NEW ACTIVITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: theme.borderColor,
                              fontFamily: 'Courier Prime',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Removed defaults section
                    if (_removedActivities.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Text(
                          'REMOVED DEFAULTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor.withValues(alpha: 0.7),
                            fontFamily: 'Courier Prime',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ..._removedActivities.map((activity) => _buildRemovedRow(activity)),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(Activity activity, bool isDefault, int index) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      key: ValueKey(activity.title),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor, width: 2),
      ),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Icon(
                Icons.drag_handle,
                color: theme.textColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ),
          // Activity title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                activity.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontFamily: 'Courier Prime',
                ),
              ),
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: () => _removeActivity(activity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Icon(
                Icons.close,
                color: theme.textColor.withValues(alpha: 0.4),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemovedRow(Activity activity) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activity.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textColor.withValues(alpha: 0.6),
                fontFamily: 'Courier Prime',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _restoreActivity(activity.title),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                'RESTORE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor.withValues(alpha: 0.8),
                  fontFamily: 'Courier Prime',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
