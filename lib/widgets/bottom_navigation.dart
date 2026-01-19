import 'package:flutter/material.dart';

class DynamicIslandMenu extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String) onMenuItemTapped;

  const DynamicIslandMenu({
    super.key,
    required this.onClose,
    required this.onMenuItemTapped,
  });

  @override
  State<DynamicIslandMenu> createState() => _DynamicIslandMenuState();
}

class _DynamicIslandMenuState extends State<DynamicIslandMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeMenu() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 500),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Menu title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                        color: Colors.grey.shade900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildMenuItem('Settings', Icons.settings, 'settings'),
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          'Custom Activities',
                          Icons.add_circle,
                          'custom',
                        ),
                        const SizedBox(height: 16),
                        _buildMenuItem('About', Icons.info, 'about'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Close button / bottom padding
                  GestureDetector(
                    onTap: _closeMenu,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade800,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CLOSE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Courier',
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(String label, IconData icon, String value) {
    return GestureDetector(
      onTap: () {
        widget.onMenuItemTapped(value);
        _closeMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade800),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Courier',
                color: Colors.grey.shade900,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, 'Home', Icons.home, currentIndex, onTabChange),
              _buildTabItem(
                1,
                'Stats',
                Icons.bar_chart,
                currentIndex,
                onTabChange,
              ),
              _buildTabItem(
                2,
                'More',
                Icons.more_horiz,
                currentIndex,
                onTabChange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    int index,
    String label,
    IconData icon,
    int currentIndex,
    Function(int) onTap,
  ) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? Colors.grey.shade900 : Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Courier',
              color: isActive ? Colors.grey.shade900 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
