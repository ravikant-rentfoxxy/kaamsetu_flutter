import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

class ShellTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  const ShellTab(this.icon, this.activeIcon, this.label, this.page);
}

/// Bottom-tab scaffold shared by the worker and employer shells.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.tabs, required this.index, required this.onTap});

  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(index: i, children: [for (final t in tabs) t.page]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppShadows.lg,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var t = 0; t < tabs.length; t++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onTap(t),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t == i ? tabs[t].activeIcon : tabs[t].icon, size: 24, color: t == i ? AppColors.primary : AppColors.textTertiary),
                          const SizedBox(height: 3),
                          Text(
                            tabs[t].label,
                            maxLines: 1,
                            style: AppText.tiny.copyWith(
                              color: t == i ? AppColors.primary : AppColors.textTertiary,
                              fontWeight: t == i ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
