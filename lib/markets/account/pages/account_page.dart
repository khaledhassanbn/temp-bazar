import 'package:bazar_suez/markets/account/services/market_account_service.dart';
import 'package:bazar_suez/markets/planes/services/pending_payment_service.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _service = MarketAccountService();
  late Future<AccountSummary> _summaryFuture;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _service.loadAccountSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = _service.loadAccountSummary();
    });
    await _summaryFuture;
  }

  // التحقق من pending payment قبل فتح صفحة plan
  Future<void> _handleCreateMarketTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول')));
      return;
    }

    // إظهار loading أثناء التحقق
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pendingPaymentService = PendingPaymentService();
      final pendingPayment = await pendingPaymentService.getPendingPayment(
        user.uid,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // إغلاق loading

      // إذا كان هناك pending payment صالح، افتح صفحة إنشاء المتجر مباشرة
      if (pendingPayment != null && pendingPayment.isValid) {
        if (context.mounted) {
          context.go(
            '/create-store?packageId=${pendingPayment.packageId}&days=${pendingPayment.days}',
          );
        }
      } else {
        // إذا لم يكن هناك pending payment، افتح صفحة plan
        if (context.mounted) {
          context.push('/pricingpage');
        }
      }
    } catch (e) {
      // في حالة حدوث خطأ، افتح صفحة plan كبديل
      if (!context.mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop(); // إغلاق loading
      }
      if (context.mounted) {
        context.push('/pricingpage');
      }
      print('خطأ في التحقق من pending payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: _refresh,
            child: FutureBuilder<AccountSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: 'تعذر تحميل الحساب',
                    onRetry: _refresh,
                  );
                }
                final summary = snapshot.data;
                if (summary == null) {
                  return _ErrorState(
                    message: 'لا يوجد حساب متاح',
                    onRetry: _refresh,
                  );
                }
                final content = summary.isMarketOwner
                    ? _buildMarketOwnerContent(summary)
                    : _buildUserContent(summary);
                return ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  children: [
                    _AccountHeader(
                      summary: summary,
                      onAction: _showAccountActions,
                    ),
                    const SizedBox(height: 20),
                    // Show create market banner only for regular users (not market owners or admins)
                    if (!summary.isMarketOwner && !summary.isAdmin) ...[
                      _CreateMarketBanner(
                        onTap: () => _handleCreateMarketTap(context),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (summary.isAdmin) ...[
                      ..._buildAdminContent(),
                      const SizedBox(height: 16),
                    ],
                    ...content,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMarketOwnerContent(AccountSummary summary) {
    final market = summary.market;
    final Widget marketCard = market == null
        ? _InfoCard(
            title: 'لم يتم ربط متجر بحسابك بعد',
            description:
                'أكمل إعداد المتجر من صفحة إنشاء المتجر أو تواصل مع الدعم.',
            leadingIcon: Icons.warning_amber_rounded,
            leadingColor: Colors.orange,
            onTap: () => context.go('/create-store'),
            trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
          )
        : _MarketActionsCard(
            market: market,
            actions: _buildMarketActions(market),
          );

    return [
      marketCard,
      const SizedBox(height: 16),
      _SectionCard(
        title: 'حسابي',
        tiles: [
          _MenuTileData(
            icon: Icons.account_balance_wallet_outlined,
            label: 'المحفظة',
            subtitle: 'إدارة رصيدك وعملياتك',
            onTap: () => context.push('/wallet'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: 'الدعم والمساعدة',
        tiles: [
          _MenuTileData(
            icon: Icons.support_agent_outlined,
            label: 'تواصل مع الدعم',
            subtitle: 'نحن هنا لمساعدتك في أي وقت',
            onTap: () => _showSnack('سيتم إتاحة الدعم قريبًا'),
          ),
          _MenuTileData(
            icon: Icons.verified_user_outlined,
            label: 'إدارة الترخيص',
            subtitle: 'خطط وباقات المتجر',
            onTap: () => context.go(
              '/pricingpage${market?.id != null ? '?marketId=${market!.id}' : ''}',
            ),
          ),
        ],
      ),
    ];
  }

  List<_MarketAction> _buildMarketActions(MarketSummary market) {
    return [
      _MarketAction(
        icon: Icons.add_circle_outline,
        label: 'إضافة منتج',
        onTap: () => context.go('/addproduct?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.category_outlined,
        label: 'تعديل المنتجات والفئات',
        onTap: () => context.go('/ManageProducts?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.store_mall_directory_outlined,
        label: 'تعديل المتجر',
        onTap: () => context.go('/edit-store?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.receipt_long_outlined,
        label: 'طلباتي الحالية',
        onTap: () => context.go('/myorder?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.history_toggle_off,
        label: 'طلباتي السابقة',
        onTap: () => context.go('/PastOrders?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.stacked_line_chart,
        label: 'إحصائياتي',
        onTap: () => context.go('/SalesStatsPage?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.group_outlined,
        label: 'إدارة المديرين',
        onTap: () => context.go('/manage-managers?marketId=${market.id}'),
      ),
      _MarketAction(
        icon: Icons.verified_user_outlined,
        label: 'إدارة الترخيص',
        onTap: () => context.go('/pricingpage?marketId=${market.id}'),
      ),
    ];
  }

  List<Widget> _buildAdminContent() {
    return [
      _SectionCard(
        title: 'لوحة الأدمن',
        tiles: [
          _MenuTileData(
            icon: Icons.add_business_outlined,
            label: 'إنشاء باقة جديدة',
            subtitle: 'إضافة باقة اشتراك جديدة',
            onTap: () => context.go('/admin/create-package'),
          ),
          _MenuTileData(
            icon: Icons.manage_accounts_outlined,
            label: 'إدارة الباقات',
            subtitle: 'عرض وتعديل وحذف الباقات',
            onTap: () => context.go('/admin/manage-packages'),
          ),
          _MenuTileData(
            icon: Icons.store_outlined,
            label: 'قائمة المتاجر',
            subtitle: 'عرض جميع المتاجر ومعلوماتها',
            onTap: () => context.go('/admin/stores'),
          ),
          _MenuTileData(
            icon: Icons.category_outlined,
            label: 'إدارة الفئات',
            subtitle: 'إضافة وتعديل وحذف الفئات',
            onTap: () => context.go('/admin/manage-categories'),
          ),
          _MenuTileData(
            icon: Icons.photo_library_rounded,
            label: 'إدارة الإعلانات',
            subtitle: 'تحكم في إعلانات الصفحة الرئيسية',
            onTap: () => context.go('/admin/ads'),
          ),
          _MenuTileData(
            icon: Icons.request_quote_outlined,
            label: 'طلبات الإعلانات',
            subtitle: 'عرض وإدارة طلبات الإعلانات',
            onTap: () => context.go('/admin/ad-requests'),
          ),
          _MenuTileData(
            icon: Icons.account_balance_wallet_outlined,
            label: 'طلبات الإيداع',
            subtitle: 'عرض وإدارة طلبات شحن المحفظة',
            onTap: () => context.push('/admin/wallet-requests'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildUserContent(AccountSummary summary) {
    return [
      _SectionCard(
        title: '',
        tiles: [
          _MenuTileData(
            icon: Icons.location_on_outlined,
            label: 'عناوين التوصيل',
            subtitle: 'إدارة عناوينك المحفوظة',
            onTap: () => context.push('/delivery-addresses'),
          ),
          _MenuTileData(
            icon: Icons.card_giftcard_outlined,
            label: '${summary.loyaltyPoints} نقاط',
            subtitle: 'مكافآت',
            onTap: () => _showSnack('المكافآت ستتوفر قريبًا'),
          ),
          _MenuTileData(
            icon: Icons.receipt_long_outlined,
            label: 'طلباتي السابقة',
            onTap: () => context.push('/user-orders'),
          ),
          _MenuTileData(
            icon: Icons.confirmation_num_outlined,
            label: 'القسائم',
            onTap: () => _showSnack('لا توجد قسائم نشطة'),
          ),
          _MenuTileData(
            icon: Icons.workspace_premium_outlined,
            label: 'talabat pro',
            badge: 'pro',
            onTap: () => context.push('/pricingpage'),
          ),
          _MenuTileData(
            icon: Icons.help_outline,
            label: 'احصل على المساعدة',
            onTap: () => _showSnack('سيتم تحويلك إلى الدعم قريبًا'),
          ),
          _MenuTileData(
            icon: Icons.info_outline,
            label: 'حول التطبيق',
            onTap: () => _showSnack('إصدار التطبيق 1.0.0'),
          ),
        ],
      ),
    ];
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAccountActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('تسجيل الخروج'),
              onTap: _signOut,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pop(); // close bottom sheet
        context.go('/login');
      }
    } catch (e) {
      _showSnack('فشل تسجيل الخروج، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}

class _AccountHeader extends StatelessWidget {
  final AccountSummary summary;
  final VoidCallback onAction;

  const _AccountHeader({required this.summary, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final avatar = summary.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.mainColor.withOpacity(0.02)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.mainColor.withOpacity(0.1),
              child: CircleAvatar(
                radius: 36,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                backgroundColor: const Color(0xFFF8F9FA),
                child: avatar == null
                    ? Text(
                        _initial(summary.displayName),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.displayName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset('assets/images/egypt.jpg', height: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'مصر',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _truncateEmail(summary.email, 25),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: onAction,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.mainColor,
              ),
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'م';
    return trimmed.substring(0, 1);
  }

  String _truncateEmail(String email, int maxLength) {
    if (email.length <= maxLength) return email;
    return '${email.substring(0, maxLength - 3)}...';
  }
}

class _MarketActionsCard extends StatefulWidget {
  final MarketSummary market;
  final List<_MarketAction> actions;

  const _MarketActionsCard({required this.market, required this.actions});

  @override
  State<_MarketActionsCard> createState() => _MarketActionsCardState();
}

class _MarketActionsCardState extends State<_MarketActionsCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final logo = widget.market.logoUrl;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: logo != null ? NetworkImage(logo) : null,
              backgroundColor: const Color(0xFFEFF3F6),
              child: logo == null
                  ? const Icon(Icons.storefront, color: AppColors.mainColor)
                  : null,
            ),
            title: Text(
              widget.market.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
            ),
            subtitle: const Text(
              'إدارة كل ما يخص متجرك',
              textAlign: TextAlign.right,
            ),
            trailing: IconButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: widget.actions
                  .map(
                    (action) => ListTile(
                      leading: Icon(action.icon, color: AppColors.mainColor),
                      title: Text(
                        action.label,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
                      onTap: action.onTap,
                    ),
                  )
                  .toList(),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MarketAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MarketAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_MenuTileData> tiles;

  const _SectionCard({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ...tiles.map((tile) => _MenuTile(data: tile)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MenuTileData {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MenuTileData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuTileData data;

  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Icon(data.icon, color: AppColors.mainColor, size: 24),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (data.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.badge!,
                      style: const TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    data.label,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: data.subtitle != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.subtitle!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  )
                : null,
            trailing: const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final String? badgeText;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String? leadingImage;
  final Widget? trailing;
  final VoidCallback onTap;

  const _InfoCard({
    required this.title,
    required this.description,
    this.badgeText,
    this.leadingIcon,
    this.leadingColor,
    this.leadingImage,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C1FFF), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            if (leadingImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  leadingImage!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              )
            else
              CircleAvatar(
                radius: 36,
                backgroundColor: leadingColor ?? Colors.white.withOpacity(0.15),
                child: Icon(
                  leadingIcon ?? Icons.info_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CreateMarketBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateMarketBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/create_market.png',
            fit: BoxFit.fitWidth,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
