import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                context: context,
                icon: Icons.bar_chart_outlined,
                label: 'Stats',
                index: 0,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.apps_outlined,
                label: 'Activities',
                index: 1,
              ),
              _buildTabItem(
                context: context,
                icon: Icons.more_horiz,
                label: 'More',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.textColor : theme.textColor.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.textColor : theme.textColor.withValues(alpha: 0.5),
                fontFamily: 'Courier Prime',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicIslandMenu extends StatelessWidget {
  final VoidCallback onClose;
  final Function(String) onMenuItemTapped;

  const DynamicIslandMenu({
    super.key,
    required this.onClose,
    required this.onMenuItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background overlay - tapping closes menu
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    onClose();
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // Menu at bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(0),
                      border: Border.all(
                        color: theme.borderColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.borderColor,
                          offset: const Offset(8, 8),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // X button in top right
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              onClose();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.borderColor, width: 2),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.share_outlined,
                          label: 'Share with Friends',
                          onTap: () {
                            onMenuItemTapped('share');
                            onClose();
                          },
                        ),
                        _buildDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () {
                            onMenuItemTapped('notifications');
                            onClose();
                          },
                        ),
                        _buildDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.palette_outlined,
                          label: 'Themes',
                          onTap: () {
                            onMenuItemTapped('themes');
                            onClose();
                          },
                        ),
                        _buildDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.edit_outlined,
                          label: 'Add/Edit Activities',
                          onTap: () {
                            onMenuItemTapped('add_edit_activities');
                            onClose();
                          },
                        ),
                        _buildDivider(context),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.info_outline,
                          label: 'About',
                          onTap: () {
                            onMenuItemTapped('about');
                            onClose();
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.textColor,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
                fontFamily: 'Courier Prime',
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 1,
      color: theme.borderColor.withValues(alpha: 0.3),
    );
  }
}
