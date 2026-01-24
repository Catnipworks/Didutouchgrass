import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header - back button only
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
                ],
              ),
            ),
            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(
                          color: theme.borderColor,
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.borderColor,
                            offset: const Offset(8, 8),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: theme.textColor,
                              fontFamily: 'DotGothic16',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'A Catnip Works utility',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor.withValues(alpha: 0.5),
                              fontFamily: 'Courier Prime',
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 2,
                            color: theme.borderColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "An app by someone who finds most apps annoying, designed specifically to get you off your phone.",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                              fontFamily: 'Courier Prime',
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Built by a solo, self-taught full-stack developer who doesn't actually like using apps and tries to stay off the phone as much as possible.",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: theme.textColor.withValues(alpha: 0.7),
                              fontFamily: 'Courier Prime',
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('https://didutouchgrass.com'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              decoration: BoxDecoration(
                                color: theme.backgroundColor,
                                border: Border.all(color: theme.borderColor, width: 2),
                              ),
                              child: Text(
                                'didutouchgrass.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor,
                                  fontFamily: 'Courier Prime',
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }
}
