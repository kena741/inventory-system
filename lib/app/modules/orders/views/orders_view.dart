import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/orders_controller.dart';
import 'order_detail_view.dart';

class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_orders',
        onPressed: () => _showCreateOrder(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        return RefreshIndicator(
          onRefresh: controller.refreshOrders,
          child: controller.orders.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('No orders yet')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.orders.length,
                  itemBuilder: (context, index) {
                    final o = controller.orders[index];
                    final name = o['customer_name']?.toString() ?? 'Customer';
                    final statusRaw = (o['status']?.toString() ?? 'pending').trim();
                    final status = statusRaw.replaceAll('_', ' ');
                    final qty = (o['quantity'] as int?) ?? 0;
                    final paid = (o['initial_payment'] as num?) ?? 0;
                    final remaining = (o['remaining_payment'] as num?) ?? 0;
                    final total = (o['total_amount'] as num?) ?? (paid + remaining);
                    final cloth = (o['cloth_code']?.toString() ?? '').trim();
                    final delivery = (o['delivery_date']?.toString() ?? '').trim();

                    final progress =
                        total > 0 ? (paid / total).clamp(0, 1).toDouble() : 0.0;
                    final statusColor = switch (statusRaw) {
                      'completed' => Colors.green.shade700,
                      'cancelled' => Colors.red.shade700,
                      'in_progress' => Colors.orange.shade700,
                      _ => scheme.primary,
                    };

                    return _OrderCard(
                      scheme: scheme,
                      name: name,
                      status: status,
                      statusColor: statusColor,
                      cloth: cloth,
                      qty: qty,
                      paid: paid,
                      remaining: remaining,
                      total: total,
                      progress: progress,
                      deliveryDate: delivery,
                      onTap: () => Get.to(() => OrderDetailView(order: o)),
                    );
                  },
                ),
        );
      }),
    );
  }

  Future<void> _showCreateOrder(BuildContext context) async {
    final customerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final interestCtrl = TextEditingController();
    final clothCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final initPayCtrl = TextEditingController(text: '0');
    final remainPayCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    DateTime? deliveryDate;
    var initialPaymentPaymentType = 'cash';

    var disposed = false;
    void disposeAll() {
      if (disposed) return;
      disposed = true;
      customerCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      interestCtrl.dispose();
      clothCtrl.dispose();
      qtyCtrl.dispose();
      initPayCtrl.dispose();
      remainPayCtrl.dispose();
      descCtrl.dispose();
    }

    InputDecoration compactField(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );

    await showDialog<void>(
      context: context,
      builder: (dCtx) {
        final scheme = Theme.of(dCtx).colorScheme;
        return StatefulBuilder(
          builder: (context, setLocal) {
            num orderTotal() {
              final i = num.tryParse(initPayCtrl.text.trim()) ?? 0;
              final r = num.tryParse(remainPayCtrl.text.trim()) ?? 0;
              return i + r;
            }

            String orderTotalLabel() {
              final t = orderTotal();
              if (t % 1 == 0) return t.toInt().toString();
              final s = t.toStringAsFixed(2);
              if (s.endsWith('0')) {
                return t.toString();
              }
              return s;
            }

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              title: Text(
                'New order',
                style: Theme.of(dCtx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              content: Theme(
                data: Theme.of(dCtx).copyWith(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'New orders start as pending. Fields match the receipt form style.',
                          style: Theme.of(dCtx).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: customerCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: compactField('Name *'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: compactField('Phone'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: compactField('Address'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: interestCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: compactField('Interest'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: clothCtrl,
                          decoration: compactField('Cloth code'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: compactField('Quantity *'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: initPayCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: compactField('Initial payment'),
                                onChanged: (_) => setLocal(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: initialPaymentPaymentType,
                                decoration: compactField('Initial paid via'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'cash',
                                    child: Text('Cash'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'bank',
                                    child: Text('Bank'),
                                  ),
                                ],
                                onChanged: (v) => setLocal(
                                  () => initialPaymentPaymentType =
                                      v ?? 'cash',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: remainPayCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: compactField('Remaining payment'),
                                onChanged: (_) => setLocal(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InputDecorator(
                                decoration: compactField(
                                  'Total (initial + remaining)',
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    orderTotalLabel(),
                                    style: Theme.of(dCtx)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final picked = await showDatePicker(
                              context: dCtx,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: deliveryDate ?? DateTime.now(),
                            );
                            if (picked != null) {
                              setLocal(() => deliveryDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: Text(
                            deliveryDate == null
                                ? 'Delivery date'
                                : '${deliveryDate!.year}-${deliveryDate!.month.toString().padLeft(2, '0')}-${deliveryDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          decoration: compactField('Description'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dCtx).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final customer = customerCtrl.text.trim();
                    if (customer.isEmpty) return;
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                    if (qty <= 0) return;

                    await controller.createOrder(
                      customerName: customer,
                      clothCode: clothCtrl.text.trim().isEmpty
                          ? null
                          : clothCtrl.text.trim(),
                      quantity: qty,
                      initialPayment:
                          num.tryParse(initPayCtrl.text.trim()) ?? 0,
                      remainingPayment:
                          num.tryParse(remainPayCtrl.text.trim()) ?? 0,
                      totalAmount: orderTotal(),
                      deliveryDate: deliveryDate,
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      status: 'pending',
                      customerInterest: interestCtrl.text.trim().isEmpty
                          ? null
                          : interestCtrl.text.trim(),
                      customerAddress: addressCtrl.text.trim().isEmpty
                          ? null
                          : addressCtrl.text.trim(),
                      customerNumber: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      initialPaymentPaymentType: initialPaymentPaymentType,
                    );
                    if (dCtx.mounted) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(dCtx).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => disposeAll());
    });
  }
}

class _OrderCard extends StatelessWidget {
  final ColorScheme scheme;
  final String name;
  final String status;
  final Color statusColor;
  final String cloth;
  final int qty;
  final num paid;
  final num remaining;
  final num total;
  final double progress;
  final String deliveryDate;
  final VoidCallback onTap;

  const _OrderCard({
    required this.scheme,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.cloth,
    required this.qty,
    required this.paid,
    required this.remaining,
    required this.total,
    required this.progress,
    required this.deliveryDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysLeft(deliveryDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (daysLeft != null) ...[
                    _DueChip(daysLeft: daysLeft),
                    const SizedBox(width: 8),
                  ],
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MoneyLine(label: 'Paid', value: paid)),
                  const SizedBox(width: 12),
                  Expanded(child: _MoneyLine(label: 'Remaining', value: remaining)),
                  const SizedBox(width: 12),
                  Expanded(child: _MoneyLine(label: 'Total', value: total)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
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
                  if (deliveryDate.isNotEmpty)
                    _MetaChip(
                      icon: Icons.calendar_month_outlined,
                      text: _dateOnly(deliveryDate),
                      color: Colors.teal.shade700,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _daysLeft(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final due = DateTime(dt.year, dt.month, dt.day);
    return due.difference(startToday).inDays;
  }

  String _dateOnly(String v) {
    final s = v.trim();
    final dateOnly = RegExp(r'^\\d{4}-\\d{2}-\\d{2}$');
    if (dateOnly.hasMatch(s)) return s;
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _DueChip extends StatelessWidget {
  final int daysLeft;
  const _DueChip({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isOverdue = daysLeft < 0;
    final isToday = daysLeft == 0;
    final label = isToday
        ? 'Due today'
        : isOverdue
            ? 'Overdue ${daysLeft.abs()}d'
            : '${daysLeft}d left';
    final color = isOverdue
        ? Colors.red.shade700
        : isToday
            ? Colors.orange.shade700
            : Colors.teal.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final num value;

  const _MoneyLine({required this.label, required this.value});

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
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(
            value.toString(),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

