import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String _frequency = 'once_daily'; // 'once_daily', 'weekends', 'random'

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  Widget _buildDitheredBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade300, Colors.grey.shade400],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(painter: DitherPainter()),
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
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'SETTINGS',
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Analog Reminders Section
                      Text(
                        'ANALOG REMINDERS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.2,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Enable/Disable Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade800,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Enable Reminders',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                                fontFamily: 'Courier',
                              ),
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeThumbColor: const Color(0xFF90EE90),
                              inactiveThumbColor: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Picker
                      if (_notificationsEnabled)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade800,
                                  width: 2,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: _selectTime,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Reminder Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade900,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                    Text(
                                      _selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF90EE90),
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Frequency Options
                            Text(
                              'FREQUENCY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade700,
                                letterSpacing: 1,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                _buildFrequencyOption(
                                  'Once Daily',
                                  'once_daily',
                                ),
                                const SizedBox(height: 8),
                                _buildFrequencyOption(
                                  'Weekdays Only',
                                  'weekdays',
                                ),
                                const SizedBox(height: 8),
                                _buildFrequencyOption('Random Times', 'random'),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String label, String value) {
    final isSelected = _frequency == value;
    return GestureDetector(
      onTap: () => _setFrequency(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF90EE90) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E1B) : Colors.grey.shade800,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1B5E1B)
                    : Colors.grey.shade900,
                fontFamily: 'Courier',
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF1B5E1B), size: 20),
          ],
        ),
      ),
    );
  }
}

// Dithered background painter
class DitherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final dotSize = 2.0;
    final spacing = 6.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final isBlack = random.nextBool();
        final color = isBlack ? Colors.black : Colors.white;
        final opacity = isBlack ? 0.25 : 0.15;
        
        final paint = Paint()..color = color.withOpacity(opacity);
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DitherPainter oldDelegate) => false;
}
