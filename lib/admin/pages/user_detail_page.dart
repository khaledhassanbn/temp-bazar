import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String userType;

  const UserDetailPage({
    Key? key,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final AdminAccountService _adminService = AdminAccountService();
  final ReportService _reportService = ReportService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المستخدم'),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _adminService.watchAccountDetails(
          accountId: widget.userId,
          accountType: widget.userType,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final user = snapshot.data;
          if (user == null) {
            return _buildErrorWidget('المستخدم غير موجود');
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Center(child: StatusBadge(status: user['adminStatus'] ?? 'pending')),
                SizedBox(height: 24),

                // Profile Card
                _buildProfileCard(user),
                SizedBox(height: 16),

                // Stats Card (for craftsmen and stores)
                if (widget.userType == 'craftsman' || widget.userType == 'store')
                  _buildStatsCard(user),

                if (widget.userType == 'craftsman' || widget.userType == 'store')
                  SizedBox(height: 16),

                // Portfolio Images (for craftsmen only)
                if (widget.userType == 'craftsman') ...[
                  _buildPortfolioSection(user),
                  SizedBox(height: 16),
                ],

                // Reports Section
                _buildReportsSection(user),
                SizedBox(height: 16),

                // Last Admin Action
                if (user['lastAdminAction'] != null) ...[
                  _buildLastActionCard(user['lastAdminAction']),
                  SizedBox(height: 16),
                ],

                // Action Buttons
                _buildActionButtons(user),

                if (_isLoading) ...[
                  SizedBox(height: 24),
                  Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> user) {
    String name = '';
    List<Widget> fields = [];

    if (widget.userType == 'craftsman') {
      name = user['name'] ?? 'بدون اسم';
      fields = [
        _buildInfoRow('المهنة', user['profession'] ?? 'غير محدد'),
        _buildInfoRow('رقم الهاتف', user['phone'] ?? 'غير محدد'),
        _buildInfoRow('المدينة', user['city'] ?? 'غير محدد'),
        if (user['bio'] != null && user['bio'].toString().isNotEmpty)
          _buildInfoRow('النبذة', user['bio']),
      ];
    } else if (widget.userType == 'store') {
      name = user['storeName'] ?? 'بدون اسم';
      fields = [
        _buildInfoRow('نوع المتجر', user['storeType'] ?? 'غير محدد'),
        _buildInfoRow('رقم الهاتف', user['phone'] ?? 'غير محدد'),
        _buildInfoRow('المدينة', user['city'] ?? 'غير محدد'),
        if (user['description'] != null && user['description'].toString().isNotEmpty)
          _buildInfoRow('الوصف', user['description']),
      ];
    } else if (widget.userType == 'courier') {
      name = user['courierName'] ?? 'بدون اسم';
      fields = [
        _buildInfoRow('نوع المركبة', user['vehicleType'] ?? 'غير محدد'),
        _buildInfoRow('رقم الهاتف', user['phone'] ?? 'غير محدد'),
        _buildInfoRow('المدينة', user['city'] ?? 'غير محدد'),
      ];
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...fields.map((f) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: f,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> user) {
    final totalCalls = user['totalCalls'] ?? 0;
    final totalWhatsApp = user['totalWhatsApp'] ?? 0;
    final totalViews = user['totalViews'] ?? 0;
    final reportCount = user['reportCount'] ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'الإحصائيات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  icon: Icons.phone,
                  label: 'مكالمات',
                  value: totalCalls.toString(),
                  color: Colors.green,
                ),
                _buildStatColumn(
                  icon: Icons.message,
                  label: 'واتساب',
                  value: totalWhatsApp.toString(),
                  color: Colors.blue,
                ),
                _buildStatColumn(
                  icon: Icons.visibility,
                  label: 'مشاهدات',
                  value: totalViews.toString(),
                  color: Colors.orange,
                ),
                if (reportCount > 0)
                  _buildStatColumn(
                    icon: Icons.report,
                    label: 'بلاغات',
                    value: reportCount.toString(),
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(Map<String, dynamic> user) {
    final portfolioImages = (user['portfolioImages'] as List?)?.cast<String>() ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.purple),
                    SizedBox(width: 12),
                    Text(
                      'معرض الأعمال',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${portfolioImages.length} صورة',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (portfolioImages.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا توجد صور',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: portfolioImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          portfolioImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.delete, size: 16, color: Colors.white),
                            onPressed: () => _confirmDeleteImage(
                              portfolioImages[index],
                              index,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report, color: Colors.red),
                SizedBox(width: 12),
                Text(
                  'البلاغات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            StreamBuilder<List<UserReport>>(
              stream: _reportService.watchReportsForTarget(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا توجد بلاغات',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: reports.map((report) {
                    return ListTile(
                      leading: StatusBadge(status: report.status),
                      title: Text(
                        report.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(report.createdAt.toDate()),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/admin/reports/${report.id}',
                          arguments: report,
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastActionCard(Map<String, dynamic> action) {
    final actionType = action['action'] ?? '';
    final reason = action['reason'] ?? '';
    final timestamp = action['at'];

    String actionText = '';
    Color actionColor = Colors.grey;

    switch (actionType) {
      case 'approved':
        actionText = 'تم القبول';
        actionColor = Colors.green;
        break;
      case 'rejected':
        actionText = 'تم الرفض';
        actionColor = Colors.red;
        break;
      case 'suspended':
        actionText = 'تم التعليق';
        actionColor = Colors.orange;
        break;
      case 'banned':
        actionText = 'تم الحظر';
        actionColor = Colors.red;
        break;
      case 'deleted':
        actionText = 'تم الحذف';
        actionColor = Colors.red;
        break;
      case 'restored':
        actionText = 'تمت الاستعادة';
        actionColor = Colors.green;
        break;
      case 'activated':
        actionText = 'تم التفعيل';
        actionColor = Colors.green;
        break;
    }

    return Card(
      elevation: 2,
      color: actionColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: actionColor),
                SizedBox(width: 12),
                Text(
                  'آخر إجراء إداري',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              actionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
            if (reason.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'السبب: $reason',
                style: TextStyle(fontSize: 14),
              ),
            ],
            if (timestamp != null) ...[
              SizedBox(height: 8),
              Text(
                'التاريخ: ${_formatDateTime((timestamp as Timestamp).toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> user) {
    final adminStatus = user['adminStatus'] ?? 'pending';

    return Column(
      children: [
        // Approve/Reject (for pending users)
        if (adminStatus == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check_circle),
                  label: Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _approveUser,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.cancel),
                  label: Text('رفض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _rejectUser,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],

        // Suspend/Ban (for active users)
        if (adminStatus == 'active') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.pause_circle),
                  label: Text('تعليق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _suspendUser,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.block),
                  label: Text('حظر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _banUser,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],

        // Activate (for suspended/banned users)
        if (adminStatus == 'suspended' || adminStatus == 'banned') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.check_circle),
              label: Text('تفعيل الحساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _activateUser,
            ),
          ),
          SizedBox(height: 12),
        ],

        // Delete (for non-deleted users)
        if (adminStatus != 'deleted') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.delete_forever),
              label: Text('حذف الحساب نهائياً'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _deleteUser,
            ),
          ),
        ],

        // Restore (for deleted users)
        if (adminStatus == 'deleted') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.restore),
              label: Text('استعادة الحساب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _restoreUser,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _approveUser() async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.approveUser(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
      );

      _showSuccessMessage('تم قبول المستخدم بنجاح');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectUser() async {
    final reason = await _showReasonDialog('سبب الرفض');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.rejectUser(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessMessage('تم رفض المستخدم');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _suspendUser() async {
    final reason = await _showReasonDialog('سبب التعليق');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.suspendAccount(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessMessage('تم تعليق الحساب');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _banUser() async {
    final reason = await _showReasonDialog('سبب الحظر');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.banAccount(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessMessage('تم حظر الحساب');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الحساب نهائياً؟\nسيتم تحويل المستخدم لحساب عادي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final reason = await _showReasonDialog('سبب الحذف');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.deleteAccount(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
        reason: reason,
      );

      _showSuccessMessage('تم حذف الحساب');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreUser() async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.restoreAccount(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
      );

      _showSuccessMessage('تم استعادة الحساب');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateUser() async {
    setState(() => _isLoading = true);
    try {
      final adminId = _adminService.getCurrentAdminId();
      if (adminId == null) throw Exception('لم يتم تسجيل الدخول');

      await _adminService.activateAccount(
        accountId: widget.userId,
        accountType: widget.userType,
        adminId: adminId,
      );

      _showSuccessMessage('تم تفعيل الحساب');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteImage(String imageUrl, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف الصورة'),
        content: Text('هل تريد حذف هذه الصورة من معرض الأعمال؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteImage(imageUrl);
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    setState(() => _isLoading = true);
    try {
      await _imageService.deletePortfolioImage(
        craftsmanId: widget.userId,
        imageUrl: imageUrl,
      );

      _showSuccessMessage('تم حذف الصورة');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'الرجاء إدخال السبب',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('يجب إدخال السبب')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: Text('تأكيد'),
          ),
        ],
      ),
    );

    return result;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(date);
  }
}
