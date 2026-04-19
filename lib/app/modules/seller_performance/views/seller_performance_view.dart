import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/seller_performance_controller.dart';

class SellerPerformanceView extends GetView<SellerPerformanceController> {
  const SellerPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return Center(child: Text(controller.error.value));
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: const Icon(Icons.trending_up_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales performance',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Orders created & payments collected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PerformanceRange>(
              segments: const [
                ButtonSegment(value: PerformanceRange.day, label: Text('Day')),
                ButtonSegment(value: PerformanceRange.week, label: Text('Week')),
                ButtonSegment(value: PerformanceRange.month, label: Text('Month')),
              ],
              selected: {controller.range.value},
              onSelectionChanged: (s) => controller.setRange(s.first),
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Orders',
              value: controller.ordersCount.value.toString(),
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: 10),
            _MetricCard(
              title: 'Paid amount',
              value: controller.totalPaid.value.toString(),
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 14),
            Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (controller.ordersByDay.isEmpty)
              const Text('No orders in this period')
            else
              ...controller.ordersByDay.map((e) {
                final paidEntry = controller.paidByDay
                    .firstWhereOrNull((p) => p.key == e.key);
                final paid = paidEntry?.value ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(e.key),
                    subtitle: Text('Paid: $paid'),
                    trailing: Text(
                      e.value.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              foregroundColor: scheme.primary,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

