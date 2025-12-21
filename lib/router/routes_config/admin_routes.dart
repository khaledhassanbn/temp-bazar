import 'package:flutter/material.dart';
import 'package:bazar_suez/admin/packages/create_package_page.dart';
import 'package:bazar_suez/admin/packages/manage_packages_page.dart';
import 'package:bazar_suez/admin/stores/stores_list_page.dart';
import 'package:bazar_suez/admin/categories/manage_categories_page.dart';
import 'package:bazar_suez/admin/categories/create_edit_category_page.dart';
import 'package:bazar_suez/admin/dashboard/dashboard_page.dart';
import 'package:bazar_suez/ads/views/admin_ads_page.dart';
import 'package:bazar_suez/ads/views/admin_ad_requests_page.dart';
import 'package:bazar_suez/admin/offices/offices_list_page.dart';
import 'package:bazar_suez/admin/offices/create_edit_office_page.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';

// Guard function to check if user is admin
bool isAdminRoute(BuildContext context) {
  final authGuard = Provider.of<AuthGuard>(context, listen: false);
  return authGuard.userStatus == 'admin';
}

final adminRoutes = [
  GoRoute(
    path: '/admin/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/admin/create-package',
    builder: (context, state) => const CreatePackagePage(),
  ),
  GoRoute(
    path: '/admin/manage-packages',
    builder: (context, state) => const ManagePackagesPage(),
  ),
  GoRoute(
    path: '/admin/stores',
    builder: (context, state) => const StoresListPage(),
  ),
  GoRoute(
    path: '/admin/manage-categories',
    builder: (context, state) => const ManageCategoriesPage(),
  ),
  GoRoute(
    path: '/admin/create-category',
    builder: (context, state) => const CreateEditCategoryPage(),
  ),
  GoRoute(
    path: '/admin/edit-category/:categoryId',
    builder: (context, state) {
      final categoryId = state.pathParameters['categoryId']!;
      return CreateEditCategoryPage(categoryId: categoryId);
    },
  ),
  GoRoute(
    path: '/admin/ads',
    builder: (context, state) => const AdminAdsPage(),
  ),
  GoRoute(
    path: '/admin/ad-requests',
    builder: (context, state) => const AdminAdRequestsPage(),
  ),
  GoRoute(
    path: '/admin/offices',
    builder: (context, state) => const OfficesListPage(),
  ),
  GoRoute(
    path: '/admin/create-office',
    builder: (context, state) => const CreateEditOfficePage(),
  ),
  GoRoute(
    path: '/admin/edit-office/:officeId',
    builder: (context, state) {
      final officeId = state.pathParameters['officeId']!;
      return CreateEditOfficePage(officeId: officeId);
    },
  ),
];
