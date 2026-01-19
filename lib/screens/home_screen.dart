import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import '../models/activity.dart';
import '../services/stats_service.dart';
import '../services/timer_controller.dart';
import '../services/premium_service.dart';
import '../services/custom_activities_service.dart';
import '../services/notification_service.dart';
import '../config/activities_config.dart';
import '../widgets/shared_card_widget.dart';
import '../widgets/bottom_navigation.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/rendering.dart';
import '../painters/grid_background_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;
  bool _showBottomNav = true;
  late TimerController _timerController;
  late StatsService _statsService;

  int _currentPage = 0;
  int _currentTabIndex = 0;
  bool _showDynamicIsland = false;
  bool _showWeeklySummary = true;
  bool _isButtonPressed = false;
  bool _showWelcomeOverlay = true;
  late List<Activity> _activities;
  Map<String, int> _activityStats = {};
  Map<String, List<Map<String, dynamic>>> _activityHistory = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _timerController = TimerController();
    _statsService = StatsService();
    
    _timerController.addListener(() {
      setState(() {});
    });
    
    _loadActivitiesAndStats();
    NotificationService.onNotificationTapped = _openRandomActivityFromNotification;
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Scrolling up - hide bottom nav
      if (_showBottomNav) {
        setState(() => _showBottomNav = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Scrolling down - show bottom nav
      if (!_showBottomNav) {
        setState(() => _showBottomNav = true);
      }
    }
  }

  @override
  void dispose() {
    NotificationService.onNotificationTapped = null;
    _pageController.dispose();
    _scrollController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _loadActivitiesAndStats() async {
    try {
      final activities = await ActivitiesConfig.getAllActivities();
      final stats = await _statsService.loadStats();
      final history = await _statsService.loadHistory();
      
      if (mounted) {
        setState(() {
          _activities = activities;
          _activityStats = stats;
          _activityHistory = history;
        });
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  Future<void> _saveStats() async {
    await _statsService.saveStats(_activityStats, _activityHistory);
  }

  void _startActivity() {
    _timerController.startTimer();
  }

  void _endActivity() {
    final elapsedTime = _timerController.stopTimer();
    final activityName = _activities[_currentPage].title;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final newTotal = (_activityStats[activityName] ?? 0) + elapsedTime;

    if (_activityHistory[activityName] == null) {
      _activityHistory[activityName] = [];
    }
    
    _activityHistory[activityName]!.add({
      'time': elapsedTime,
      'timestamp': timestamp,
    });

    setState(() {
      _activityStats[activityName] = newTotal;
    });

    _saveStats();
  }

  void _openRandomActivityFromNotification() {
    final notificationService = NotificationService();
    final randomIndex = notificationService.getRandomActivityIndex(_activities.length);

    _pageController.jumpToPage(randomIndex);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_timerController.isRunning) {
        _startActivity();
      }
    });
  }

  void _showAddActivityDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade100,
        title: Text(
          'ADD ACTIVITY',
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
                  duration: '',
                );

                final customService = CustomActivitiesService();
                await customService.addActivity(activity);
                await _loadActivitiesAndStats();

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

  Future<void> _handleAddActivityTap() async {
    final premiumService = PremiumService();
    final isPremium = await premiumService.isPremium();

    if (!isPremium) {
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PaywallScreen()),
        );
        if (result == true && mounted) {
          await _loadActivitiesAndStats();
        }
      }
    } else {
      if (mounted) {
        _showAddActivityDialog();
      }
    }
  }

  String _formatTotalTime(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  int _getTodayTime(String activityName) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    int totalSeconds = 0;
    final entries = _activityHistory[activityName] ?? [];
    
    for (var entry in entries) {
      final timestamp = entry['timestamp'] as int;
      final entryDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      if (entryDate.isAfter(todayStart) && entryDate.isBefore(todayEnd)) {
        totalSeconds += entry['time'] as int;
      }
    }
    
    return totalSeconds ~/ 60;
  }

  int _getWeekTime(String activityName) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    int totalSeconds = 0;
    final entries = _activityHistory[activityName] ?? [];
    
    for (var entry in entries) {
      final timestamp = entry['timestamp'] as int;
      final entryDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      if (entryDate.isAfter(weekAgo)) {
        totalSeconds += entry['time'] as int;
      }
    }
    
    return totalSeconds ~/ 60;
  }

  @override
  Widget build(BuildContext context) {
    if (_timerController.isRunning) {
      return _buildTimerScreen();
    }
    
    return Stack(
      children: [
        Scaffold(
          body: _buildCurrentTabContent(),
          bottomNavigationBar: _showBottomNav
              ? BottomTabBar(
                  currentIndex: _currentTabIndex,
                  onTabChange: (index) {
                    if (index == 2) {
                      setState(() => _showDynamicIsland = !_showDynamicIsland);
                    } else {
                      setState(() {
                        _currentTabIndex = index;
                        _showDynamicIsland = false;
                      });
                    }
                  },
                )
              : null,
        ),
        if (_showDynamicIsland)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DynamicIslandMenu(
              onClose: () {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  setState(() => _showDynamicIsland = false);
                });
              },
              onMenuItemTapped: (String item) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  _handleMenuItemTap(item);
                });
              },
            ),
          ),
        if (_showWelcomeOverlay)
          _buildWelcomeOverlay(),
      ],
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildCarouselScreenBody();
      case 1:
        return _buildSummaryScreenBody();
      case 2:
        return _buildCarouselScreenBody();
      default:
        return _buildCarouselScreenBody();
    }
  }

  Widget _buildCarouselScreenBody() {
    if (_activities.isEmpty) {
      return Stack(
        children: [
          _buildDitheredBackground(),
          const Center(
            child: Text('Loading activities...'),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _buildDitheredBackground(),
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 80),
                      // White card directly below
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF2D3B2D),
                            width: 4.0,
                          ),
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF2D3B2D),
                              offset: Offset(10, 10),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          // Carousel with side arrows
                          SizedBox(
                            height: 340,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left arrow
                                SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFF2D3B2D), width: 3),
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          if (_currentPage > 0) {
                                            _pageController.previousPage(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          } else {
                                            _pageController.animateToPage(
                                              _activities.length,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.chevron_left, size: 28, color: const Color(0xFF2D3B2D)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ),
                                // Activity carousel in middle
                                Expanded(
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() => _currentPage = index);
                                    },
                                    itemCount: _activities.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == _activities.length) {
                                        return _buildAddActivityCard();
                                      }
                                      return _buildActivityCard(_activities[index]);
                                    },
                                  ),
                                ),
                                // Right arrow
                                SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFF2D3B2D), width: 3),
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          if (_currentPage < _activities.length) {
                                            _pageController.nextPage(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          } else {
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.chevron_right, size: 28, color: const Color(0xFF2D3B2D)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_currentPage < _activities.length) _buildStartButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryScreenBody() {
    final isWeekly = _showWeeklySummary;
    final stats = isWeekly
        ? _statsService.getWeeklyStats(_activityHistory)
        : _activityStats;
    final totalTime = isWeekly
        ? _statsService.getTotalTime(stats)
        : _statsService.getTotalTime(_activityStats);
    final totalHours = totalTime ~/ 3600;
    final totalMinutes = (totalTime % 3600) ~/ 60;

    return Stack(
      children: [
        _buildDitheredBackground(),
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'YOUR STATS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade900,
                      letterSpacing: 1.5,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF2D3B2D),
                          width: 4.0,
                        ),
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF2D3B2D),
                            offset: Offset(10, 10),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isWeekly ? 'YOUR WEEK OFFLINE' : 'TOTAL TIME AWAY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2D3B2D),
                              letterSpacing: 1.5,
                              fontFamily: 'Courier Prime',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '■ ■ ■',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF2D3B2D),
                              letterSpacing: 8,
                              fontFamily: 'Courier Prime',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() => _showWeeklySummary = true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isWeekly ? const Color(0xFF2D3B2D) : Colors.white,
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(color: const Color(0xFF2D3B2D), width: 4),
                                  ),
                                  child: Text(
                                    'WEEK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isWeekly ? Colors.white : const Color(0xFF2D3B2D),
                                      letterSpacing: 1,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _showWeeklySummary = false);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isWeekly ? const Color(0xFF2D3B2D) : Colors.white,
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(color: const Color(0xFF2D3B2D), width: 4),
                                  ),
                                  child: Text(
                                    'ALL TIME',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: !isWeekly ? Colors.white : const Color(0xFF2D3B2D),
                                      letterSpacing: 1,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC4F2BE),
                              borderRadius: BorderRadius.circular(0),
                              border: Border.all(color: const Color(0xFF2D3B2D), width: 4),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'TOTAL TIME',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D3B2D),
                                    letterSpacing: 2,
                                    fontFamily: 'Courier Prime',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2D3B2D),
                                    letterSpacing: 2,
                                    fontFamily: 'Courier Prime',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D3B2D),
                                    letterSpacing: 2,
                                    fontFamily: 'Courier Prime',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          ...stats.entries.map((entry) {
                            final time = entry.value;
                            if (time == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2D3B2D),
                                        letterSpacing: 1,
                                        fontFamily: 'Courier Prime',
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTotalTime(time).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF2D3B2D),
                                      letterSpacing: 1,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                          Text(
                            'You touched grass!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuItemTap(String item) {
    switch (item) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      default:
        break;
    }
  }

  Widget _buildDitheredBackground() {
    return Container(
      color: Color(0xFFEBEBEB),
      child: CustomPaint(
        painter: GridBackgroundPainter(
          gridColor: Color(0xFFBCBCBC),
          spacing: 30.0,
          strokeWidth: 1.0,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildActivityCarousel() {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemCount: _activities.length + 1,
        itemBuilder: (context, index) {
          if (index == _activities.length) {
            return _buildAddActivityCard();
          }
          return _buildActivityCard(_activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final todayTime = _getTodayTime(activity.title);
    final weekTime = _getWeekTime(activity.title);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title - centered and bigger (KEPT LARGER)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              activity.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2D3B2D),
                letterSpacing: 0.3,
                fontFamily: 'Courier Prime',
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Today time - black label, darker green number (bold)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Today:\u00A0\u00A0\u00A0\u00A0\u00A0',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3B2D),
                    fontFamily: 'Courier Prime',
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: '$todayTime\u00A0m',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5AA85A),
                    fontFamily: 'Courier Prime',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // This Week time - black label, darker green number (bold)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'This\u00A0Week:\u00A0',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3B2D),
                    fontFamily: 'Courier Prime',
                    height: 1.3,
                  ),
                ),
                TextSpan(
                  text: '$weekTime\u00A0m',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5AA85A),
                    fontFamily: 'Courier Prime',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Description - centered
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              activity.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3B2D),
                height: 1.4,
                letterSpacing: 0.3,
                fontFamily: 'Courier Prime',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddActivityCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _handleAddActivityTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade700, width: 3),
            ),
            child: Icon(
              Icons.add,
              size: 48,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ADD CUSTOM\nACTIVITY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade800,
            letterSpacing: 1.5,
            fontFamily: 'Courier',
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavigationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          _activities.length + 2,
          (index) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                _currentPage == index ? '✦' : '✧',
                style: TextStyle(
                  fontSize: _currentPage == index ? 12 : 9,
                  color: _currentPage == index
                      ? Colors.grey.shade800
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) {
          setState(() => _isButtonPressed = false);
          _startActivity();
        },
        onTapCancel: () => setState(() => _isButtonPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 14),
          transform: Matrix4.translationValues(
            _isButtonPressed ? 4 : 0,
            _isButtonPressed ? 4 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFC4F2BE),
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: const Color(0xFF2D3B2D), width: 4),
            boxShadow: _isButtonPressed
                ? []
                : [
                    const BoxShadow(
                      color: Color(0xFF2D3B2D),
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            "START NOW",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontFamily: 'Courier Prime',
              color: const Color(0xFF2D3B2D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerScreen() {
    return Scaffold(
      body: Stack(
        children: [
          _buildDitheredBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF2D3B2D),
                      width: 4.0,
                    ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2D3B2D),
                        offset: Offset(10, 10),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activities[_currentPage].title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3B2D),
                          letterSpacing: 1,
                          fontFamily: 'Courier Prime',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4F2BE),
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(color: const Color(0xFF2D3B2D), width: 4),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TIME SPENT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D3B2D),
                                letterSpacing: 2,
                                fontFamily: 'Courier Prime',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _timerController.formatTime(_timerController.elapsed),
                                style: TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade700,
                                  letterSpacing: 2,
                                  fontFamily: 'Courier',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _endActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            foregroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "I'M DONE",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    final isWeekly = _showWeeklySummary;
    final stats = isWeekly
        ? _statsService.getWeeklyStats(_activityHistory)
        : _activityStats;
    final totalTime = isWeekly
        ? _statsService.getTotalTime(stats)
        : _statsService.getTotalTime(_activityStats);
    final totalHours = totalTime ~/ 3600;
    final totalMinutes = (totalTime % 3600) ~/ 60;

    return Scaffold(
      body: Stack(
        children: [
          _buildDitheredBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'YOUR STATS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade900,
                      letterSpacing: 1.5,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SharedCardWidget(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isWeekly ? 'YOUR WEEK OFFLINE' : 'TOTAL TIME AWAY',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade900,
                                letterSpacing: 1.5,
                                fontFamily: 'Courier',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '✦ ✧ ✦',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showWeeklySummary = true);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isWeekly ? Colors.grey.shade700 : Colors.grey.shade300,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border.all(color: Colors.grey.shade800, width: 2),
                                    ),
                                    child: Text(
                                      'WEEK',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: isWeekly ? Colors.grey.shade100 : Colors.grey.shade700,
                                        letterSpacing: 1,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _showWeeklySummary = false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !isWeekly ? Colors.grey.shade700 : Colors.grey.shade300,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      border: Border.all(color: Colors.grey.shade800, width: 2),
                                    ),
                                    child: Text(
                                      'ALL TIME',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: !isWeekly ? Colors.grey.shade100 : Colors.grey.shade700,
                                        letterSpacing: 1,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade900, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'TOTAL TIME',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey.shade100,
                                      letterSpacing: 2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'OFFLINE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 2,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...stats.entries.map((entry) {
                              final time = entry.value;
                              if (time == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade800,
                                          letterSpacing: 1,
                                          fontFamily: 'Courier',
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTotalTime(time).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 1,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 32),
                            Text(
                              'You touched grass!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCard() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title - reduced visual dominance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'DID U TOUCH GRASS?',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
                fontFamily: 'Courier',
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Description
          Text(
            'Choose offline activity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start timer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Put phone down',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
              child: SelectionContainer.disabled(
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF2D3B2D),
                      width: 4.0,
                    ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2D3B2D),
                        offset: Offset(10, 10),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button at top right
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showWelcomeOverlay = false);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2D3B2D), width: 2),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: const Color(0xFF2D3B2D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title below X button
                      Text(
                        'DID U TOUCH GRASS?',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D3B2D),
                          letterSpacing: -0.5,
                          fontFamily: 'Courier Prime',
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Instructions
                      _buildInstructionItem('1', 'Choose offline activity'),
                      const SizedBox(height: 28),
                      _buildInstructionItem('2', 'Start timer'),
                      const SizedBox(height: 28),
                      _buildInstructionItem('3', 'Put phone down'),
                      const SizedBox(height: 48),
                      // Bottom decoration
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3B2D),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3B2D),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2D3B2D), width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Courier Prime',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3B2D),
                letterSpacing: 0.3,
                fontFamily: 'Courier Prime',
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SubtleNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint();
    
    // Create TV static-like noise with larger pixels
    final pixelSize = 2.0;
    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        // 25% chance of a pixel
        if (random.nextDouble() < 0.25) {
          final isLight = random.nextBool();
          final opacity = isLight ? 0.15 : 0.22;
          final color = Colors.grey.shade800;
          
          canvas.drawRect(
            Rect.fromLTWH(x, y, pixelSize, pixelSize),
            paint..color = color.withOpacity(opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(SubtleNoisePainter oldDelegate) => false;
}