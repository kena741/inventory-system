import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/erp/enums.dart';
import '../../dashboard/bindings/dashboard_binding.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../more/views/more_view.dart';
import '../../orders/bindings/orders_binding.dart';
import '../../orders/views/orders_view.dart';
import '../../raw_material_requests/bindings/raw_material_requests_binding.dart';
import '../../raw_material_requests/views/raw_material_requests_view.dart';
import '../../raw_materials/bindings/raw_materials_binding.dart';
import '../../raw_materials/views/raw_materials_view.dart';
import '../../seller_performance/bindings/seller_performance_binding.dart';
import '../../seller_performance/views/seller_performance_view.dart';
import '../../tailor/bindings/tailor_binding.dart';
import '../../tailor/views/assigned_orders_view.dart';
import '../../tailor/views/tailor_performance_view.dart';
import '../../time_logs/bindings/time_logs_binding.dart';
import '../../time_logs/views/time_logs_view.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../profile/views/profile_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthController>();
      final role = parseUserRole(auth.currentUser.value?.role ?? controller.user.value?.role);
      final scheme = Theme.of(context).colorScheme;
      return _RoleShell(
        role: role,
        scheme: scheme,
        tabIndex: controller.tabIndex.value,
        onTabSelected: controller.setTab,
      );
    });
  }
}

class _RoleShell extends StatelessWidget {
  final UserRole role;
  final ColorScheme scheme;
  final int tabIndex;
  final ValueChanged<int> onTabSelected;

  const _RoleShell({
    required this.role,
    required this.scheme,
    required this.tabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final config = switch (role) {
      UserRole.admin => _adminConfig(),
      UserRole.manager => _managerConfig(),
      UserRole.qualityChecker => _managerConfig(),
      UserRole.seller => _sellerConfig(),
      UserRole.tailor => _tailorConfig(),
    };

    // Only reset when index is truly out of range (e.g., role changed).
    final safeIndex = (tabIndex >= 0 && tabIndex < config.pages.length) ? tabIndex : 0;
    if (safeIndex != tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onTabSelected(0));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(config.titleForIndex(safeIndex)),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              ProfileBinding().dependencies();
              Get.to(() => const _ProfilePage());
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              child: const Icon(Icons.person_outline, size: 18),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: safeIndex, children: config.pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onTabSelected,
        destinations: config.destinations,
      ),
    );
  }
}

typedef _TitleForIndex = String Function(int idx);

({List<Widget> pages, List<NavigationDestination> destinations, _TitleForIndex titleForIndex})
_adminConfig() {
  DashboardBinding().dependencies();
  OrdersBinding().dependencies();
  RawMaterialRequestsBinding().dependencies();
  RawMaterialsBinding().dependencies();
  return (
    pages: const [
      DashboardView(),
      RawMaterialsView(),
      OrdersView(),
      RawMaterialRequestsView(),
      MoreView(),
    ],
    destinations: const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Stock'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Requests'),
      NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
    ],
    titleForIndex: (idx) => switch (idx) {
      0 => 'Home',
      1 => 'Stock',
      2 => 'Orders',
      3 => 'Requests',
      _ => 'More',
    }
  );
}

({List<Widget> pages, List<NavigationDestination> destinations, _TitleForIndex titleForIndex})
_managerConfig() {
  OrdersBinding().dependencies();
  RawMaterialRequestsBinding().dependencies();
  RawMaterialsBinding().dependencies();
  return (
    pages: const [
      OrdersView(),
      RawMaterialsView(),
      RawMaterialRequestsView(),
      MoreView(),
    ],
    destinations: const [
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Stock'),
      NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Requests'),
      NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
    ],
    titleForIndex: (idx) => switch (idx) {
      0 => 'Orders',
      1 => 'Stock',
      2 => 'Requests',
      _ => 'More',
    }
  );
}

({List<Widget> pages, List<NavigationDestination> destinations, _TitleForIndex titleForIndex})
_sellerConfig() {
  OrdersBinding().dependencies();
  SellerPerformanceBinding().dependencies();
  RawMaterialRequestsBinding().dependencies();
  return (
    pages: const [
      OrdersView(),
      SellerPerformanceView(),
      RawMaterialRequestsView(),
    ],
    destinations: const [
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.query_stats_outlined), label: 'Performance'),
      NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Purchases'),
    ],
    titleForIndex: (idx) => switch (idx) {
      0 => 'Orders',
      1 => 'Performance',
      _ => 'Purchases',
    }
  );
}

({List<Widget> pages, List<NavigationDestination> destinations, _TitleForIndex titleForIndex})
_tailorConfig() {
  TailorBinding().dependencies();
  TimeLogsBinding().dependencies();
  return (
    pages: const [
      AssignedOrdersView(),
      TailorPerformanceView(),
      TimeLogsView(),
    ],
    destinations: const [
      NavigationDestination(icon: Icon(Icons.assignment_ind_outlined), label: 'Assigned'),
      NavigationDestination(icon: Icon(Icons.query_stats_outlined), label: 'Performance'),
      NavigationDestination(icon: Icon(Icons.access_time_outlined), label: 'Time'),
    ],
    titleForIndex: (idx) => switch (idx) {
      0 => 'Assigned Orders',
      1 => 'Performance',
      _ => 'Clock In/Out',
    }
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const ProfileView(),
    );
  }
}

