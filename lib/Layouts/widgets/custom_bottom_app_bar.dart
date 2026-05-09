import 'dart:ui';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomAppBar extends StatefulWidget {
  final int currentIndex;
  final int ordersCount;
  final Function(int) onTap;

  const CustomBottomAppBar({
    super.key,
    required this.currentIndex,
    required this.ordersCount,
    required this.onTap,
  });

  @override
  State<CustomBottomAppBar> createState() => _CustomBottomAppBarState();
}

class _CustomBottomAppBarState extends State<CustomBottomAppBar> {
  bool _manageMenuOpen = false;
  OverlayEntry? _manageOverlay;

  void _toggleManageMenu() {
    if (_manageMenuOpen) {
      _closeManageMenu();
    } else {
      _openManageMenu();
    }
  }

  void _closeManageMenu() {
    _manageOverlay?.remove();
    _manageOverlay = null;
    if (_manageMenuOpen && mounted) {
      setState(() {
        _manageMenuOpen = false;
      });
    }
  }

  void _handleNavigation(int index) {
    if (!mounted) return;
    _closeManageMenu();
    Feedback.forTap(context);
    widget.onTap(index);
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    _closeManageMenu();
    Feedback.forTap(context);
    GoRouter.of(context).go(route);
  }

  void _openManageMenu() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final actions = _buildManageActions();
    _manageOverlay = OverlayEntry(
      builder: (context) {
        final size = MediaQuery.of(context).size;
        const double menuWidth = 220;
        final double left = (size.width - menuWidth) / 2;
        final double bottom = MediaQuery.of(context).padding.bottom + 80;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeManageMenu,
                child: Container(color: Colors.black.withOpacity(0.12)),
              ),
            ),
            Positioned(
              bottom: bottom,
              left: left < 16 ? 16 : left,
              right: left < 16 ? 16 : null,
              child: _ManageMenu(actions: actions, onDismiss: _closeManageMenu),
            ),
          ],
        );
      },
    );

    overlay.insert(_manageOverlay!);
    if (mounted) {
      setState(() {
        _manageMenuOpen = true;
      });
    }
  }

  List<_ManageAction> _buildManageActions() => [
    _ManageAction(
      icon: Icons.store_mall_directory,
      label: 'تعديل المتجر',
      onTap: () => _navigateTo('/edit-store'),
    ),
    _ManageAction(
      icon: Icons.inventory_2_rounded,
      label: 'تعديل المنتجات',
      onTap: () => _navigateTo('/ManageProducts'),
    ),
    _ManageAction(
      icon: Icons.add_circle_outline,
      label: 'إضافة منتج',
      onTap: () => _navigateTo('/addproduct'),
    ),
    _ManageAction(
      icon: Icons.verified_user_outlined,
      label: 'الترخيص',
      onTap: () => _navigateTo('/market-dashboard'),
    ),
  ];

  @override
  void dispose() {
    _manageOverlay?.remove();
    _manageOverlay = null;
    super.dispose();
  }

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
                    _buildNavItem(
                      context,
                      Icons.home_rounded,
                      'الرئيسية',
                      0,
                      onTapOverride: () => _handleNavigation(0),
                    ),
                    _buildOrdersItem(context),
                    _buildNavItem(
                      context,
                      Icons.manage_accounts,
                      'إدارة المتجر',
                      2,
                      onTapOverride: _toggleManageMenu,
                      isActiveOverride: _manageMenuOpen,
                    ),
                    _buildNavItem(
                      context,
                      Icons.storefront_rounded,
                      'متجري',
                      3,
                      onTapOverride: () => _handleNavigation(3),
                    ),
                    _buildNavItem(
                      context,
                      Icons.person_outline_rounded,
                      'حسابي',
                      4,
                      onTapOverride: () => _handleNavigation(4),
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

  Widget _buildOrdersItem(BuildContext context) {
    final isActive = widget.currentIndex == 1 && !_manageMenuOpen;
    return GestureDetector(
      onTap: () => _handleNavigation(1),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: isActive ? AppColors.mainColor : Colors.grey,
                  size: 24,
                ),
                if (widget.ordersCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${widget.ordersCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'الطلبات',
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

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    VoidCallback? onTapOverride,
    bool isActiveOverride = false,
  }) {
    final isActive =
        isActiveOverride || widget.currentIndex == index && !_manageMenuOpen;
    return GestureDetector(
      onTap: onTapOverride ?? () => _handleNavigation(index),
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

class _ManageAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ManageAction({required this.icon, required this.label, required this.onTap});
}

class _ManageMenu extends StatelessWidget {
  final List<_ManageAction> actions;
  final VoidCallback onDismiss;

  const _ManageMenu({required this.actions, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (action) =>
                    _ManageMenuItem(action: action, onDismiss: onDismiss),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ManageMenuItem extends StatelessWidget {
  final _ManageAction action;
  final VoidCallback onDismiss;

  const _ManageMenuItem({required this.action, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Feedback.forTap(context);
          onDismiss();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.mainColor.withOpacity(0.1),
        highlightColor: AppColors.mainColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(action.icon, color: AppColors.mainColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
