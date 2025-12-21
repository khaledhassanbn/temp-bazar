import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/admin_ad_requests_viewmodel.dart';
import '../widgets/request_card.dart';
import '../widgets/loading_snackbar.dart';

class AdminAdRequestsPage extends StatelessWidget {
  const AdminAdRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(child: Text('غير مصرح لك بالوصول إلى هذه الصفحة')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AdminAdRequestsViewModel()..loadRequests(),
      child: const _AdminAdRequestsView(),
    );
  }
}

class _AdminAdRequestsView extends StatelessWidget {
  const _AdminAdRequestsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'طلبات الإعلانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
        ),
        body: Consumer<AdminAdRequestsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            if (viewModel.requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد طلبات',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadRequests(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.requests.length,
                itemBuilder: (context, index) {
                  final request = viewModel.requests[index];
                  return RequestCard(
                    request: request,
                    onApprove: () => _handleApprove(context, request.id),
                    onReject: () => _handleReject(context, request.id),
                    onDelete: () => _handleDelete(context, request.id),
                    formatDate: viewModel.formatDate,
                    getStatusColor: viewModel.getStatusColor,
                    getStatusText: viewModel.getStatusText,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();

    LoadingSnackBar.show(context, 'جاري إنشاء الإعلان...');
    final success = await viewModel.updateRequestStatus(requestId, 'approved');
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(
        context,
        'تم الموافقة على الطلب وإنشاء الإعلان بنجاح',
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        context.go('/admin/ads');
      }
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل تحديث حالة الطلب',
      );
    }
  }

  Future<void> _handleReject(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();

    LoadingSnackBar.show(context, 'جاري تحديث حالة الطلب...');
    final success = await viewModel.updateRequestStatus(requestId, 'rejected');
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم تحديث حالة الطلب بنجاح');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل تحديث حالة الطلب',
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, String requestId) async {
    final viewModel = context.read<AdminAdRequestsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteRequest(requestId);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم حذف الطلب بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل حذف الطلب',
        );
      }
    }
  }
}



