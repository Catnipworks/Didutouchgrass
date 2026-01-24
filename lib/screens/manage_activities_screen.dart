import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/activity.dart';
import '../services/custom_activities_service.dart';
import '../services/premium_service.dart';
import 'paywall_screen.dart';

class ManageActivitiesScreen extends StatefulWidget {
  const ManageActivitiesScreen({super.key});

  @override
  State<ManageActivitiesScreen> createState() => _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState extends State<ManageActivitiesScreen> {
  final CustomActivitiesService _customService = CustomActivitiesService();
  final PremiumService _premiumService = PremiumService();
  List<Activity> _customActivities = [];
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isPremium = await _premiumService.isPremium();
    final activities = await _customService.loadCustomActivities();
    setState(() {
      _isPremium = isPremium;
      _customActivities = activities;
    });
  }

  Future<void> _checkPremiumAndAdd() async {
    if (!_isPremium) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaywallScreen()),
      );
      if (result == true) {
        await _loadData();
        if (_isPremium) {
          _showAddActivityDialog();
        }
      }
    } else {
      _showAddActivityDialog();
    }
  }

  void _showAddActivityDialog({Activity? existingActivity, int? index}) {
    final titleController = TextEditingController(
      text: existingActivity?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingActivity?.description ?? '',
    );
    final durationController = TextEditingController(
      text: existingActivity?.duration ?? '10 min',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade100,
        title: Text(
          existingActivity == null ? 'ADD ACTIVITY' : 'EDIT ACTIVITY',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
            color: Colors.grey.shade900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration (e.g., 15 min)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descController.text.isNotEmpty) {
                final activity = Activity(
                  title: titleController.text,
                  description: descController.text,
                  duration: durationController.text,
                );

                if (existingActivity == null) {
                  await _customService.addActivity(activity);
                } else if (index != null) {
                  await _customService.updateActivity(index, activity);
                }

                await _loadData();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.grey.shade100,
            ),
            child: Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDitheredBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade300, Colors.grey.shade500],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(painter: SubtleNoisePainter()),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildDitheredBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context, true),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'CUSTOM ACTIVITIES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey.shade900,
                            letterSpacing: 1.5,
                            fontFamily: 'Courier',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _customActivities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No custom activities yet.\nTap + to add one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontFamily: 'Courier',
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _customActivities.length,
                          itemBuilder: (context, index) {
                            final activity = _customActivities[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade800,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  activity.title.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                subtitle: Text(
                                  activity.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                      onPressed: () => _showAddActivityDialog(
                                        existingActivity: activity,
                                        index: index,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                      onPressed: () async {
                                        await _customService.deleteActivity(
                                          index,
                                        );
                                        await _loadData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkPremiumAndAdd,
        backgroundColor: Colors.grey.shade700,
        foregroundColor: Colors.grey.shade100,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Subtle noise painter - zine-like texture overlay
class SubtleNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Create subtle noise pattern with small dots
    final dotSize = 2.0;
    final spacing = 6.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final isBlack = random.nextBool();
        final color = isBlack ? Colors.black : Colors.white;
        final opacity = isBlack ? 0.25 : 0.15;
        
        final paint = Paint()..color = color.withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SubtleNoisePainter oldDelegate) => false;
}
