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
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                for (var t = 0; t < tabs.length; t++)
                  Expanded(
                    child: Semantics(
                      selected: t == i,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => onTap(t),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 56,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: t == i ? AppColors.primaryLight : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(t == i ? tabs[t].activeIcon : tabs[t].icon, size: 22, color: t == i ? AppColors.primary : AppColors.textTertiary),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tabs[t].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label.copyWith(
                                  color: t == i ? AppColors.primary : AppColors.textTertiary,
                                  fontWeight: t == i ? FontWeight.w800 : FontWeight.w700,
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
      ),
    );
  }
}
