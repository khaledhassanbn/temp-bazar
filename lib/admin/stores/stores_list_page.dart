import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';
import 'viewmodels/stores_list_viewmodel.dart';
import 'widgets/store_search_bar.dart';
import 'widgets/store_filter_chips.dart';
import 'widgets/store_sort_bar.dart';
import 'widgets/store_card.dart';

class StoresListPage extends StatefulWidget {
  const StoresListPage({super.key});

  @override
  State<StoresListPage> createState() => _StoresListPageState();
}

class _StoresListPageState extends State<StoresListPage> {
  late StoresListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StoresListViewModel();
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
            'قائمة المتاجر',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.mainColor,
          elevation: 0,
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
                  StoreSearchBar(
                    onSearchChanged: (value) {
                      _viewModel.setSearchQuery(value);
                    },
                  ),
                  // أزرار الفلاتر
                  StoreFilterChips(
                    selectedFilter: _viewModel.filterStatus,
                    onFilterChanged: (value) {
                      _viewModel.setFilterStatus(value);
                    },
                  ),
                ],
              ),
            ),
            // شريط الفرز
            Consumer<StoresListViewModel>(
              builder: (context, viewModel, child) {
                return StoreSortBar(
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
            // قائمة المتاجر
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _viewModel.service.getStoresStream(),
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
                            Icons.store_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد متاجر',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Consumer<StoresListViewModel>(
                    builder: (context, viewModel, child) {
                      final sortedStores = viewModel.sortAndFilterStores(
                        snapshot.data!.docs,
                      );

                      if (sortedStores.isEmpty) {
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
                        itemCount: sortedStores.length,
                        itemBuilder: (context, index) {
                          final doc = sortedStores[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final marketId = doc.id;

                          return StoreCard(
                            marketId: marketId,
                            data: data,
                            service: _viewModel.service,
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
