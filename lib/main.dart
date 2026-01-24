import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Denver')); // Mountain Time (Utah)
  
  // Initialize the notification service
  await NotificationService.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadTheme(),
      child: const TouchGrassApp(),
    ),
  );
}

class TouchGrassApp extends StatelessWidget {
  const TouchGrassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Did U Touch Grass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}