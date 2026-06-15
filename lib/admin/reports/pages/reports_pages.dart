import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/admin/activity_logs/repositories/admin_log_repository.dart';
import 'package:bazar_suez/admin/reports/models/report_model.dart';
import 'package:bazar_suez/admin/reports/models/report_status.dart';
import 'package:bazar_suez/admin/reports/repositories/report_repository.dart';
import 'package:bazar_suez/admin/reports/services/report_service.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final _service = ReportService();
  ReportStatus? _statusFilter;
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthGuard>();
    if (auth.userStatus != 'admin') {
      return const Scaffold(body: Center(child: Text('غير مصرح')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('إدارة البلاغات'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('الكل', _statusFilter == null, () => setState(() => _statusFilter = null)),
                ...ReportStatus.values.map(
                  (s) => _chip(s.labelAr, _statusFilter == s, () => setState(() => _statusFilter = s)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip('كل الأنواع', _typeFilter == null, () => setState(() => _typeFilter = null)),
                _chip('صنايعي', _typeFilter == 'craftsman', () => setState(() => _typeFilter = 'craftsman')),
                _chip('متجر', _typeFilter == 'store', () => setState(() => _typeFilter = 'store')),
                _chip('مندوب', _typeFilter == 'courier', () => setState(() => _typeFilter = 'courier')),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: _service.watchReports(
                status: _statusFilter,
                targetType: _typeFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return const Center(child: Text('لا توجد بلاغات'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return Card(
                      child: ListTile(
                        title: Text(r.targetName),
                        subtitle: Text('${r.reason.labelAr} • ${r.status.labelAr}'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/admin/reports/${r.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.mainColor.withOpacity(0.2),
      ),
    );
  }
}

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _service = ReportService();
  final _repo = ReportRepository();
  ReportModel? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.getById(widget.reportId);
    if (mounted) setState(() => _report = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    if (r == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = context.read<AuthGuard>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('تفاصيل البلاغ'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('المُبلِّغ', r.reporterName),
          _row('الهدف', r.targetName),
          _row('النوع', r.targetType),
          _row('السبب', r.reason.labelAr),
          _row('الحالة', r.status.labelAr),
          if (r.additionalDetails != null) _row('تفاصيل', r.additionalDetails!),
          const SizedBox(height: 24),
          if (r.status == ReportStatus.pending || r.status == ReportStatus.underReview) ...[
            FilledButton(
              onPressed: () async {
                await _service.markUnderReview(
                  reportId: r.id,
                  adminUid: auth.currentUser!.uid,
                  adminName: auth.currentUser?.email ?? 'Admin',
                );
                await _load();
              },
              child: const Text('بدء المراجعة'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                await _service.resolveReport(
                  reportId: r.id,
                  adminUid: auth.currentUser!.uid,
                  adminName: auth.currentUser?.email ?? 'Admin',
                );
                if (mounted) context.pop();
              },
              child: const Text('تم الحل'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await _service.dismissReport(
                  reportId: r.id,
                  adminUid: auth.currentUser!.uid,
                  adminName: auth.currentUser?.email ?? 'Admin',
                );
                if (mounted) context.pop();
              },
              child: const Text('رفض البلاغ'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminLogRepository();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('سجلات النشاط'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: repo.watchRecent(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('لا توجد سجلات'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.actionType.labelAr),
                subtitle: Text('${log.adminName} • ${log.targetName ?? log.targetId}'),
                trailing: Text(
                  log.createdAt != null
                      ? '${log.createdAt!.day}/${log.createdAt!.month}'
                      : '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
