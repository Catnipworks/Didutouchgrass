import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../providers/theme_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final PremiumService _premiumService = PremiumService();
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      body: Container(
        color: theme.backgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
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
                        offset: const Offset(8, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button inside card - smaller
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                      Text(
                        'LIFETIME ACCESS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.textColor,
                          letterSpacing: 1.5,
                          fontFamily: 'DotGothic16',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _buildFeature('Custom Zines', 'Turn your data into monthly physical printouts.'),
                      const SizedBox(height: 16),
                      _buildFeature('Full Library', 'Access all current and future activities + themes.'),
                      const SizedBox(height: 16),
                      _buildFeature('One-Time Buy', 'Lock in every future update for life.'),
                      const SizedBox(height: 20),
                      Text(
                        'Built by a solo creator. Your support keeps this utility ad-free.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: theme.textColor.withValues(alpha: 0.6),
                          fontFamily: 'Courier Prime',
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Price box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(color: theme.borderColor, width: 3),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'EARLY ACCESS PRICE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor.withValues(alpha: 0.5),
                                letterSpacing: 1.5,
                                fontFamily: 'Courier Prime',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$5.99',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                                fontFamily: 'Courier Prime',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Green unlock button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) async {
                          setState(() => _isButtonPressed = false);
                          await _premiumService.unlockPremium();
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          transform: Matrix4.translationValues(
                            _isButtonPressed ? 4 : 0,
                            _isButtonPressed ? 4 : 0,
                            0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(0),
                            border: Border.all(color: theme.borderColor, width: 3),
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
                            'UNLOCK PREMIUM',
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

  Widget _buildFeature(String title, String description) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '●',
            style: TextStyle(
              fontSize: 10,
              color: theme.textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontFamily: 'Courier Prime',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: theme.textColor.withValues(alpha: 0.7),
                  height: 1.3,
                  fontFamily: 'Courier Prime',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
