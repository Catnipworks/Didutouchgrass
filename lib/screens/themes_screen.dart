import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/premium_service.dart';
import 'paywall_screen.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: currentTheme.backgroundColor),
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
                            color: currentTheme.cardColor,
                            border: Border.all(color: currentTheme.borderColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: currentTheme.textColor,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'THEMES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: currentTheme.textColor,
                            letterSpacing: 1.5,
                            fontFamily: 'Courier Prime',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                // Theme grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView.builder(
                      itemCount: AppTheme.allThemes.length,
                      itemBuilder: (context, index) {
                        final theme = AppTheme.allThemes[index];
                        final isSelected = theme.id == currentTheme.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () async {
                              if (theme.isPremium) {
                                final premiumService = PremiumService();
                                final isPremium = await premiumService.isPremium();

                                if (!isPremium && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => PaywallScreen()),
                                  );
                                  return;
                                }
                              }
                              themeProvider.setTheme(theme);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: currentTheme.cardColor,
                                border: Border.all(
                                  color: isSelected ? currentTheme.accentColor : currentTheme.borderColor,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: currentTheme.borderColor,
                                    offset: const Offset(6, 6),
                                    blurRadius: 0,
                                  ),
                                ] : [],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Theme header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              theme.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: currentTheme.textColor,
                                                letterSpacing: 1,
                                                fontFamily: 'Courier Prime',
                                              ),
                                            ),
                                            if (theme.isPremium) ...[
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: theme.borderColor,
                                                  border: Border.all(
                                                    color: currentTheme.textColor.withValues(alpha: 0.3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  'PRO',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: theme.accentColor,
                                                    fontFamily: 'Courier Prime',
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: currentTheme.accentColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: currentTheme.borderColor, width: 2),
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: currentTheme.borderColor,
                                              size: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Mini preview mockup
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Row(
                                      children: [
                                        // Phone mockup preview
                                        Container(
                                          width: 100,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: theme.backgroundColor,
                                            border: Border.all(color: theme.borderColor, width: 2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: Column(
                                            children: [
                                              // Mini header
                                              Container(
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: theme.cardColor,
                                                  border: Border.all(color: theme.borderColor, width: 1),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 30,
                                                    height: 4,
                                                    color: theme.textColor.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // Mini card
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor,
                                                    border: Border.all(color: theme.borderColor, width: 1),
                                                  ),
                                                  padding: const EdgeInsets.all(6),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 4,
                                                        color: theme.textColor,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        width: 55,
                                                        height: 3,
                                                        color: theme.textColor.withValues(alpha: 0.5),
                                                      ),
                                                      const Spacer(),
                                                      // Mini button
                                                      Container(
                                                        width: double.infinity,
                                                        height: 14,
                                                        decoration: BoxDecoration(
                                                          color: theme.accentColor,
                                                          border: Border.all(color: theme.borderColor, width: 1),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // Mini bottom nav
                                              Container(
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: theme.cardColor,
                                                  border: Border.all(color: theme.borderColor, width: 1),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    Container(width: 10, height: 10, color: theme.textColor.withValues(alpha: 0.4)),
                                                    Container(width: 10, height: 10, color: theme.accentColor),
                                                    Container(width: 10, height: 10, color: theme.textColor.withValues(alpha: 0.4)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // Color swatches grid
                                        Expanded(
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _buildSwatch(theme.backgroundColor, currentTheme, size: 38),
                                              _buildSwatch(theme.cardColor, currentTheme, size: 38),
                                              _buildSwatch(theme.accentColor, currentTheme, size: 38),
                                              _buildSwatch(theme.textColor, currentTheme, size: 38),
                                              _buildSwatch(theme.borderColor, currentTheme, size: 38),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwatch(Color color, AppTheme currentTheme, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: currentTheme.borderColor.withValues(alpha: 0.4), width: 1.5),
      ),
    );
  }
}
