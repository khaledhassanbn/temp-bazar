import 'package:flutter/material.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _dashboardService.getQuickStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: '/admin/management'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStats,
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Row 1
            Row(
              children: [
                StatCard(
                  title: 'الصنايعية',
                  value: stats['totalCraftsmen'].toString(),
                  icon: Icons.construction,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users-management',
                        arguments: {'tab': 0});
                  },
                ),
                SizedBox(width: 12),
                StatCard(
                  title: 'المتاجر',
                  value: stats['totalStores'].toString(),
                  icon: Icons.store,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users-management',
                        arguments: {'tab': 1});
                  },
                ),
              ],
            ),
            SizedBox(height: 12),

            // Quick Stats Row 2
            Row(
              children: [
                StatCard(
                  title: 'البلاغات المعلقة',
                  value: stats['pendingReports'].toString(),
                  icon: Icons.report_problem,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/reports');
                  },
                ),
                SizedBox(width: 12),
                StatCard(
                  title: 'الكوريرات',
                  value: stats['totalCouriers'].toString(),
                  icon: Icons.delivery_dining,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users-management',
                        arguments: {'tab': 2});
                  },
                ),
              ],
            ),
            SizedBox(height: 12),

            // Pending Stats Row
            Row(
              children: [
                StatCard(
                  title: 'صنايعية معلقين',
                  value: stats['pendingCraftsmen'].toString(),
                  icon: Icons.pending_actions,
                  color: Colors.amber,
                ),
                SizedBox(width: 12),
                StatCard(
                  title: 'متاجر معلقة',
                  value: stats['pendingStores'].toString(),
                  icon: Icons.pending,
                  color: Colors.teal,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Craftsmen by Profession Section
            SectionTitle(title: 'الصنايعية حسب المهنة'),
            Card(
              elevation: 2,
              child: _buildCraftsmenByProfession(
                  stats['craftsmenByProfession']),
            ),

            SizedBox(height: 24),

            // Top Craftsmen Section
            SectionTitle(title: 'أكثر الصنايعية تفاعلاً'),
            Card(
              elevation: 2,
              child: _buildTopCraftsmen(stats['topCraftsmen']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftsmenByProfession(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Column(
      children: entries.map((entry) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: Text(
              entry.value.toString(),
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(entry.key),
          trailing: Text(
            '${entry.value} صنايعي',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCraftsmen(List<dynamic> craftsmen) {
    if (craftsmen.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: craftsmen.map((c) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.2),
            child: Text(
              '${c['totalCalls']}',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(c['name']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['profession']),
              if ((c['reportCount'] ?? 0) > 0)
                Text(
                  '${c['reportCount']} بلاغ',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone, size: 16, color: Colors.green),
              Text('${c['totalCalls']}'),
              SizedBox(width: 8),
              Icon(Icons.message, size: 16, color: Colors.blue),
              Text('${c['totalWhatsApp']}'),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/admin/user-management-detail',
              arguments: {
                'userId': c['id'],
                'userType': 'craftsman',
              },
            );
          },
        );
      }).toList(),
    );
  }
}
