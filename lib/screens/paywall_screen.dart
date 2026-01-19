import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import '../widgets/shared_card_widget.dart';

class PaywallScreen extends StatelessWidget {
  final PremiumService _premiumService = PremiumService();

  PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 28, color: Colors.grey.shade800),
                  padding: const EdgeInsets.all(16),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: SharedCardWidget(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LIFETIME ACCESS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade900,
                              letterSpacing: 2,
                              fontFamily: 'Courier',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildFeature('Customizable monthly Zine printouts'),
                          const SizedBox(height: 16),
                          _buildFeature('Unlimited activities, lofi themes'),
                          const SizedBox(height: 16),
                          _buildFeature('Every future feature included forever'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // TODO: Add your roadmap URL here
                              // You can use url_launcher package to open the link
                              print('Open roadmap link');
                            },
                            child: Text(
                              'View Roadmap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D5A3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2A4A2A), width: 2),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Early Access Price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFA8C4A8),
                                    fontFamily: 'Courier',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$4.99',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFE8F5E8),
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                // TODO: Replace with actual IAP
                                await _premiumService.unlockPremium();
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.grey.shade100,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade800, width: 3),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'UNLOCK PREMIUM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontFamily: 'Courier',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Row(
      children: [
        Text(
          '✦',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}