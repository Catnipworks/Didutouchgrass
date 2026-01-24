import 'package:flutter/material.dart';
import 'dart:async';

class TimerController extends ChangeNotifier {
  Timer? _timer;
  int _elapsed = 0;
  bool _isRunning = false;

  int get elapsed => _elapsed;
  bool get isRunning => _isRunning;

  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    _isRunning = true;
    _elapsed = 0;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed++;
      notifyListeners();
    });
  }

  int stopTimer() {
    _timer?.cancel();
    final finalTime = _elapsed;
    _isRunning = false;
    _elapsed = 0;
    notifyListeners();
    return finalTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
