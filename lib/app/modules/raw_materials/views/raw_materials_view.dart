import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/raw_materials_controller.dart';

class RawMaterialsView extends GetView<RawMaterialsController> {
  const RawMaterialsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_raw_materials',
        onPressed: () => _showCreate(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        final totalItems = controller.materials.length;
        num totalStockQty = 0;
        num totalValue = 0;
        for (final m in controller.materials) {
          final ex = (m['existing_quantity'] as num?) ?? 0;
          final nq = (m['new_quantity'] as num?) ?? 0;
          totalStockQty += ex + nq;
          totalValue += (m['total_price'] as num?) ?? 0;
        }

        return RefreshIndicator(
          onRefresh: controller.refreshMaterials,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                      child: const Icon(Icons.category_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raw Materials',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track quantities and purchase value',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Materials',
                      value: '$totalItems',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Stock qty',
                      value: totalStockQty.toString(),
                      icon: Icons.add_chart_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Value',
                      value: totalValue.toString(),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Latest',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Obx(() {
                    final isTable = controller.isTableView.value;
                    return SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Cards')),
                        ButtonSegment(value: true, label: Text('Table')),
                      ],
                      selected: {isTable},
                      onSelectionChanged: (s) =>
                          controller.toggleTableView(s.first),
                    );
                  }),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: controller.refreshMaterials,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (controller.materials.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 52, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No raw materials yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap + to add your first raw material.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Obx(() {
                  final isTable = controller.isTableView.value;
                  if (isTable) {
                    return _RawMaterialsTable(
                      materials: controller.materials,
                      onDelete: (id) => controller.remove(id),
                    );
                  }
                  return Column(
                    children: controller.materials.map((m) {
                      final existing = (m['existing_quantity'] as num?) ?? 0;
                      final newQty = (m['new_quantity'] as num?) ?? 0;
                      final unit = (m['unit']?.toString() ?? 'pcs');
                      final totalPrice = (m['total_price'] as num?) ?? 0;
                      final addedDate =
                          (m['new_quantity_added_date']?.toString() ?? '')
                              .trim();
                      final name = (m['name']?.toString() ?? 'Material').trim();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                          .titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        controller.remove(m['id'] as String),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    label: 'Qty',
                                    value: '${existing + newQty} $unit',
                                    color: scheme.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _KV(
                                      k: 'Total',
                                      v: totalPrice.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _KV(
                                      k: 'Unit',
                                      v: unit,
                                    ),
                                  ),
                                  if (addedDate.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _KV(
                                        k: 'New Qt Added',
                                        v: addedDate,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showCreate(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'pcs');
    final newQtyCtrl = TextEditingController(text: '0');
    final unitPriceCtrl = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;
        num totalPreview = (num.tryParse(newQtyCtrl.text.trim()) ?? 0) *
            (num.tryParse(unitPriceCtrl.text.trim()) ?? 0);
        return AlertDialog(
          title: const Text('New raw material'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                void recalc() {
                  final q = num.tryParse(newQtyCtrl.text.trim()) ?? 0;
                  final p = num.tryParse(unitPriceCtrl.text.trim()) ?? 0;
                  setState(() => totalPreview = q * p);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Cotton, Fabric, Thread',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'pcs / meter / kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: newQtyCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => recalc(),
                            decoration: const InputDecoration(
                              labelText: 'New quantity',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitPriceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => recalc(),
                      decoration: const InputDecoration(
                        labelText: 'Unit price',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calculate_outlined, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Total preview',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            totalPreview.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final newQty = num.tryParse(newQtyCtrl.text.trim()) ?? 0;
                final unitPrice = num.tryParse(unitPriceCtrl.text.trim()) ?? 0;
                await controller.create(
                  name: name,
                  unit: unitCtrl.text.trim().isEmpty ? 'pcs' : unitCtrl.text.trim(),
                  newQuantity: newQty,
                  unitPrice: unitPrice,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({
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
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Pill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;

  const _KV({required this.k, required this.v});

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

class _RawMaterialsTable extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final ValueChanged<String> onDelete;

  const _RawMaterialsTable({
    required this.materials,
    required this.onDelete,
  });

  num _num(dynamic v) => (v is num) ? v : (num.tryParse('${v ?? ''}') ?? 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.06),
        ),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Old price')),
          DataColumn(label: Text('New price')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Added')),
          DataColumn(label: Text('')),
        ],
        rows: materials.map((m) {
          final id = (m['id']?.toString() ?? '').trim();
          final name = (m['name']?.toString() ?? 'Material').trim();
          final unit = (m['unit']?.toString() ?? 'pcs').trim();
          final existing = _num(m['existing_quantity']);
          final newQty = _num(m['new_quantity']);
          final qty = existing + newQty;
          final totalPrice = _num(m['total_price']);
          final oldPrice = _num(m['old_unit_price']);
          final newPrice = _num(m['new_unit_price'] ?? m['unit_price']);
          final added =
              (m['new_quantity_added_date']?.toString() ?? '').trim();
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(qty.toString())),
              DataCell(Text(unit)),
              DataCell(Text(oldPrice.toString())),
              DataCell(Text(newPrice.toString())),
              DataCell(Text(totalPrice.toString())),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    added,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: id.isEmpty ? null : () => onDelete(id),
                ),
              ),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

