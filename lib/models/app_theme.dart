import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final bool isPremium;
  final Color backgroundColor;
  final Color cardColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color borderColor;

  const AppTheme({
    required this.id,
    required this.name,
    required this.isPremium,
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.borderColor,
  });

  // Default theme (free) - Light mode with green accents
  // Contrast ratio: ~10:1 (text on card), ~9:1 (text on background)
  static const AppTheme standard = AppTheme(
    id: 'standard',
    name: 'Standard',
    isPremium: false,
    backgroundColor: Color(0xFFEBEBEB),  // Light gray
    cardColor: Colors.white,              // White cards
    primaryColor: Color(0xFF2D3B2D),      // Dark forest green
    accentColor: Color(0xFFC4F2BE),       // Mint green (buttons)
    textColor: Color(0xFF2D3B2D),         // Dark forest green
    borderColor: Color(0xFF2D3B2D),       // Dark forest green
  );

  // Goth Mode - Clean modern dark theme
  // Neutral tones, high contrast, no color tint
  static const AppTheme gothMode = AppTheme(
    id: 'goth_mode',
    name: 'Goth Mode',
    isPremium: true,
    backgroundColor: Color(0xFF121212),   // Near black
    cardColor: Color(0xFF1E1E1E),         // Slightly lighter dark
    primaryColor: Color(0xFF2A2A2A),      // Medium dark
    accentColor: Color(0xFFE0E0E0),       // Clean white-gray for buttons
    textColor: Color(0xFFE8E8E8),         // Off-white text
    borderColor: Color(0xFF3A3A3A),       // Neutral gray border
  );

  // Gamer Green - Refined retro gaming aesthetic
  // Modern take on classic gaming with better visual balance
  static const AppTheme gamerGreen = AppTheme(
    id: 'gamer_green',
    name: 'Gamer Green',
    isPremium: true,
    backgroundColor: Color(0xFF0D1F0D),   // Rich dark forest
    cardColor: Color(0xFF1A3A1A),         // Elevated dark green cards
    primaryColor: Color(0xFF2D5A2D),      // Mid-tone green
    accentColor: Color(0xFFAAD94C),       // Vibrant lime (modernized)
    textColor: Color(0xFFC8E6A0),         // Soft lime-white for readability
    borderColor: Color(0xFF3D6B3D),       // Visible green border
  );

  // Lavender Haze - Soft calming purple theme
  // Gentle lavender tones, easy on the eyes
  static const AppTheme lavenderHaze = AppTheme(
    id: 'lavender_haze',
    name: 'Lavender Haze',
    isPremium: true,
    backgroundColor: Color(0xFFE8E0F0),   // Soft lavender background
    cardColor: Color(0xFFF5F0FA),         // Light purple-white cards
    primaryColor: Color(0xFFD4C4E8),      // Muted lavender
    accentColor: Color(0xFFCDB4E3),       // Soft purple for buttons
    textColor: Color(0xFF3D3452),         // Deep purple-gray text
    borderColor: Color(0xFF5C4E6E),       // Rich purple borders
  );

  // Warm Glow - Blue light filter aesthetic with cute warm tones
  // Cozy amber warmth like Night Shift, soft coral-pink accent
  static const AppTheme warmGlow = AppTheme(
    id: 'warm_glow',
    name: 'Warm Glow',
    isPremium: true,
    backgroundColor: Color(0xFFF7E4D0),   // Warm parchment peach
    cardColor: Color(0xFFFFF6ED),          // Creamy warm white
    primaryColor: Color(0xFFEDAB6E),       // Golden amber
    accentColor: Color(0xFFF9A08C),        // Cute soft coral-pink
    textColor: Color(0xFF4A2818),          // Deep warm brown
    borderColor: Color(0xFF7A4528),        // Rich warm brown
  );

  // List of all themes
  static const List<AppTheme> allThemes = [
    standard,
    lavenderHaze,
    warmGlow,
    gamerGreen,
    gothMode,
  ];

  static AppTheme getThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => standard,
    );
  }
}
