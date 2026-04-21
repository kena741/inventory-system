import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/erp/enums.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../expenses/bindings/expenses_binding.dart';
import '../../expenses/views/expenses_view.dart';
import '../../locations/bindings/locations_binding.dart';
import '../../locations/views/locations_view.dart';
import '../../tailor/controllers/admin_tailor_team_performance_controller.dart';
import '../../tailor/views/admin_tailor_team_performance_view.dart';
import '../../user_management/views/role_users_view.dart';
import '../../vendors/bindings/vendors_binding.dart';
import '../../vendors/views/vendors_view.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = parseUserRole(
          Get.find<AuthController>().currentUser.value?.role,
        ) ==
        UserRole.admin;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _SectionHeader(title: 'Management'),
        _SettingsCard(
          children: [            
            _SettingsTile(
              title: 'Expenses',
              subtitle: 'Track operational expenses',
              icon: Icons.receipt_long_outlined,
              onTap: () {
                ExpensesBinding().dependencies();
                Get.to(() => const ExpensesView());
              },
            ),
            const _TileDivider(),
            _SettingsTile(
              title: 'Locations',
              subtitle: 'Manage locations',
              icon: Icons.location_on_outlined,
              onTap: () {
                LocationsBinding().dependencies();
                Get.to(
                  () => Scaffold(
                    appBar: AppBar(title: const Text('Locations')),
                    body: const LocationsView(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Users'),
        _SettingsCard(
          children: [
            _SettingsTile(
              title: 'Tailors',
              subtitle: 'Manage tailor accounts',
              icon: Icons.design_services_outlined,
              onTap: () {
                Get.to(() => const RoleUsersView(role: 'tailor'));
              },
            ),
            if (isAdmin) ...[
              const _TileDivider(),
              _SettingsTile(
                title: 'Vendors',
                subtitle: 'Add, edit, and delete vendors',
                icon: Icons.store_outlined,
                onTap: () {
                  VendorsBinding().dependencies();
                  Get.to(() => const VendorsView());
                },
              ),
            ],
            const _TileDivider(),
            _SettingsTile(
              title: 'Sellers',
              subtitle: 'Manage seller accounts',
              icon: Icons.storefront_outlined,
              onTap: () {
                Get.to(() => const RoleUsersView(role: 'seller'));
              },
            ),
            const _TileDivider(),
            _SettingsTile(
              title: 'Managers',
              subtitle: 'Manage manager accounts',
              icon: Icons.manage_accounts_outlined,
              onTap: () {
                Get.to(() => const RoleUsersView(role: 'manager'));
              },
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Performance'),
          _SettingsCard(
            children: [
              _SettingsTile(
                title: 'Tailor team performance',
                subtitle: 'Week grid · deliveries per tailor',
                icon: Icons.calendar_view_month_outlined,
                onTap: () {
                  if (Get.isRegistered<AdminTailorTeamPerformanceController>()) {
                    Get.delete<AdminTailorTeamPerformanceController>();
                  }
                  Get.put(AdminTailorTeamPerformanceController());
                  Get.to(() => const AdminTailorTeamPerformanceView());
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        const _SectionHeader(title: 'About'),
        _SettingsCard(
          children: [
            _SettingsTile(
              title: 'App info',
              subtitle: 'Version and legal',
              icon: Icons.info_outline,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Zulu Inventory',
                  applicationIcon: Icon(
                    Icons.inventory_2_outlined,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
      ),
      onTap: onTap,
    );
  }
}

