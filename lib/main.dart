import 'package:flutter/material.dart';
import 'Screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const TouchGrassApp());
}

class TouchGrassApp extends StatelessWidget {
  const TouchGrassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Touch Grass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}