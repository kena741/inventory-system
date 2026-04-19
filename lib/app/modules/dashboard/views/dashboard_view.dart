import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  static String _fmtMoney(num v) {
    final a = v.abs();
    if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (a >= 1e4) return '${(v / 1e3).toStringAsFixed(1)}k';
    if (v == v.round()) return v.round().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              controller.error.value,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pull to refresh · key numbers across the business',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Customer orders'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'Total orders',
                  value: controller.ordersTotal.value.toString(),
                  icon: Icons.assignment_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Active',
                  value:
                      '${controller.ordersPending.value + controller.ordersInProgress.value}',
                  subtitle:
                      '${controller.ordersPending.value} pending · ${controller.ordersInProgress.value} in progress',
                  icon: Icons.pending_actions_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Completed',
                  value: controller.ordersCompleted.value.toString(),
                  icon: Icons.check_circle_outline,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Outstanding',
                  value: _fmtMoney(controller.ordersOutstanding.value),
                  subtitle: 'Remaining payments',
                  icon: Icons.account_balance_wallet_outlined,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Raw materials'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'SKUs',
                  value: controller.rawMaterialsCount.value.toString(),
                  icon: Icons.inventory_2_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Book value',
                  value: _fmtMoney(controller.rawInventoryValue.value),
                  subtitle: 'Sum of total_price',
                  icon: Icons.payments_outlined,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Purchase requests'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'All requests',
                  value: controller.rawRequestsTotal.value.toString(),
                  icon: Icons.playlist_add_check_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Awaiting PO',
                  value: controller.rawRequestsPendingAdmin.value.toString(),
                  subtitle: 'Pending admin approval',
                  icon: Icons.gavel_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'In pipeline',
                  value: controller.rawRequestsInPipeline.value.toString(),
                  subtitle: 'After approval, before receipt',
                  icon: Icons.timeline_outlined,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Operations'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'Locations',
                  value: controller.locationsCount.value.toString(),
                  icon: Icons.location_on_outlined,
                  scheme: scheme,
                ),
                _StatCard(
                  title: 'Expenses (month)',
                  value: _fmtMoney(controller.expensesThisMonth.value),
                  subtitle: '${controller.expensesCount.value} records total',
                  icon: Icons.receipt_long_outlined,
                  scheme: scheme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Use the bottom tabs for Stock, Orders, and Requests. Open More for raw materials, expenses, and users.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final ColorScheme scheme;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!.trim(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
