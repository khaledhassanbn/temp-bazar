import 'package:bazar_suez/admin/reports/pages/reports_pages.dart';
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

import 'package:bazar_suez/admin/delivery_fee/delivery_fee_settings_page.dart';

import 'package:bazar_suez/admin/courier_requests/courier_requests_page.dart';

import 'package:bazar_suez/admin/courier_requests/courier_request_detail_page.dart';

import 'package:bazar_suez/admin/craftsmen/craftsmen_admin_list_page.dart';

import 'package:bazar_suez/admin/craftsmen/craftsman_admin_detail_page.dart';

import 'package:bazar_suez/admin/security/pages/admin_roles_page.dart';

import 'package:bazar_suez/admin/security/pages/deleted_accounts_page.dart';

// import 'package:bazar_suez/admin/reports/pages/reports_pages.dart';

// 🆕 نظام إدارة الأدمن الجديد
import 'package:bazar_suez/admin/pages/pages.dart' as admin_pages;
import 'package:bazar_suez/admin/models/models.dart' as admin_models;

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import 'package:bazar_suez/authentication/guards/AuthGuard.dart';



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

  GoRoute(

    path: '/admin/delivery-fee-settings',

    builder: (context, state) => const DeliveryFeeSettingsPage(),

  ),

  GoRoute(

    path: '/admin/courier-requests',

    builder: (context, state) => const CourierRequestsPage(),

  ),

  GoRoute(

    path: '/admin/courier-request/:requestId',

    builder: (context, state) {

      final requestId = state.pathParameters['requestId']!;

      final extraData = state.extra as Map<String, dynamic>?;

      return CourierRequestDetailPage(

        requestId: requestId,

        initialData: extraData,

      );

    },

  ),

  GoRoute(

    path: '/admin/craftsmen',

    builder: (context, state) => const CraftsmenAdminListPage(),

  ),

  GoRoute(

    path: '/admin/craftsmen/:craftsmanId',

    builder: (context, state) {

      final craftsmanId = state.pathParameters['craftsmanId']!;

      return CraftsmanAdminDetailPage(craftsmanId: craftsmanId);

    },

  ),

  GoRoute(
    path: '/admin/reports',
    builder: (context, state) => const admin_pages.ReportsListPage(),
  ),

  GoRoute(
    path: '/admin/reports/:reportId',
    builder: (context, state) {
      final report = state.extra as admin_models.UserReport;
      return admin_pages.ReportDetailPage(report: report);
    },
  ),

  GoRoute(

    path: '/admin/roles',

    builder: (context, state) => const AdminRolesPage(),

  ),

  GoRoute(

    path: '/admin/add-admin',

    builder: (context, state) => const AddAdminPage(),

  ),

  GoRoute(

    path: '/admin/deleted-accounts',

    builder: (context, state) => const DeletedAccountsPage(),

  ),

  GoRoute(

    path: '/admin/activity-logs',

    builder: (context, state) => const ActivityLogsPage(),

  ),

  // 🆕 نظام إدارة الأدمن الجديد - لوحة التحكم
  GoRoute(
    path: '/admin/management',
    builder: (context, state) => const admin_pages.AdminDashboardPage(),
  ),

  // 🆕 نظام إدارة الأدمن الجديد - قائمة البلاغات (user_reports)
  GoRoute(
    path: '/admin/user-reports',
    builder: (context, state) => const admin_pages.ReportsListPage(),
  ),

  // 🆕 نظام إدارة الأدمن الجديد - تفاصيل البلاغ
  GoRoute(
    path: '/admin/user-reports/:reportId',
    builder: (context, state) {
      final report = state.extra as admin_models.UserReport;
      return admin_pages.ReportDetailPage(report: report);
    },
  ),

  // 🆕 نظام إدارة الأدمن الجديد - قائمة المستخدمين
  GoRoute(
    path: '/admin/users-management',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>?;
      final initialTab = args?['tab'] ?? 0;
      return admin_pages.UsersListPage(initialTab: initialTab);
    },
  ),

  // 🆕 نظام إدارة الأدمن الجديد - تفاصيل المستخدم
  GoRoute(
    path: '/admin/user-management-detail',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return admin_pages.UserDetailPage(
        userId: args['userId'],
        userType: args['userType'],
      );
    },
  ),

];


