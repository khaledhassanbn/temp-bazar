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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onTap(index);
    });
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    _closeManageMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.of(context).go(route);
    });
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
        final double bottom = MediaQuery.of(context).padding.bottom + 90;

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
      onTap: () => _navigateTo('/pricingpage'),
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
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                Icons.home,
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
                Icons.storefront,
                'متجري',
                3,
                onTapOverride: () => _handleNavigation(3),
              ),
              _buildNavItem(
                context,
                Icons.person,
                'حسابي',
                4,
                onTapOverride: () => _handleNavigation(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersItem(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.mainColor.withOpacity(0.2),
        onTap: () => _handleNavigation(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.receipt_long,
                  color: widget.currentIndex == 1
                      ? AppColors.mainColor
                      : Colors.grey,
                  size: 26,
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
            const SizedBox(height: 2),
            const Text(
              'الطلبات',
              style: TextStyle(fontSize: 11),
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
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.mainColor.withOpacity(0.2),
        onTap: onTapOverride ?? () => _handleNavigation(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.mainColor : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.mainColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
