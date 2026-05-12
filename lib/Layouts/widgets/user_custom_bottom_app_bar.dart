import 'dart:ui';

import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';

/// شريط سفلي للمستخدم بنفس أسلوب [CustomBottomAppBar] (ضبابية، ارتفاع، ألوان).
/// الترتيب البصري من اليمين لليسار (RTL): الرئيسية، الطلبات، الحساب.
class UserCustomBottomAppBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const UserCustomBottomAppBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _UserNavItem(
                      icon: Icons.home_rounded,
                      label: 'الرئيسية',
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _UserNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'طلباتي',
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _UserNavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'حسابي',
                      isActive: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _UserNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.mainColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.mainColor : Colors.grey,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
