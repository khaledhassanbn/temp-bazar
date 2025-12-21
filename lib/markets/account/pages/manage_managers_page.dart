import 'package:bazar_suez/markets/account/services/market_account_service.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';

class ManageManagersPage extends StatefulWidget {
  final String marketId;

  const ManageManagersPage({super.key, required this.marketId});

  @override
  State<ManageManagersPage> createState() => _ManageManagersPageState();
}

class _ManageManagersPageState extends State<ManageManagersPage> {
  final _service = MarketAccountService();
  final _emailController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('إدارة المديرين'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAddManagerCard(),
              const SizedBox(height: 20),
              Expanded(child: _buildManagersList()),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  📌 Card إضافة مدير جديد
  // ---------------------------------------------------------------------------

  Widget _buildAddManagerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أضف مديرًا جديدًا',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 14),

          // Email Field
          TextField(
            controller: _emailController,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'example@email.com',
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: _inputBorder(),
              enabledBorder: _inputBorder(),
              focusedBorder: _inputBorder(color: AppColors.mainColor),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isAdding ? null : _handleAddManager,
              icon: _isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: const Text('إضافة مدير', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  📌 قائمة المديرين
  // ---------------------------------------------------------------------------

  Widget _buildManagersList() {
    return StreamBuilder<List<ManagerProfile>>(
      stream: _service.watchManagers(widget.marketId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final managers = snapshot.data ?? [];

        if (managers.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد مديرون مرتبطون بهذا المتجر بعد',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: managers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final manager = managers[i];
            final allowDelete = managers.length > 1;

            return _ManagerCard(
              profile: manager,
              canDelete: allowDelete,
              onDelete: () => _confirmDelete(manager, allowDelete),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  //  📌 إضافة مدير
  // ---------------------------------------------------------------------------

  Future<void> _handleAddManager() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('الرجاء إدخال البريد الإلكتروني');
      return;
    }

    setState(() => _isAdding = true);

    try {
      await _service.addManager(email, widget.marketId);
      _emailController.clear();
      _showSnack('تمت إضافة المدير بنجاح', isSuccess: true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  // ---------------------------------------------------------------------------
  //  📌 تأكيد الحذف
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(ManagerProfile manager, bool canDelete) async {
    if (!canDelete) {
      _showSnack('يجب أن يبقى مدير واحد على الأقل');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المدير'),
        content: Text('هل أنت متأكد من حذف ${manager.displayName}?'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('حذف'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.removeManager(manager.uid);
      _showSnack('تم حذف المدير', isSuccess: true);
    } catch (e) {
      _showSnack('حدث خطأ أثناء الحذف');
    }
  }

  // ---------------------------------------------------------------------------
  //  📌 أدوات مساعدة
  // ---------------------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  📌 Card المدير الواحد
// ---------------------------------------------------------------------------

class _ManagerCard extends StatelessWidget {
  final ManagerProfile profile;
  final bool canDelete;
  final VoidCallback onDelete;

  const _ManagerCard({
    required this.profile,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة المدير
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.mainColor.withOpacity(0.15),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // الاسم والاميل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          // زر الحذف
          IconButton(
            onPressed: canDelete ? onDelete : null,
            icon: Icon(
              Icons.delete_outline,
              size: 26,
              color: canDelete ? Colors.redAccent : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
