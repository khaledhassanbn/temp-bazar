import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';
import 'viewmodels/offices_list_viewmodel.dart';
import 'widgets/office_search_bar.dart';
import 'widgets/office_filter_chips.dart';
import 'widgets/office_sort_bar.dart';
import 'widgets/office_card.dart';
import 'widgets/office_actions_button.dart';
import 'models/office_model.dart';

class OfficesListPage extends StatefulWidget {
  const OfficesListPage({super.key});

  @override
  State<OfficesListPage> createState() => _OfficesListPageState();
}

class _OfficesListPageState extends State<OfficesListPage> {
  late OfficesListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OfficesListViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

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

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/dashboard');
              }
            },
          ),
          title: const Text(
            'قائمة مكاتب الشحن',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                context.push('/admin/create-office');
              },
              tooltip: 'إضافة مكتب جديد',
            ),
          ],
        ),
        body: Column(
          children: [
            // قسم البحث والفلاتر
            Container(
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // شريط البحث
                  OfficeSearchBar(
                    onSearchChanged: (value) {
                      _viewModel.setSearchQuery(value);
                    },
                  ),
                  // أزرار الفلاتر
                  OfficeFilterChips(
                    selectedFilter: _viewModel.filterStatus,
                    onFilterChanged: (value) {
                      _viewModel.setFilterStatus(value);
                    },
                  ),
                ],
              ),
            ),
            // شريط الفرز
            Consumer<OfficesListViewModel>(
              builder: (context, viewModel, child) {
                return OfficeSortBar(
                  selectedSort: viewModel.sortBy,
                  isAscending: viewModel.isAscending,
                  onSortChanged: (value) {
                    viewModel.setSortBy(value);
                  },
                  onToggleOrder: () {
                    viewModel.toggleSortOrder();
                  },
                );
              },
            ),
            // قائمة المكاتب
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _viewModel.service.getOfficesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mainColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('خطأ: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مكاتب شحن',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/admin/create-office');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة مكتب جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Consumer<OfficesListViewModel>(
                    builder: (context, viewModel, child) {
                      final sortedOffices = viewModel.sortAndFilterOffices(
                        snapshot.data!.docs,
                      );

                      if (sortedOffices.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد نتائج',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedOffices.length,
                        itemBuilder: (context, index) {
                          final doc = sortedOffices[index];
                          final office = OfficeModel.fromDocument(doc);

                          return Column(
                            children: [
                              OfficeCard(office: office),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: OfficeActionsButton(
                                  officeId: office.id,
                                  isActive: office.isActive,
                                  service: _viewModel.service,
                                  onActionCompleted: () {
                                    // إعادة تحميل القائمة
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
