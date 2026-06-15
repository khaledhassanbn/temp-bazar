import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/admin/craftsmen/models/craftsman_admin_model.dart';
import 'package:bazar_suez/admin/craftsmen/services/craftsmen_admin_service.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _DS {
  // Palette
  static Color get navy => AppColors.mainColor;
  static Color get navyLight => AppColors.mainColor.withOpacity(0.85);
  static Color get gold => AppColors.mainColor;
  static const surface = Color(0xFFF8F9FC);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF6B7A99);

  // Status colors
  static const activeGreen = Color(0xFF00C896);
  static const suspendedAmber = Color(0xFFFFB300);
  static const bannedRed = Color(0xFFEF5350);

  // Radius
  static const radius = 16.0;
  static const radiusCard = 20.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.mainColor.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class CraftsmenAdminListPage extends StatefulWidget {
  const CraftsmenAdminListPage({super.key});

  @override
  State<CraftsmenAdminListPage> createState() => _CraftsmenAdminListPageState();
}

class _CraftsmenAdminListPageState extends State<CraftsmenAdminListPage>
    with SingleTickerProviderStateMixin {
  final _service = CraftsmenAdminService();
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _searchQuery = '';
  List<CraftsmanAdminModel>? _searchResults;
  bool _isSearching = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    if (_searchQuery.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _service.searchByNameOrPhone(_searchQuery);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGuard>();
    if (auth.userStatus != 'admin') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: _DS.textSecondary),
              const SizedBox(height: 12),
              Text('غير مصرح بالدخول',
                  style: TextStyle(fontSize: 18, color: _DS.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _DS.surface,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DS.navy, _DS.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة الصنايعية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لوحة التحكم الإدارية',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Stats badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _DS.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _DS.gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded,
                        color: _DS.gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'نشط',
                      style: TextStyle(
                        color: _DS.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search + Filter ─────────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      color: _DS.navy,
      child: Container(
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_DS.radius),
                boxShadow: _DS.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو رقم الهاتف...',
                  hintStyle: TextStyle(
                    color: _DS.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: GestureDetector(
                    onTap: _runSearch,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _DS.navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: _DS.textSecondary, size: 20),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            Text(
              'تصفية حسب الحالة',
              style: TextStyle(
                color: _DS.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    icon: Icons.grid_view_rounded,
                    value: 'all',
                    color: _DS.navy,
                  ),
                  _buildFilterChip(
                    label: 'نشط',
                    icon: Icons.check_circle_outline_rounded,
                    value: 'active',
                    color: _DS.activeGreen,
                  ),
                  _buildFilterChip(
                    label: 'موقوف',
                    icon: Icons.pause_circle_outline_rounded,
                    value: 'suspended',
                    color: _DS.suspendedAmber,
                  ),
                  _buildFilterChip(
                    label: 'محظور',
                    icon: Icons.block_rounded,
                    value: 'banned',
                    color: _DS.bannedRed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () => setState(() {
            _statusFilter = value;
            _searchResults = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: selected ? _DS.cardShadow : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 15,
                    color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _DS.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_searchResults != null) {
      return _buildList(_searchResults!);
    }
    return StreamBuilder<List<CraftsmanAdminModel>>(
      stream: _service.watchCraftsmen(
        accountStatus: _statusFilter == 'all' ? null : _statusFilter,
      ),
      builder: (context, snapshot) {
        if (_isSearching ||
            snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoader();
        }
        return _buildList(snapshot.data ?? []);
      },
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _DS.navy,
              backgroundColor: _DS.navy.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),
          Text('جارٍ التحميل...',
              style: TextStyle(color: _DS.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList(List<CraftsmanAdminModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _DS.navy.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 40, color: _DS.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _DS.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'جرّب تغيير معايير البحث أو الفلتر',
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeCtrl,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final c = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CraftsmanCard(
              craftsman: c,
              onTap: () => context.push('/admin/craftsmen/${c.id}'),
            ),
          );
        },
      ),
    );
  }
}

// ─── Craftsman Card ────────────────────────────────────────────────────────────
class _CraftsmanCard extends StatelessWidget {
  const _CraftsmanCard({required this.craftsman, required this.onTap});

  final CraftsmanAdminModel craftsman;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(craftsman.accountStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _DS.cardBg,
          borderRadius: BorderRadius.circular(_DS.radiusCard),
          boxShadow: _DS.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_DS.radiusCard),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status accent bar
                Container(
                  width: 4,
                  color: statusColor,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Avatar
                        _buildAvatar(statusColor),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(child: _buildInfo()),
                        // Right side
                        _buildTrailing(statusColor),
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

  Widget _buildAvatar(Color statusColor) {
    return Stack(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.15),
                statusColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: craftsman.photoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: craftsman.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Icon(
                      Icons.person_outline_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.person_outline_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                )
              : Icon(Icons.person_outline_rounded,
                  color: statusColor, size: 28),
        ),
        // Online dot
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          craftsman.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: _DS.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.handyman_rounded,
                size: 13, color: _DS.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                craftsman.professionName,
                style: TextStyle(
                    color: _DS.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 13, color: _DS.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                craftsman.areaName,
                style: TextStyle(
                    color: _DS.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Rating
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: AppColors.mainColor),
                  const SizedBox(width: 3),
                  Text(
                    craftsman.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Reports badge
            if (craftsman.reportCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _DS.bannedRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 12, color: _DS.bannedRed.withOpacity(0.8)),
                    const SizedBox(width: 3),
                    Text(
                      '${craftsman.reportCount} بلاغ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _DS.bannedRed.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing(Color statusColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            craftsman.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _DS.navy.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _DS.navy,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return _DS.activeGreen;
      case 'suspended':
        return _DS.suspendedAmber;
      case 'banned':
        return _DS.bannedRed;
      default:
        return _DS.textSecondary;
    }
  }
}