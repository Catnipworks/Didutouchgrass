import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String _frequency = 'once_daily'; // 'once_daily', 'weekdays', 'random'

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scheduleDefaultIfNeeded();
  }

  Future<void> _scheduleDefaultIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // If notifications are enabled but never scheduled, schedule now
    if (!prefs.containsKey('notifications_scheduled')) {
      if (_notificationsEnabled) {
        await _notificationService.scheduleReminder(_selectedTime, _frequency);
        await prefs.setBool('notifications_scheduled', true);
      }
    }
  }

  Future<void> _loadSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final time = await _notificationService.getReminderTime();
    final frequency = await _notificationService.getFrequency();

    setState(() {
      _notificationsEnabled = enabled;
      _selectedTime = time;
      _frequency = frequency;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _notificationService.setNotificationsEnabled(value);

    if (value) {
      await _notificationService.scheduleReminder(_selectedTime, _frequency);
    } else {
      await _notificationService.cancelReminder();
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
      await _notificationService.setReminderTime(time);

      if (_notificationsEnabled) {
        await _notificationService.scheduleReminder(time, _frequency);
      }
    }
  }

  Future<void> _setFrequency(String newFrequency) async {
    setState(() => _frequency = newFrequency);
    await _notificationService.setFrequency(newFrequency);

    if (_notificationsEnabled) {
      await _notificationService.scheduleReminder(_selectedTime, newFrequency);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(color: theme.backgroundColor),
          SafeArea(
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
                      const Spacer(),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
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
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Section Title
                              Text(
                                'REMINDERS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: theme.textColor,
                                  letterSpacing: 1.5,
                                  fontFamily: 'Courier Prime',
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Enable/Disable Toggle
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Enable Reminders',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                      fontFamily: 'Courier Prime',
                                    ),
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    onChanged: _toggleNotifications,
                                    activeThumbColor: theme.accentColor,
                                    activeTrackColor: theme.borderColor,
                                    inactiveThumbColor: theme.textColor.withValues(alpha: 0.4),
                                    inactiveTrackColor: theme.textColor.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),

                              // Expandable section
                              if (_notificationsEnabled) ...[
                                const SizedBox(height: 32),

                                // Divider
                                Container(
                                  height: 2,
                                  color: theme.borderColor,
                                ),

                                const SizedBox(height: 32),

                                // Time Picker
                                GestureDetector(
                                  onTap: _selectTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    decoration: BoxDecoration(
                                      color: theme.accentColor,
                                      borderRadius: BorderRadius.circular(0),
                                      border: Border.all(color: theme.borderColor, width: 3),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'REMINDER TIME',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: theme.borderColor,
                                              letterSpacing: 1,
                                              fontFamily: 'Courier Prime',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _selectedTime.format(context),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: theme.borderColor,
                                                fontFamily: 'Courier Prime',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chevron_right,
                                              color: theme.borderColor,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Frequency Section
                                Text(
                                  'FREQUENCY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textColor,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Courier Prime',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildFrequencyOption('Once Daily', 'once_daily'),
                                const SizedBox(height: 12),
                                _buildFrequencyOption('Weekdays Only', 'weekdays'),
                                const SizedBox(height: 12),
                                _buildFrequencyOption('Random Times', 'random'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String label, String value) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final isSelected = _frequency == value;
    return GestureDetector(
      onTap: () => _setFrequency(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.backgroundColor : theme.cardColor,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(
            color: theme.borderColor,
            width: 3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
                fontFamily: 'Courier Prime',
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: theme.textColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
