import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/activity.dart';
import '../services/stats_service.dart';
import '../services/timer_controller.dart';
import '../services/premium_service.dart';
import '../services/custom_activities_service.dart';
import '../services/notification_service.dart';
import '../config/activities_config.dart';
import '../widgets/bottom_navigation.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/rendering.dart';
import 'themes_screen.dart';
import 'custom_activities_screen.dart';
import 'about_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  late ScrollController _scrollController;
  bool _showBottomNav = true;
  late TimerController _timerController;
  late StatsService _statsService;

  int _currentPage = 0;
  int _currentTabIndex = 1;
  bool _showDynamicIsland = false;
  bool _showWeeklySummary = true;
  bool _isButtonPressed = false;
  bool _isDoneButtonPressed = false;
  bool _showWelcomeOverlay = true;
  double _welcomeOpacity = 1.0;
  bool _showReturnReminder = false;
  double _reminderOpacity = 1.0;
  bool _wasInBackground = false;
  List<Activity> _activities = [];
  Map<String, int> _activityStats = {};
  Map<String, List<Map<String, dynamic>>> _activityHistory = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start at a high page number to allow infinite scrolling in both directions
    // Use a multiple of 9 (8 default activities + 1 add card) so Reach Out shows first
    _pageController = PageController(initialPage: 9999);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App is going to background
      if (_timerController.isRunning) {
        _wasInBackground = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground
      if (_wasInBackground && _timerController.isRunning) {
        setState(() {
          _reminderOpacity = 1.0;
          _showReturnReminder = true;
        });
        _wasInBackground = false;
      }
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
        final isFirstLoad = _activities.isEmpty;
        setState(() {
          _activities = activities;
          _activityStats = stats;
          _activityHistory = history;
        });

        // On first load, jump to a page aligned to index 0 (first activity)
        if (isFirstLoad && activities.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              final totalPages = activities.length + 1;
              final startPage = (9999 ~/ totalPages) * totalPages;
              _pageController.jumpToPage(startPage);
              setState(() => _currentPage = 0);
            }
          });
        }
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
      _showReturnReminder = false;
      _wasInBackground = false;
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
            fontFamily: 'Courier Prime',
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
                  fontFamily: 'Courier Prime',
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
                  fontFamily: 'Courier Prime',
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
                fontFamily: 'Courier Prime',
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

                // Jump to the newly added activity
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _pageController.hasClients) {
                    final newIndex = _activities.indexWhere((a) => a.title == activity.title);
                    if (newIndex >= 0) {
                      final totalPages = _activities.length + 1;
                      final basePage = (_pageController.page!.round() ~/ totalPages) * totalPages;
                      _pageController.jumpToPage(basePage + newIndex);
                      setState(() => _currentPage = newIndex);
                    }
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.grey.shade100,
            ),
            child: Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'Courier Prime',
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
    if (mins == 0 && seconds > 0) {
      return '<1m';
    }
    return '${mins}m';
  }

  String _formatActivityNameForStats(String activityName) {
    // Map of activity names to their stats display versions
    final Map<String, String> nameMap = {
      'Sit in Silence': 'SAT IN SILENCE',
      'Create Something': 'CREATED SOMETHING',
      'Reach Out': 'REACHED OUT',
      'Any Movement Counts': 'MOVED',
      'Touch Grass': 'TOUCHED GRASS',
      'Turn a Few Pages': 'TURNED A FEW PAGES',
      'Tend Your Space': 'TENDED YOUR SPACE',
    };
    
    // Return mapped name or default uppercase
    return nameMap[activityName] ?? activityName.toUpperCase();
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
    
    return totalSeconds;
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

    return totalSeconds;
  }

  String _formatMinutes(int seconds) {
    final mins = seconds ~/ 60;
    if (mins == 0 && seconds > 0) {
      return '<1';
    }
    return '$mins';
  }

  Duration _animDuration(int ms) {
    return MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : Duration(milliseconds: ms);
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
        bottomNavigationBar: AnimatedSlide(
            duration: _animDuration(200),
            curve: Curves.easeOut,
            offset: _showBottomNav ? Offset.zero : const Offset(0, 1),
            child: BottomTabBar(
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
              ),
            ),
      ),
      if (_showDynamicIsland)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            duration: _animDuration(300),
            curve: Curves.easeOut,
            offset: _showDynamicIsland ? Offset.zero : const Offset(0, 1),
            child: DynamicIslandMenu(
              onClose: () {
                setState(() => _showDynamicIsland = false);
              },
              onMenuItemTapped: (String item) {
                _handleMenuItemTap(item);
                setState(() => _showDynamicIsland = false);
              },
            ),
          ),
        ),
      if (_showWelcomeOverlay)
        AnimatedOpacity(
          duration: _animDuration(200),
          opacity: _welcomeOpacity,
          child: _buildWelcomeOverlay(),
        ),
    ],
  );
}

  Widget _buildCurrentTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildSummaryScreenBody(); // Stats tab
      case 1:
        return _buildCarouselScreenBody(); // Activities tab
      case 2:
        return _buildCarouselScreenBody(); // More opens menu, but show carousel as fallback
      default:
        return _buildCarouselScreenBody();
    }
  }

  Widget _buildCarouselScreenBody() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

  if (_activities.isEmpty) {
      return Stack(
        children: [
          _buildDitheredBackground(),
          Center(
            child: Text('Loading activities...', style: TextStyle(color: theme.textColor)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 80),
                      // Main card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(
                            color: theme.borderColor,
                            width: 3.0,
                          ),
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: [
                            BoxShadow(
                              color: theme.borderColor,
                              offset: const Offset(10, 10),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 48),
                          // Carousel with side arrows
                          SizedBox(
                            height: 400,
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
                                        color: theme.cardColor,
                                        border: Border.all(color: theme.borderColor, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        icon: Icon(Icons.chevron_left, size: 28, color: theme.textColor),
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
                                      final totalPages = _activities.length + 1;
                                      setState(() => _currentPage = index % totalPages);
                                    },
                                    itemBuilder: (context, index) {
                                      final totalPages = _activities.length + 1;
                                      final actualIndex = index % totalPages;
                                      if (actualIndex == _activities.length) {
                                        return _buildAddActivityCard();
                                      }
                                      return _buildActivityCard(_activities[actualIndex]);
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
                                        color: theme.cardColor,
                                        border: Border.all(color: theme.borderColor, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        icon: Icon(Icons.chevron_right, size: 28, color: theme.textColor),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
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
          child: Center(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(
                          color: theme.borderColor,
                          width: 3.0,
                        ),
                        borderRadius: BorderRadius.circular(0),
                        boxShadow: [
                          BoxShadow(
                            color: theme.borderColor,
                            offset: const Offset(10, 10),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'OFFLINE TIME',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: theme.textColor,
                              letterSpacing: 1,
                              fontFamily: 'DotGothic16',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                                    color: isWeekly ? theme.borderColor : theme.cardColor,
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(color: theme.borderColor, width: 3),
                                  ),
                                  child: Text(
                                    'WEEK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isWeekly ? theme.accentColor : theme.textColor,
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
                                    color: !isWeekly ? theme.borderColor : theme.cardColor,
                                    borderRadius: BorderRadius.circular(0),
                                    border: Border.all(color: theme.borderColor, width: 3),
                                  ),
                                  child: Text(
                                    'ALL TIME',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: !isWeekly ? theme.accentColor : theme.textColor,
                                      letterSpacing: 1,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              borderRadius: BorderRadius.circular(0),
                              border: Border.all(color: theme.borderColor, width: 3),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'TOTAL TIME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: theme.borderColor.withValues(alpha: 0.7),
                                    letterSpacing: 2,
                                    fontFamily: 'Courier Prime',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w400,
                                    color: theme.borderColor,
                                    letterSpacing: 4,
                                    fontFamily: 'DotGothic16',
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
                                      _formatActivityNameForStats(entry.key),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textColor,
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
                                      color: theme.textColor,
                                      letterSpacing: 1,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
  }

  void _handleMenuItemTap(String item) async {
  switch (item) {
    case 'notifications':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      // Re-show menu when returning
      if (mounted) setState(() => _showDynamicIsland = true);
      break;
    case 'add_edit_activities':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomActivitiesScreen()),
      );
      // Reload activities and re-show menu when returning
      await _loadActivitiesAndStats();
      if (mounted) setState(() => _showDynamicIsland = true);
      break;
    case 'themes':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ThemesScreen()),
      );
      // Re-show menu when returning
      if (mounted) setState(() => _showDynamicIsland = true);
      break;
    case 'share':
      final screenSize = MediaQuery.of(context).size;
      await Share.share(
        "Did U Touch Grass? Sending this as a friend: put the phone down for ten minutes. I'm currently upping my stats in the real world—go look at a tree or something and join me.\n\nhttps://didutouchgrass.com",
        subject: 'Did U Touch Grass?',
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 100,
          height: 100,
        ),
      );
      break;
    case 'about':
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AboutScreen()),
      );
      // Re-show menu when returning
      if (mounted) setState(() => _showDynamicIsland = true);
      break;
    default:
      break;
  }
}

  Widget _buildDitheredBackground() {
  final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
  return Container(
    color: theme.backgroundColor,
  );
}

  Widget _buildActivityCard(Activity activity) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final todayTime = _getTodayTime(activity.title);
    final weekTime = _getWeekTime(activity.title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title - centered and bigger
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              activity.title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: theme.textColor,
                letterSpacing: 0.5,
                fontFamily: 'DotGothic16',
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Today time
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Today:\u00A0\u00A0\u00A0\u00A0\u00A0',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      fontFamily: 'Courier Prime',
                      height: 1.3,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatMinutes(todayTime)}\u00A0m',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: theme.textColor,
                      fontFamily: 'Courier Prime',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // This Week time
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'This\u00A0Week:\u00A0',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      fontFamily: 'Courier Prime',
                      height: 1.3,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatMinutes(weekTime)}\u00A0m',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: theme.textColor,
                      fontFamily: 'Courier Prime',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Description - centered
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                activity.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: theme.textColor,
                  height: 1.4,
                  letterSpacing: 0.3,
                  fontFamily: 'Courier Prime',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddActivityCard() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _handleAddActivityTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.borderColor, width: 3),
            ),
            child: Icon(
              Icons.add,
              size: 48,
              color: theme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ADD CUSTOM\nACTIVITY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: theme.textColor,
            letterSpacing: 1.5,
            fontFamily: 'Courier Prime',
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) {
          setState(() => _isButtonPressed = false);
          _startActivity();
        },
        onTapCancel: () => setState(() => _isButtonPressed = false),
        child: AnimatedContainer(
          duration: _animDuration(100),
          curve: Curves.easeOut,
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          transform: Matrix4.translationValues(
            _isButtonPressed ? 4 : 0,
            _isButtonPressed ? 4 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: theme.accentColor,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: theme.borderColor, width: 2),
            boxShadow: _isButtonPressed
                ? []
                : [
                    BoxShadow(
                      color: theme.borderColor,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            "START NOW",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontFamily: 'Courier Prime',
              color: theme.borderColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isDoneButtonPressed = true),
      onTapUp: (_) {
        setState(() => _isDoneButtonPressed = false);
        _endActivity();
      },
      onTapCancel: () => setState(() => _isDoneButtonPressed = false),
      child: AnimatedContainer(
        duration: _animDuration(100),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        transform: Matrix4.translationValues(
          _isDoneButtonPressed ? 4 : 0,
          _isDoneButtonPressed ? 4 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: theme.borderColor, width: 3),
          boxShadow: _isDoneButtonPressed
              ? []
              : [
                  BoxShadow(
                    color: theme.borderColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          "I'M DONE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'Courier Prime',
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerScreen() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      body: Stack(
        children: [
          _buildDitheredBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(
                      color: theme.borderColor,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: [
                      BoxShadow(
                        color: theme.borderColor,
                        offset: const Offset(10, 10),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showReturnReminder) ...[
                        AnimatedOpacity(
                          duration: _animDuration(200),
                          opacity: _reminderOpacity,
                          child: GestureDetector(
                          onTap: () {
                            setState(() => _reminderOpacity = 0.0);
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (mounted) setState(() => _showReturnReminder = false);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              border: Border.all(color: theme.borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Are you still touching grass?",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.borderColor,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.close,
                                  size: 16,
                                  color: theme.borderColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ],
                      Text(
                        _activities[_currentPage].title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                          letterSpacing: 1,
                          fontFamily: 'DotGothic16',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(color: theme.borderColor, width: 3),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TIME SPENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.borderColor.withValues(alpha: 0.7),
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
                                  fontSize: 56,
                                  fontWeight: FontWeight.w400,
                                  color: theme.borderColor,
                                  letterSpacing: 4,
                                  fontFamily: 'DotGothic16',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildDoneButton(),
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

  Widget _buildWelcomeOverlay() {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 48.0),
              child: SelectionContainer.disabled(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28.0, 20.0, 28.0, 36.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(
                      color: theme.borderColor,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: [
                      BoxShadow(
                        color: theme.borderColor,
                        offset: const Offset(8, 8),
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
                            setState(() => _welcomeOpacity = 0.0);
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (mounted) setState(() => _showWelcomeOverlay = false);
                            });
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.borderColor, width: 2),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title below X button
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'DID U TOUCH GRASS?',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: theme.textColor,
                            letterSpacing: -0.5,
                            fontFamily: 'DotGothic16',
                            height: 1.0,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Instructions - left aligned with polish
                      _buildInstructionItemPolished('1', 'Choose offline activity'),
                      const SizedBox(height: 20),
                      _buildInstructionItemPolished('2', 'Start timer'),
                      const SizedBox(height: 20),
                      _buildInstructionItemPolished('3', 'Put phone down'),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Note: This is a scroll-stopper, not a life-tracker. Get in, get out, go touch grass.',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: theme.textColor.withValues(alpha: 0.6),
                            fontFamily: 'Courier Prime',
                            height: 1.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
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


  Widget _buildInstructionItemPolished(String number, String text) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.borderColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.cardColor,
                fontFamily: 'Courier Prime',
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
              fontFamily: 'Courier Prime',
              decoration: TextDecoration.none,
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
            paint..color = color.withValues(alpha: opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(SubtleNoisePainter oldDelegate) => false;
}