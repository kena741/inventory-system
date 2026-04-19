import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../orders/views/order_detail_view.dart';
import '../../../../core/services/erp_repository.dart';
import '../controllers/assigned_orders_controller.dart';

class AssignedOrdersView extends GetView<AssignedOrdersController> {
  const AssignedOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ErpRepository();
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return Center(child: Text(controller.error.value));
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAssigned,
        child: controller.orders.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.assignment_ind_outlined,
                      size: 56, color: scheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    'No assigned orders',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When a manager assigns orders, they will appear here.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: controller.orders.length,
                itemBuilder: (context, i) {
                  final o = controller.orders[i];
                  final statusRaw = (o['status']?.toString() ?? 'pending').trim();
                  final status = statusRaw.replaceAll('_', ' ');
                  final qty = (o['quantity'] as int?) ?? 0;
                  final cloth = (o['cloth_code']?.toString() ?? '').trim();
                  final delivery = (o['delivery_date']?.toString() ?? '').trim();
                  final managerId = (o['manager_id'] as String?) ?? '';

                  final statusColor = switch (statusRaw) {
                    'completed' => Colors.green.shade700,
                    'cancelled' => Colors.red.shade700,
                    'in_progress' => Colors.orange.shade700,
                    _ => scheme.primary,
                  };

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Get.to(() => OrderDetailView(order: o)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    o['customer_name']?.toString() ?? 'Customer',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaChip(
                                  icon: Icons.confirmation_number_outlined,
                                  text: 'Qty $qty',
                                  color: scheme.primary,
                                ),
                                if (cloth.isNotEmpty)
                                  _MetaChip(
                                    icon: Icons.qr_code_2_outlined,
                                    text: cloth,
                                    color: Colors.blueGrey,
                                  ),
                                if (delivery.isNotEmpty)
                                  _MetaChip(
                                    icon: Icons.calendar_month_outlined,
                                    text: _dateOnly(delivery),
                                    color: Colors.teal.shade700,
                                  ),
                              ],
                            ),
                            if (managerId.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 18, color: scheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<String?>(
                                      future: repo.getUserDisplayNameById(managerId),
                                      builder: (context, snap) {
                                        final name = (snap.data ?? '').trim();
                                        return Text(
                                          'Assigned by: ${name.isEmpty ? 'Manager' : name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  static String _dateOnly(String v) {
    final s = v.trim();
    final dateOnly = RegExp(r'^\\d{4}-\\d{2}-\\d{2}$');
    if (dateOnly.hasMatch(s)) return s;
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

