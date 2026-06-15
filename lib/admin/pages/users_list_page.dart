import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class UsersListPage extends StatefulWidget {
  final int initialTab;

  const UsersListPage({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminAccountService _adminService = AdminAccountService();

  String _craftsmenFilter = 'all';
  String _storesFilter = 'all';
  String _couriersFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('إدارة المستخدمين'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'الصنايعية', icon: Icon(Icons.construction)),
            Tab(text: 'المتاجر', icon: Icon(Icons.store)),
            Tab(text: 'الكوريرات', icon: Icon(Icons.delivery_dining)),
          ],
        ),
      ),
      drawer: AdminDrawer(currentRoute: '/admin/users-management'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab('craftsman', _craftsmenFilter, (val) {
            setState(() => _craftsmenFilter = val);
          }),
          _buildUsersTab('store', _storesFilter, (val) {
            setState(() => _storesFilter = val);
          }),
          _buildUsersTab('courier', _couriersFilter, (val) {
            setState(() => _couriersFilter = val);
          }),
        ],
      ),
    );
  }

  Widget _buildUsersTab(
    String accountType,
    String currentFilter,
    Function(String) onFilterChange,
  ) {
    return Column(
      children: [
        // Filter Dropdown
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'تصفية حسب الحالة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'pending', child: Text('معلق')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'suspended', child: Text('معلق')),
                    DropdownMenuItem(value: 'banned', child: Text('محظور')),
                    DropdownMenuItem(value: 'deleted', child: Text('محذوف')),
                  ],
                  onChanged: (val) => onFilterChange(val!),
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _adminService.watchAccountsByStatus(
              accountType: accountType,
              status: currentFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorWidget(snapshot.error.toString());
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return _buildEmptyWidget();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user, accountType);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String accountType) {
    final adminStatus = user['adminStatus'] ?? 'pending';
    final reportCount = user['reportCount'] ?? 0;
    final totalCalls = user['totalCalls'] ?? 0;
    final totalWhatsApp = user['totalWhatsApp'] ?? 0;

    String userName = '';
    String subTitle = '';

    if (accountType == 'craftsman') {
      userName = user['name'] ?? 'بدون اسم';
      subTitle = user['profession'] ?? 'غير محدد';
    } else if (accountType == 'store') {
      userName = user['storeName'] ?? 'بدون اسم';
      subTitle = user['storeType'] ?? 'غير محدد';
    } else if (accountType == 'courier') {
      userName = user['courierName'] ?? 'بدون اسم';
      subTitle = user['vehicleType'] ?? 'غير محدد';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/user-management-detail',
            arguments: {
              'userId': user['id'],
              'userType': accountType,
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  StatusBadge(status: adminStatus),
                ],
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                subTitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              // Stats Row
              if (accountType == 'craftsman' || accountType == 'store') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.phone,
                      label: '$totalCalls',
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.message,
                      label: '$totalWhatsApp',
                      color: Colors.blue,
                    ),
                    if (reportCount > 0) ...[
                      SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.report,
                        label: '$reportCount',
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
              ],

              // Last Admin Action
              if (user['lastAdminAction'] != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatLastAction(user['lastAdminAction']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا يوجد مستخدمين',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  String _formatLastAction(Map<String, dynamic> action) {
    final actionType = action['action'] ?? '';
    final timestamp = action['at'];

    String actionText = '';
    switch (actionType) {
      case 'approved':
        actionText = 'تم القبول';
        break;
      case 'rejected':
        actionText = 'تم الرفض';
        break;
      case 'suspended':
        actionText = 'تم التعليق';
        break;
      case 'banned':
        actionText = 'تم الحظر';
        break;
      case 'deleted':
        actionText = 'تم الحذف';
        break;
      case 'restored':
        actionText = 'تمت الاستعادة';
        break;
      case 'activated':
        actionText = 'تم التفعيل';
        break;
      default:
        actionText = actionType;
    }

    if (timestamp != null) {
      final date = (timestamp as Timestamp).toDate();
      final formattedDate = DateFormat('dd/MM/yyyy').format(date);
      return '$actionText - $formattedDate';
    }

    return actionText;
  }
}
