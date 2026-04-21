import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/erp/enums.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/order_detail_controller.dart';
import '../../../../core/services/erp_repository.dart';

class OrderDetailView extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  late Map<String, dynamic> order;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'] as String;
    final quantity = (order['quantity'] as int?) ?? 0;
    final controller =
        Get.put(OrderDetailController(orderId: orderId, quantity: quantity), tag: orderId);
    final scheme = Theme.of(context).colorScheme;
    final role = parseUserRole(Get.find<AuthController>().currentUser.value?.role);
    final canAssignTailor = role == UserRole.admin ||
        role == UserRole.manager ||
        role == UserRole.qualityChecker;
    final isTailor = role == UserRole.tailor;
    final currentUserId = Get.find<AuthController>().currentUser.value?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(order['customer_name']?.toString() ?? 'Order'),
        actions: [
          if (canAssignTailor)
            IconButton(
              tooltip: 'Assign tailor',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () async {
                final selected = await _showAssignTailor(context, orderId);
                if (selected != null) {
                  setState(() => order['tailor_id'] = selected);
                }
              },
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        if (controller.order.isNotEmpty) {
          order = Map<String, dynamic>.from(controller.order);
        }
        final byIndex = <int, Map<String, dynamic>>{};
        for (final m in controller.measurements) {
          final idx = (m['item_index'] as int?) ?? -1;
          if (idx > 0) byIndex[idx] = m;
        }
        return RefreshIndicator(
          onRefresh: controller.refreshMeasurements,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OrderHeader(order: order, showPayments: !isTailor),
              const SizedBox(height: 12),
              if (!isTailor)
                _QualityCheckCard(
                  role: role,
                  controller: controller,
                  order: order,
                  qc: controller.qualityCheck,
                ),
              if (!isTailor) const SizedBox(height: 12),
              if (role == UserRole.seller &&
                  (order['status']?.toString() ?? '').trim().toLowerCase() ==
                      'completed')
                _SellerDeliveryCard(controller: controller),
              if (role == UserRole.seller &&
                  (order['status']?.toString() ?? '').trim().toLowerCase() ==
                      'completed')
                const SizedBox(height: 12),
              if (!isTailor &&
                  (order['status']?.toString().trim().toLowerCase() ??
                          '') ==
                      'completed')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FinalPaymentMethodSection(
                    controller: controller,
                    order: order,
                  ),
                ),
              if (isTailor) _AssignedByCard(order: order),
              if (isTailor) const SizedBox(height: 12),
              if (isTailor &&
                  ((order['tailor_id']?.toString() ?? '').trim() == currentUserId))
                _TailorStatusCard(
                  currentStatus: (order['status']?.toString() ?? 'pending').trim(),
                  onUpdate: controller.updateOrderStatus,
                ),
              if (isTailor &&
                  ((order['tailor_id']?.toString() ?? '').trim() == currentUserId))
                const SizedBox(height: 12),
              if (canAssignTailor)
                _AssignmentCard(
                  order: order,
                  onChange: () async {
                    final selected = await _showAssignTailor(context, orderId);
                    if (selected != null) {
                      setState(() => order['tailor_id'] = selected);
                    }
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Measurements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Qty $quantity',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (quantity <= 0)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: Text('Quantity is 0')),
                )
              else
                for (var i = 1; i <= quantity; i++)
                  _MeasurementCard(
                    index: i,
                    m: byIndex[i],
                    onEdit: () => _showEditMeasurement(
                      context,
                      controller,
                      byIndex[i],
                      i,
                    ),
                  ),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showEditMeasurement(
    BuildContext context,
    OrderDetailController controller,
    Map<String, dynamic>? m,
    int index,
  ) async {
    final measurementId = (m?['id'] as String?) ?? '';
    final labelCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final heightCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final hipCtrl = TextEditingController();
    final shoulderCtrl = TextEditingController();
    final sleeveCtrl = TextEditingController();
    final neckCtrl = TextEditingController();
    final inseamCtrl = TextEditingController();
    final thighCtrl = TextEditingController();
    final calfCtrl = TextEditingController();

    labelCtrl.text = (m?['customer_label']?.toString() ?? '');
    notesCtrl.text = (m?['notes']?.toString() ?? '');
    heightCtrl.text = (m?['height']?.toString() ?? '');
    chestCtrl.text = (m?['chest']?.toString() ?? '');
    waistCtrl.text = (m?['waist']?.toString() ?? '');
    hipCtrl.text = (m?['hip']?.toString() ?? '');
    shoulderCtrl.text = (m?['shoulder']?.toString() ?? '');
    sleeveCtrl.text = (m?['sleeve_length']?.toString() ?? '');
    neckCtrl.text = (m?['neck']?.toString() ?? '');
    inseamCtrl.text = (m?['inseam']?.toString() ?? '');
    thighCtrl.text = (m?['thigh']?.toString() ?? '');
    calfCtrl.text = (m?['calf']?.toString() ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Item $index measurements',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: labelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Customer label',
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fields = [
                              _NumField(label: 'Height', ctrl: heightCtrl),
                              _NumField(label: 'Chest', ctrl: chestCtrl),
                              _NumField(label: 'Waist', ctrl: waistCtrl),
                              _NumField(label: 'Hip', ctrl: hipCtrl),
                              _NumField(label: 'Shoulder', ctrl: shoulderCtrl),
                              _NumField(label: 'Sleeve length', ctrl: sleeveCtrl),
                              _NumField(label: 'Neck', ctrl: neckCtrl),
                              _NumField(label: 'Inseam', ctrl: inseamCtrl),
                              _NumField(label: 'Thigh', ctrl: thighCtrl),
                              _NumField(label: 'Calf', ctrl: calfCtrl),
                            ];
                            final isWide = constraints.maxWidth >= 420;
                            if (!isWide) return Column(children: fields);
                            final itemWidth = (constraints.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 0,
                              children: [
                                for (final f in fields)
                                  SizedBox(width: itemWidth, child: f),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                            ),
                            onPressed: () async {
                              final payload = (
                                customerLabel: labelCtrl.text.trim().isEmpty
                                    ? null
                                    : labelCtrl.text.trim(),
                                height: num.tryParse(heightCtrl.text.trim()),
                                chest: num.tryParse(chestCtrl.text.trim()),
                                waist: num.tryParse(waistCtrl.text.trim()),
                                hip: num.tryParse(hipCtrl.text.trim()),
                                shoulder: num.tryParse(shoulderCtrl.text.trim()),
                                sleeveLength: num.tryParse(sleeveCtrl.text.trim()),
                                neck: num.tryParse(neckCtrl.text.trim()),
                                inseam: num.tryParse(inseamCtrl.text.trim()),
                                thigh: num.tryParse(thighCtrl.text.trim()),
                                calf: num.tryParse(calfCtrl.text.trim()),
                                notes: notesCtrl.text.trim().isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                              );

                              if (measurementId.isEmpty) {
                                await controller.saveMeasurementForItem(
                                  itemIndex: index,
                                  customerLabel: payload.customerLabel,
                                  height: payload.height,
                                  chest: payload.chest,
                                  waist: payload.waist,
                                  hip: payload.hip,
                                  shoulder: payload.shoulder,
                                  sleeveLength: payload.sleeveLength,
                                  neck: payload.neck,
                                  inseam: payload.inseam,
                                  thigh: payload.thigh,
                                  calf: payload.calf,
                                  notes: payload.notes,
                                );
                              } else {
                                await controller.saveMeasurement(
                                  measurementId: measurementId,
                                  customerLabel: payload.customerLabel,
                                  height: payload.height,
                                  chest: payload.chest,
                                  waist: payload.waist,
                                  hip: payload.hip,
                                  shoulder: payload.shoulder,
                                  sleeveLength: payload.sleeveLength,
                                  neck: payload.neck,
                                  inseam: payload.inseam,
                                  thigh: payload.thigh,
                                  calf: payload.calf,
                                  notes: payload.notes,
                                );
                              }

                              if (context.mounted) Navigator.of(context).pop();
                            },
                            child: const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showAssignTailor(BuildContext context, String orderId) async {
    final repo = ErpRepository();
    String? result;
    await showDialog<void>(
      context: context,
      builder: (_) {
        String? selectedId = (order['tailor_id'] as String?);
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: repo.listTailors(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const AlertDialog(
                title: Text('Assign tailor'),
                content: SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final tailors = snap.data ?? <Map<String, dynamic>>[];
            return AlertDialog(
              title: const Text('Assign tailor'),
              content: DropdownButtonFormField<String>(
                value: selectedId,
                items: [
                  for (final t in tailors)
                    DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text(
                        [
                          (t['first_name']?.toString() ?? '').trim(),
                          (t['last_name']?.toString() ?? '').trim(),
                        ].where((e) => e.isNotEmpty).join(' ').trim().isEmpty
                            ? 'Tailor'
                            : [
                                (t['first_name']?.toString() ?? '').trim(),
                                (t['last_name']?.toString() ?? '').trim(),
                              ].where((e) => e.isNotEmpty).join(' '),
                      ),
                    ),
                ],
                onChanged: (v) => selectedId = v,
                decoration: const InputDecoration(labelText: 'Tailor'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (selectedId == null) return;
                    await repo.assignOrderToTailor(
                      orderId: orderId,
                      tailorId: selectedId!,
                    );
                    result = selectedId;
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChange;

  const _AssignmentCard({
    required this.order,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ErpRepository();
    final assignedId = (order['tailor_id'] as String?) ?? '';
    final hasTailor = assignedId.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              foregroundColor: scheme.primary,
              child: const Icon(Icons.assignment_ind_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tailor assignment',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  if (!hasTailor)
                    Text(
                      'Not assigned',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  else
                    FutureBuilder<String?>(
                      future: repo.getUserDisplayNameById(assignedId),
                      builder: (context, snap) {
                        final name = (snap.data ?? '').trim();
                        return Text(
                          name.isEmpty ? 'Assigned' : name,
                          style: Theme.of(context).textTheme.titleMedium,
                        );
                      },
                    ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.swap_horiz),
              label: Text(hasTailor ? 'Change' : 'Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool showPayments;
  const _OrderHeader({required this.order, required this.showPayments});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusRaw = (order['status']?.toString() ?? 'pending').trim();
    final status = statusRaw.replaceAll('_', ' ');
    final cloth = (order['cloth_code']?.toString() ?? '').trim();
    final addr = (order['customer_address'] ?? '').toString().trim();
    final phone = (order['customer_number'] ?? '').toString().trim();
    final interest = (order['customer_interest'] ?? '').toString().trim();
    final initPayType =
        (order['initial_payment_payment_type'] ?? '').toString().trim();
    final paid = (order['initial_payment'] as num?) ?? 0;
    final remaining = (order['remaining_payment'] as num?) ?? 0;
    final total = order['total_amount'] as num?;
    final orderDate = _tryParseDate(order['order_date']);
    final deliveryDate = _tryParseDate(order['delivery_date']);

    final progress = showPayments && (total != null && total > 0)
        ? (paid / total).clamp(0, 1).toDouble()
        : null;

    final statusColor = switch (statusRaw) {
      'completed' => Colors.green.shade700,
      'delivered' => Colors.green.shade700,
      'cancelled' => Colors.red.shade700,
      'in_progress' => Colors.orange.shade700,
      _ => scheme.primary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (cloth.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Cloth code: $cloth',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (addr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Address: $addr',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Phone: $phone',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (interest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Interest: $interest',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 14),
          if (showPayments) ...[
            Row(
              children: [
                _Metric(
                  label: initPayType.isEmpty
                      ? 'Paid'
                      : 'Paid (${initPayType.toLowerCase() == 'bank' ? 'Bank' : 'Cash'})',
                  value: paid.toString(),
                ),
                const SizedBox(width: 12),
                _Metric(label: 'Remaining', value: remaining.toString()),
                const SizedBox(width: 12),
                _Metric(label: 'Total', value: total?.toString() ?? '—'),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  color: scheme.primary,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateLine(
                  label: 'Order date',
                  value: orderDate ?? '—',
                  icon: Icons.event_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateLine(
                  label: 'Delivery date',
                  value: deliveryDate ?? '—',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
            ],
          ),
          if ((order['description']?.toString() ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              order['description'].toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String? _tryParseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // If it's already yyyy-mm-dd, keep it.
    final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateOnly.hasMatch(s)) return s;
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _FinalPaymentMethodSection extends StatefulWidget {
  final OrderDetailController controller;
  final Map<String, dynamic> order;

  const _FinalPaymentMethodSection({
    required this.controller,
    required this.order,
  });

  @override
  State<_FinalPaymentMethodSection> createState() =>
      _FinalPaymentMethodSectionState();
}

class _FinalPaymentMethodSectionState extends State<_FinalPaymentMethodSection> {
  String _selected = 'cash';

  static String _channelLabel(String raw) =>
      raw.trim().toLowerCase() == 'bank' ? 'Bank' : 'Cash';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final raw =
        (widget.order['final_payment_payment_type'] ?? '').toString().trim();

    if (raw.isNotEmpty) {
      return Card(
        child: ListTile(
          leading:
              Icon(Icons.account_balance_wallet_outlined, color: scheme.primary),
          title: const Text('Final payment'),
          subtitle: Text('Received via ${_channelLabel(raw)}'),
        ),
      );
    }

    InputDecoration compact(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Final payment method',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order is completed — record how the balance was received.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selected,
              decoration: compact('Final payment via'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
              ],
              onChanged: (v) => setState(() => _selected = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await widget.controller
                      .setFinalPaymentPaymentType(_selected);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedByCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _AssignedByCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ErpRepository();
    final managerId = (order['manager_id'] as String?) ?? '';
    if (managerId.trim().isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              foregroundColor: scheme.primary,
              child: const Icon(Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assigned by',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  FutureBuilder<String?>(
                    future: repo.getUserDisplayNameById(managerId),
                    builder: (context, snap) {
                      final name = (snap.data ?? '').trim();
                      return Text(
                        name.isEmpty ? 'Manager' : name,
                        style: Theme.of(context).textTheme.titleMedium,
                      );
                    },
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

class _TailorStatusCard extends StatelessWidget {
  final String currentStatus;
  final Future<void> Function(String status) onUpdate;

  const _TailorStatusCard({
    required this.currentStatus,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var selected = currentStatus.isEmpty ? 'pending' : currentStatus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: const Icon(Icons.sync_alt_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update status',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        selected.replaceAll('_', ' '),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) {
                return DropdownButtonFormField<String>(
                  value: selected,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In progress'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (v) => setState(() => selected = v ?? selected),
                  decoration: const InputDecoration(labelText: 'Status'),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onUpdate(selected),
                child: const Text('Save status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerDeliveryCard extends StatelessWidget {
  final OrderDetailController controller;
  const _SellerDeliveryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: const Icon(Icons.local_shipping_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to deliver',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark delivered'),
                onPressed: () => controller.updateOrderStatus('delivered'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityCheckCard extends StatelessWidget {
  final UserRole role;
  final OrderDetailController controller;
  final Map<String, dynamic> order;
  final Map<String, dynamic> qc;

  const _QualityCheckCard({
    required this.role,
    required this.controller,
    required this.order,
    required this.qc,
  });

  bool get _canRequest {
    if (role != UserRole.manager) return false;
    final s = (qc['status']?.toString() ?? '').trim().toLowerCase();
    return s != 'passed';
  }

  bool _qcRequested(Map<String, dynamic> qc) {
    final s = (qc['status']?.toString() ?? '').trim().toLowerCase();
    return s == 'pending';
  }

  bool get _canSubmit => role == UserRole.qualityChecker && _qcRequested(qc);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ErpRepository();
    final orderStatus = (order['status']?.toString() ?? 'pending').trim();
    final qcStatus = (qc['status']?.toString() ?? '').trim();
    final qcLabel = qcStatus.isEmpty ? 'Not requested' : qcStatus.replaceAll('_', ' ');
    final checkerId = (qc['checker_id']?.toString() ?? '').trim();
    final qcPassed = qcStatus.trim().toLowerCase() == 'passed';
    final orderStatusLc = orderStatus.trim().toLowerCase();
    final canManagerComplete = qcPassed &&
        orderStatusLc != 'completed' &&
        orderStatusLc != 'delivered' &&
        orderStatusLc != 'cancelled';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  child: const Icon(Icons.verified_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quality check',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        qcLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (checkerId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        FutureBuilder<String?>(
                          future: repo.getUserDisplayNameById(checkerId),
                          builder: (context, snap) {
                            final name = (snap.data ?? '').trim();
                            return Text(
                              name.isEmpty ? 'Quality checker' : name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (orderStatus.toLowerCase() == 'ready_for_seller')
                  Chip(
                    label: const Text('Sent to seller'),
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                    side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
                  ),
              ],
            ),
            if (qcStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QcKV(
                      k: 'Embroidery',
                      v: (qc['embroidery_level']?.toString() ?? '—'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QcKV(
                      k: 'Decoration',
                      v: (qc['decoration_level']?.toString() ?? '—'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QcKV(
                      k: 'Geber',
                      v: (qc['geber_level']?.toString() ?? '—'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (role == UserRole.manager && canManagerComplete) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QC passed',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'You can now mark this order as done (completed) so the seller can deliver it.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.task_alt_outlined),
                        label: const Text('Mark done (Completed)'),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Mark order completed'),
                              content: const Text(
                                'This will set the order status to completed so the seller can mark it as delivered.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          await controller.updateOrderStatus('completed');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_canRequest)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('Request QC'),
                  onPressed: () async {
                    String? selectedId;
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: repo.listQualityCheckers(),
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const AlertDialog(
                                title: Text('Request QC'),
                                content: SizedBox(
                                  height: 90,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              );
                            }
                            final users = snap.data ?? <Map<String, dynamic>>[];
                            if (users.isNotEmpty && selectedId == null) {
                              selectedId = users.first['id']?.toString();
                            }
                            return AlertDialog(
                              title: const Text('Request QC'),
                              content: DropdownButtonFormField<String>(
                                value: selectedId,
                                decoration: const InputDecoration(
                                  labelText: 'Quality checker',
                                ),
                                items: [
                                  for (final u in users)
                                    DropdownMenuItem(
                                      value: u['id']?.toString(),
                                      child: Text(
                                        [
                                          (u['first_name']?.toString() ?? '').trim(),
                                          (u['last_name']?.toString() ?? '').trim(),
                                        ].where((e) => e.isNotEmpty).join(' ').trim().isEmpty
                                            ? 'Quality checker'
                                            : [
                                                (u['first_name']?.toString() ?? '').trim(),
                                                (u['last_name']?.toString() ?? '').trim(),
                                              ].where((e) => e.isNotEmpty).join(' '),
                                      ),
                                    ),
                                ],
                                onChanged: (v) => selectedId = v,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: users.isEmpty
                                      ? null
                                      : () => Navigator.of(ctx).pop(),
                                  child: const Text('Next'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                    if (selectedId == null || selectedId!.trim().isEmpty) return;
                    await controller.requestQualityCheck(checkerId: selectedId!);
                  },
                ),
              ),
            if (_canSubmit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: const Text('Submit QC result'),
                  onPressed: () async {
                    final notesCtrl = TextEditingController();
                    var embroidery = (qc['embroidery_level'] as int?) ?? 0;
                    var decoration = (qc['decoration_level'] as int?) ?? 0;
                    var geber = (qc['geber_level'] as int?) ?? 0;
                    String selected = 'passed';
                    final embroideryCtrl =
                        TextEditingController(text: embroidery == 0 ? '' : embroidery.toString());
                    final decorationCtrl =
                        TextEditingController(text: decoration == 0 ? '' : decoration.toString());
                    final geberCtrl =
                        TextEditingController(text: geber == 0 ? '' : geber.toString());

                    await showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            int clamp05(String raw) {
                              final v = int.tryParse(raw.trim()) ?? 0;
                              if (v < 0) return 0;
                              if (v > 5) return 5;
                              return v;
                            }

                            int? parse05OrNull(String raw) {
                              final s = raw.trim();
                              if (s.isEmpty) return null;
                              return clamp05(s);
                            }

                            return AlertDialog(
                              title: const Text('Quality check'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: selected,
                                      decoration: const InputDecoration(
                                        labelText: 'Decision',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'passed', child: Text('Passed')),
                                        DropdownMenuItem(
                                            value: 'rework', child: Text('Needs rework')),
                                        DropdownMenuItem(
                                            value: 'failed', child: Text('Failed')),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => selected = v ?? selected),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: embroideryCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Embroidery',
                                      ),
                                      onChanged: (v) => setState(() {
                                        embroidery = clamp05(v);
                                      }),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: decorationCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Decoration',
                                      ),
                                      onChanged: (v) => setState(() {
                                        decoration = clamp05(v);
                                      }),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: geberCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Geber',
                                      ),
                                      onChanged: (v) => setState(() {
                                        geber = clamp05(v);
                                      }),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: notesCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Notes',
                                      ),
                                      minLines: 2,
                                      maxLines: 4,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    final checkerId = Get.find<AuthController>()
                                            .currentUser
                                            .value
                                            ?.id ??
                                        '';
                                    await controller.submitQualityCheck(
                                      status: selected,
                                      checkerId: checkerId,
                                      embroideryLevel:
                                          parse05OrNull(embroideryCtrl.text),
                                      decorationLevel:
                                          parse05OrNull(decorationCtrl.text),
                                      geberLevel: parse05OrNull(geberCtrl.text),
                                      notes: notesCtrl.text.trim(),
                                    );
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Submit'),
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
          ],
        ),
      ),
    );
  }
}

class _QcKV extends StatelessWidget {
  final String k;
  final String v;

  const _QcKV({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            v,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic>? m;
  final VoidCallback onEdit;

  const _MeasurementCard({
    required this.index,
    required this.m,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = (m?['customer_label']?.toString() ?? '').trim();
    final title = label.isEmpty ? 'Item $index' : 'Item $index • $label';
    final filled = _filledCount(m);
    final total = 10; // number of numeric fields we show
    final hasAny = filled > 0 || (m?['notes']?.toString() ?? '').trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '$filled/$total',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasAny)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'No measurements yet. Tap Edit to add.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _chip('Height', m?['height']),
                  _chip('Chest', m?['chest']),
                  _chip('Waist', m?['waist']),
                  _chip('Hip', m?['hip']),
                  _chip('Shoulder', m?['shoulder']),
                  _chip('Sleeve', m?['sleeve_length']),
                  _chip('Neck', m?['neck']),
                  _chip('Inseam', m?['inseam']),
                  _chip('Thigh', m?['thigh']),
                  _chip('Calf', m?['calf']),
                ],
              ),
            if ((m?['notes']?.toString() ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(m!['notes'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  int _filledCount(Map<String, dynamic>? m) {
    if (m == null) return 0;
    final keys = const [
      'height',
      'chest',
      'waist',
      'hip',
      'shoulder',
      'sleeve_length',
      'neck',
      'inseam',
      'thigh',
      'calf',
    ];
    var count = 0;
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) count++;
    }
    return count;
  }

  Widget _chip(String label, dynamic v) {
    if (v == null) return const SizedBox.shrink();
    return Chip(label: Text('$label: $v'));
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _NumField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DateLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

