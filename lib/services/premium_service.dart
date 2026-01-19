import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';

  // Check if user has premium
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  // Set premium status (this would be called after successful IAP)
  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }

  // Unlock premium (for testing - replace with actual IAP later)
  Future<void> unlockPremium() async {
    await setPremium(true);
  }

  // Reset premium (for testing)
  Future<void> resetPremium() async {
    await setPremium(false);
  }
}