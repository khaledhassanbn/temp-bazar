import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'report_detail_page.dart';

class AppColors {
  static const Color mainColor = Color(0xFF4E99B4);
  static const Color mainColorLight = Color(0xFF7BB8CD);
  static const Color mainColorDark = Color(0xFF2E7A97);
  static const Color mainColorSurface = Color(0xFFE8F4F8);
  static const Color accent = Color(0xFFFF7043);
  static const Color background = Color(0xFFF0F7FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A2E35);
  static const Color textSecondary = Color(0xFF607D8B);
}

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({Key? key}) : super(key: key);

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  String _filter = 'pending';
  late TabController _tabController;

  final List<Map<String, dynamic>> _filterTabs = [
    {'key': 'pending', 'label': 'المعلقة', 'icon': Icons.pending_actions},
    {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt},
    {'key': 'resolved', 'label': 'المحلولة', 'icon': Icons.check_circle_outline},
    {'key': 'dismissed', 'label': 'المرفوضة', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filter = _filterTabs[_tabController.index]['key'];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      drawer: AdminDrawer(currentRoute: '/admin/reports'),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildReportsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.mainColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.report_gmailerrorred_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'البلاغات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.mainColor,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
     child: TabBar(
  controller: _tabController,
  isScrollable: true, // أضف السطر ده
  indicator: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
  ),
  tabs: _filterTabs.map((tab) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab['icon'] as IconData, size: 15),
          const SizedBox(width: 4),
          Text(tab['label'] as String),
        ],
      ),
    );
  }).toList(),
),
      ),
    );
  }

  Widget _buildReportsList() {
    return StreamBuilder<List<UserReport>>(
      stream: _filter == 'pending'
          ? _reportService.watchPendingReports()
          : _reportService.watchAllReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final reports = snapshot.data!;
        final filteredReports = _filterReports(reports);

        if (filteredReports.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildSummaryHeader(filteredReports.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filteredReports.length,
                itemBuilder: (context, index) {
                  return AnimatedReportCard(
                    report: filteredReports[index],
                    index: index,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportDetailPage(report: filteredReports[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mainColorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.mainColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _getSummaryLabel(count),
            style: TextStyle(
              color: AppColors.mainColorDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Icon(Icons.filter_list_rounded,
              color: AppColors.mainColor, size: 18),
        ],
      ),
    );
  }

  String _getSummaryLabel(int count) {
    switch (_filter) {
      case 'pending':
        return 'بلاغ معلق يحتاج مراجعة';
      case 'resolved':
        return 'بلاغ تم حله';
      case 'dismissed':
        return 'بلاغ مرفوض';
      default:
        return 'إجمالي البلاغات';
    }
  }

  List<UserReport> _filterReports(List<UserReport> reports) {
    if (_filter == 'all') return reports;
    return reports.where((r) => r.status == _filter).toList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.mainColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل البلاغات...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.mainColorSurface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.mainColor.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.report_off_rounded,
              size: 48,
              color: AppColors.mainColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getEmptyMessage(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا يوجد ما يحتاج اتخاذ إجراء الآن',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case 'pending':
        return 'لا توجد بلاغات معلقة';
      case 'resolved':
        return 'لا توجد بلاغات محلولة';
      case 'dismissed':
        return 'لا توجد بلاغات مرفوضة';
      default:
        return 'لا توجد بلاغات';
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في التحميل',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Report Card ───────────────────────────────────────────────────

class AnimatedReportCard extends StatefulWidget {
  final UserReport report;
  final int index;
  final VoidCallback onTap;

  const AnimatedReportCard({
    Key? key,
    required this.report,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedReportCard> createState() => _AnimatedReportCardState();
}

class _AnimatedReportCardState extends State<AnimatedReportCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 350 + widget.index * 60),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _ReportCardContent(
          report: widget.report,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// ── Report Card Content ────────────────────────────────────────────────────

class _ReportCardContent extends StatelessWidget {
  final UserReport report;
  final VoidCallback onTap;

  const _ReportCardContent({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.mainColor.withOpacity(0.06),
          highlightColor: AppColors.mainColorSurface.withOpacity(0.5),
          child: Column(
            children: [
              // Top colored accent strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusConfig['color'] as Color,
                      (statusConfig['color'] as Color).withOpacity(0.4),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(statusConfig),
                    const SizedBox(height: 10),
                    _buildReasonText(),
                    if (report.status != 'pending') ...[
                      const SizedBox(height: 10),
                      _buildResolutionNote(statusConfig),
                    ],
                    const SizedBox(height: 12),
                    _buildCardFooter(statusConfig),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> statusConfig) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (statusConfig['color'] as Color).withOpacity(0.85),
                statusConfig['color'] as Color,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (statusConfig['color'] as Color).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            statusConfig['icon'] as IconData,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بلاغ عن ${report.targetTypeDisplayName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.createdAt.toDate()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildStatusChip(statusConfig),
      ],
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> statusConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (statusConfig['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (statusConfig['color'] as Color).withOpacity(0.3)),
      ),
      child: Text(
        statusConfig['label'] as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: statusConfig['color'] as Color,
        ),
      ),
    );
  }

  Widget _buildReasonText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              size: 16, color: AppColors.mainColor.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              report.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionNote(Map<String, dynamic> statusConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (statusConfig['color'] as Color).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(
            color: statusConfig['color'] as Color,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            report.status == 'resolved'
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 16,
            color: statusConfig['color'] as Color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              report.resolution ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: (statusConfig['color'] as Color),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(Map<String, dynamic> statusConfig) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'عرض التفاصيل',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 12, color: AppColors.mainColor),
      ],
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'color': const Color(0xFFFF9800),
          'icon': Icons.pending_actions_rounded,
          'label': 'معلق',
        };
      case 'resolved':
        return {
          'color': const Color(0xFF43A047),
          'icon': Icons.check_circle_rounded,
          'label': 'محلول',
        };
      case 'dismissed':
        return {
          'color': const Color(0xFFE53935),
          'icon': Icons.cancel_rounded,
          'label': 'مرفوض',
        };
      default:
        return {
          'color': AppColors.textSecondary,
          'icon': Icons.report_rounded,
          'label': 'غير معروف',
        };
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}