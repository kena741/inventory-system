import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../models/erp/enums.dart';
import '../controllers/raw_material_requests_controller.dart';

List<Map<String, dynamic>> _parseItemRowsFromRequest(
    Map<String, dynamic> request) {
  dynamic items = request['items'];
  if (items is String) {
    final s = items.trim();
    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        items = jsonDecode(s);
      } catch (_) {}
    }
  }
  final rows = <Map<String, dynamic>>[];
  if (items is List) {
    for (final it in items) {
      if (it is Map) rows.add(Map<String, dynamic>.from(it));
    }
  }
  if (rows.isEmpty) {
    rows.add({
      'name': (request['material_name']?.toString() ?? 'Material').trim(),
      'qty': request['quantity'] ?? 0,
      'unit': (request['unit']?.toString() ?? 'pcs').trim(),
      'last_order_price': null,
    });
  }
  return rows;
}

bool _isClosedRequestStatus(String status) {
  final s = status.trim().toLowerCase();
  return s == RawMaterialRequestStatuses.completed ||
      s == RawMaterialRequestStatuses.rejected ||
      s == 'purchased' ||
      s == 'cancelled' ||
      s == 'fulfilled';
}

class RawMaterialRequestsView extends GetView<RawMaterialRequestsController> {
  const RawMaterialRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role =
        parseUserRole(Get.find<AuthController>().currentUser.value?.role);
    final isManagerLike = role == UserRole.manager || role == UserRole.qualityChecker;
    Widget buildList(
      List<Map<String, dynamic>> requests, {
      bool closedTab = false,
    }) {
      if (requests.isEmpty) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.playlist_add_check_outlined,
                size: 56, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              closedTab ? 'No closed requests' : 'No requests here',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              closedTab
                  ? 'Completed and rejected requests appear here.'
                  : isManagerLike
                      ? 'Tap + to request raw materials for purchase.'
                      : 'Nothing in progress for you at this stage.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
                    final status = (r['status']?.toString() ?? 'pending').trim();
                    dynamic items = r['items'];
                    if (items is String) {
                      final s = items.trim();
                      if (s.startsWith('[') && s.endsWith(']')) {
                        try {
                          items = jsonDecode(s);
                        } catch (_) {}
                      }
                    }
                    final notes = (r['notes']?.toString() ?? '').trim();
                    final legacyTitle =
                        (r['material_name']?.toString() ?? 'Material').trim();

                    List<({String name, String qtyUnit, String? lastPrice})>
                        rows = [];
                    if (items is List && items.isNotEmpty) {
                      for (final it in items) {
                        if (it is Map) {
                          final name = (it['name']?.toString() ?? '')
                              .trim()
                              .isNotEmpty
                              ? (it['name']?.toString() ?? '').trim()
                              : (it['material_name']?.toString() ?? '').trim();
                          final qty = it['qty'] ?? it['quantity'] ?? 0;
                          final unitRaw = (it['unit']?.toString() ?? '').trim();
                          final unit = unitRaw.isEmpty ? 'pcs' : unitRaw;
                          if (name.isEmpty) continue;
                          final qtyUnit = '${qty ?? 0} $unit';
                          final last =
                              (it['last_order_price'] ?? it['lastPrice']);
                          final lastPrice = (last == null ||
                                  (last is String && last.trim().isEmpty))
                              ? null
                              : last.toString();
                          rows.add(
                            (name: name, qtyUnit: qtyUnit, lastPrice: lastPrice),
                          );
                        }
                      }
                    } else {
                      final qty = r['quantity'] ?? 0;
                      final unitRaw = (r['unit']?.toString() ?? '').trim();
                      final unit = unitRaw.isEmpty ? 'pcs' : unitRaw;
                      rows = [
                        (
                          name: legacyTitle,
                          qtyUnit: '$qty $unit',
                          lastPrice: null,
                        )
                      ];
                    }
                    final title = (items is List && items.isNotEmpty)
                        ? 'Raw material request (${rows.length} items)'
                        : legacyTitle;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusChip(status: status),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'View details',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showRequestDetails(
                                    context: context,
                                    request: r,
                                    role: role,
                                  ),
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: rows.map((row) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            row.qtyUnit,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if ((row.lastPrice ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Last: ${row.lastPrice}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: scheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.surfaceContainerHighest.withValues(
                                    alpha: 0.55,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  notes,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
        },
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(8),
            child: Obx(() {
              final all = controller.requests;
              final openCount = all
                  .where((r) => !_isClosedRequestStatus(
                      (r['status']?.toString() ?? 'pending').trim()))
                  .length;
              final closedCount = all.length - openCount;
              return TabBar(
                tabs: [
                  Tab(text: 'In progress ($openCount)'),
                  Tab(text: 'Closed ($closedCount)'),
                ],
              );
            }),
          ),
        ),
        floatingActionButton: isManagerLike
            ? FloatingActionButton(
                heroTag: 'fab_raw_material_requests',
                onPressed: () => _showCreate(context),
                child: const Icon(Icons.add),
              )
            : null,
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value.isNotEmpty) {
            return Center(child: Text(controller.error.value));
          }

          final all = controller.requests.toList(growable: false);
          final open = all
              .where((r) => !_isClosedRequestStatus(
                  (r['status']?.toString() ?? 'pending').trim()))
              .toList(growable: false);
          final closed = all
              .where((r) => _isClosedRequestStatus(
                  (r['status']?.toString() ?? 'pending').trim()))
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: controller.refreshRequests,
            child: TabBarView(
              children: [
                buildList(open),
                buildList(closed, closedTab: true),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showRequestDetails({
    required BuildContext context,
    required Map<String, dynamic> request,
    required UserRole role,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final id = request['id'] as String;
    final status = (request['status']?.toString() ?? 'pending').trim();
    final statusLc = status.toLowerCase();
    final notes = (request['notes']?.toString() ?? '').trim();
    final rows = _parseItemRowsFromRequest(request);

    dynamic receiptRaw = request['manager_receipt'];
    if (receiptRaw is String && receiptRaw.trim().startsWith('{')) {
      try {
        receiptRaw = jsonDecode(receiptRaw);
      } catch (_) {}
    }

    dynamic workflowAuditRaw = request['workflow_audit'];
    if (workflowAuditRaw is String && workflowAuditRaw.trim().startsWith('[')) {
      try {
        workflowAuditRaw = jsonDecode(workflowAuditRaw);
      } catch (_) {}
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Request details',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 12, color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final it = rows[index];
                      final name = (it['name']?.toString() ??
                              it['material_name']?.toString() ??
                              '')
                          .trim();
                      final qty = it['qty'] ?? it['quantity'] ?? 0;
                      final unitRaw = (it['unit']?.toString() ?? '').trim();
                      final unit = unitRaw.isEmpty ? 'pcs' : unitRaw;
                      final last = it['last_order_price'] ?? it['lastPrice'];
                      final lastText = (last == null ||
                              (last is String && last.trim().isEmpty))
                          ? null
                          : last.toString();

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? 'Material' : name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$qty $unit',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if ((lastText ?? '').trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Last: $lastText',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (receiptRaw is Map) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Manager receipt',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  _ManagerReceiptSummary(
                    receipt: Map<String, dynamic>.from(receiptRaw),
                    scheme: scheme,
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Notes', style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(notes),
                  ),
                ],
                if (workflowAuditRaw is List && workflowAuditRaw.isNotEmpty) ...[
                  SizedBox(height: notes.isNotEmpty ? 16 : 12),
                  _DecisionHistorySection(
                    events: workflowAuditRaw,
                    scheme: scheme,
                  ),
                ],
                if (role == UserRole.admin &&
                    statusLc == RawMaterialRequestStatuses.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await controller.adminApprove(id);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('Approve PO'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await controller.adminReject(id);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
                if ((role == UserRole.manager || role == UserRole.qualityChecker) &&
                    statusLc == RawMaterialRequestStatuses.approved) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await controller.managerMarkOrdered(id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.shopping_cart_checkout_outlined),
                      label: const Text('Mark as ordered'),
                    ),
                  ),
                ],
                if (role == UserRole.seller &&
                    statusLc == RawMaterialRequestStatuses.ordered) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await controller.sellerConfirmPurchased(id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Confirm purchase (seller)'),
                    ),
                  ),
                ],
                if ((role == UserRole.manager || role == UserRole.qualityChecker) &&
                    statusLc ==
                        RawMaterialRequestStatuses.sellerConfirmed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _showReceiptForm(
                          context: context,
                          requestId: id,
                          itemRows: rows,
                        );
                      },
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Record receipt & close'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReceiptForm({
    required BuildContext context,
    required String requestId,
    required List<Map<String, dynamic>> itemRows,
  }) async {
    final n = itemRows.length;
    if (n == 0) return;

    await controller.refreshVendors();
    if (!context.mounted) return;

    final meters = List.generate(n, (i) {
      final it = itemRows[i];
      final q = it['qty'] ?? it['quantity'] ?? 0;
      final num? qNum = q is num ? q : num.tryParse(q.toString());
      return TextEditingController(text: (qNum ?? 0).toString());
    });
    final unitPrice = List.generate(n, (i) {
      final it = itemRows[i];
      final p = it['last_order_price'] ?? it['lastPrice'];
      final num? pNum = p is num ? p : num.tryParse(p?.toString() ?? '');
      return TextEditingController(
        text: pNum != null && pNum != 0 ? pNum.toString() : '',
      );
    });
    final qtyGood = List.generate(n, (i) {
      final it = itemRows[i];
      final q = it['qty'] ?? it['quantity'] ?? 0;
      return TextEditingController(text: q.toString());
    });
    final qtyDamaged =
        List.generate(n, (_) => TextEditingController(text: '0'));
    final remarkCtrls = List.generate(n, (_) => TextEditingController());
    final selectedVendorId = List<String?>.filled(n, null, growable: false);
    final linePaymentType = List<String>.generate(n, (_) => 'cash');

    var disposed = false;
    void disposeAll() {
      if (disposed) return;
      disposed = true;
      for (final c in remarkCtrls) {
        c.dispose();
      }
      for (final c in meters) {
        c.dispose();
      }
      for (final c in unitPrice) {
        c.dispose();
      }
      for (final c in qtyGood) {
        c.dispose();
      }
      for (final c in qtyDamaged) {
        c.dispose();
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dCtx) {
        final scheme = Theme.of(dCtx).colorScheme;
        return StatefulBuilder(
          builder: (context, setLocal) {
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

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              title: Text(
                'Record receipt',
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
                        
                        if (controller.vendors.isEmpty)
                          Text(
                            'No vendors yet — add vendors (admin) first.',
                            style: Theme.of(dCtx).textTheme.bodySmall?.copyWith(
                                  color: scheme.error,
                                ),
                          ),
                        const SizedBox(height: 12),
                        ...List.generate(n, (index) {
                          final it = itemRows[index];
                          final name = (it['name']?.toString() ??
                                  it['material_name']?.toString() ??
                                  'Material')
                              .trim();
                          final unit =
                              (it['unit']?.toString() ?? 'pcs').trim();
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == n - 1 ? 0 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (index > 0)
                                  Divider(
                                    height: 1,
                                    color: scheme.outlineVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                if (index > 0) const SizedBox(height: 16),
                                Text(
                                  '$name · $unit',
                                  style: Theme.of(dCtx)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedVendorId[index],
                                  decoration: compactField('Vendor'),
                                  style: Theme.of(dCtx).textTheme.bodyMedium,
                                  items: [
                                    for (final v in controller.vendors)
                                      DropdownMenuItem<String>(
                                        value: v['id']?.toString(),
                                        child: Text(
                                          (v['name'] ?? 'Vendor').toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(dCtx)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                  ],
                                  onChanged: controller.vendors.isEmpty
                                      ? null
                                      : (val) => setLocal(
                                            () =>
                                                selectedVendorId[index] = val,
                                          ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: meters[index],
                                        readOnly: true,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: compactField('Meters'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: unitPrice[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: compactField('Unit price'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: linePaymentType[index],
                                  decoration: compactField('Payment'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cash',
                                      child: Text('Cash'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'credit',
                                      child: Text('Credit'),
                                    ),
                                  ],
                                  onChanged: (v) => setLocal(
                                    () => linePaymentType[index] =
                                        v ?? 'cash',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: qtyGood[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: compactField('Qty good'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: qtyDamaged[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration:
                                            compactField('Qty damaged'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: remarkCtrls[index],
                                  decoration: compactField('Remark'),
                                  maxLines: 1,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          );
                        }),
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
                    if (controller.vendors.isEmpty) {
                      Get.snackbar(
                        'Vendors required',
                        'Add vendors (admin) before recording receipt.',
                      );
                      return;
                    }
                    for (var i = 0; i < n; i++) {
                      final vid = selectedVendorId[i];
                      if (vid == null || vid.isEmpty) {
                        Get.snackbar(
                          'Vendor required',
                          'Select a vendor for each material line.',
                        );
                        return;
                      }
                    }
                    final lines = <Map<String, dynamic>>[];
                    for (var i = 0; i < n; i++) {
                      final it = itemRows[i];
                      final requestedRaw = it['qty'] ?? it['quantity'] ?? 0;
                      final requested =
                          requestedRaw is num
                              ? requestedRaw
                              : (num.tryParse(requestedRaw.toString()) ?? 0);
                      final mid =
                          (it['material_id']?.toString() ?? '').trim();
                      final lineName = (it['name']?.toString() ??
                              it['material_name']?.toString() ??
                              '')
                          .trim();
                      // Meters must match what was requested for this item.
                      final m = requested;
                      final up =
                          num.tryParse(unitPrice[i].text.trim()) ?? 0;
                      final g =
                          num.tryParse(qtyGood[i].text.trim()) ?? 0;
                      final d =
                          num.tryParse(qtyDamaged[i].text.trim()) ?? 0;
                      if (requested > 0 && (g + d) > requested) {
                        Get.snackbar(
                          'Invalid qty',
                          'For "$lineName": good + damaged cannot exceed requested ($requested).',
                        );
                        return;
                      }
                      lines.add({
                        'vendor_id': selectedVendorId[i],
                        'material_id': mid,
                        'name': lineName,
                        'payment_type': linePaymentType[i],
                        if (remarkCtrls[i].text.trim().isNotEmpty)
                          'remark': remarkCtrls[i].text.trim(),
                        'meters': m,
                        'unit_price': up,
                        'qty_good': g,
                        'qty_damaged': d,
                      });
                    }
                    await controller.managerCompleteWithReceipt(
                      id: requestId,
                      lines: lines,
                    );
                    if (!dCtx.mounted) return;
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dCtx).pop();
                  },
                  child: const Text('Save & complete'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      // Dispose after the route is gone; synchronous dispose here races dialog teardown
      // and can trigger inherited-widget assertions (e.g. _dependents.isEmpty).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        disposeAll();
      });
    });
  }

  Future<void> _showCreate(BuildContext context) async {
    final notesCtrl = TextEditingController();

    final qtyCtrls = <String, TextEditingController>{};
    var selectedMaterials = <Map<String, dynamic>>[];

    await showDialog<void>(
      context: context,
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: StatefulBuilder(
                builder: (context, setState) {
                  void syncQtyCtrls() {
                    final selectedIds = selectedMaterials
                        .map((m) => (m['id']?.toString() ?? '').trim())
                        .where((id) => id.isNotEmpty)
                        .toSet();
                    qtyCtrls.removeWhere((k, _) => !selectedIds.contains(k));
                    for (final id in selectedIds) {
                      qtyCtrls.putIfAbsent(id, () => TextEditingController(text: '1'));
                    }
                  }

                  syncQtyCtrls();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Request raw material purchase',
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
                      Obx(() {
                        if (controller.isMaterialsLoading.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (controller.materialsError.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              controller.materialsError.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.error),
                            ),
                          );
                        }

                        final options =
                            controller.materials.toList(growable: false);
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.expand_more),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                selectedMaterials.isEmpty
                                    ? 'Select raw materials'
                                    : '${selectedMaterials.length} selected',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onPressed: options.isEmpty
                                ? null
                                : () async {
                                    final picked = await _pickMaterials(
                                      context: context,
                                      allMaterials: options,
                                      initialSelectedIds: selectedMaterials
                                          .map((m) =>
                                              (m['id']?.toString() ?? '').trim())
                                          .where((id) => id.isNotEmpty)
                                          .toSet(),
                                    );
                                    if (picked == null) return;
                                    setState(() {
                                      selectedMaterials = picked;
                                    });
                                  },
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      if (selectedMaterials.isNotEmpty) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: selectedMaterials.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index == selectedMaterials.length) {
                                return TextField(
                                  controller: notesCtrl,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (required)',
                                  ),
                                );
                              }
                              final m = selectedMaterials[index];
                              final id = (m['id']?.toString() ?? '').trim();
                              final name =
                                  (m['name']?.toString() ?? 'Material').trim();
                              final unit =
                                  (m['unit']?.toString() ?? 'pcs').trim();
                              final ctrl = qtyCtrls[id]!;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        scheme.primary.withValues(alpha: 0.14),
                                  ),
                                ),
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
                                                .titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Remove',
                                          onPressed: () {
                                            setState(() {
                                              selectedMaterials = selectedMaterials
                                                  .where((x) =>
                                                      (x['id']?.toString() ??
                                                              '')
                                                          .trim() !=
                                                      id)
                                                  .toList(growable: false);
                                              qtyCtrls.remove(id);
                                            });
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Unit: $unit',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: ctrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity (required)',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final notes = notesCtrl.text.trim();
                                if (selectedMaterials.isEmpty) return;
                                if (notes.isEmpty) return;

                                final items = <Map<String, dynamic>>[];
                                for (final m in selectedMaterials) {
                                  final name =
                                      (m['name']?.toString() ?? '').trim();
                                  final unit =
                                      (m['unit']?.toString() ?? '').trim();
                                  final id =
                                      (m['id']?.toString() ?? '').trim();
                                  final lastOrderPrice = (m['new_unit_price'] ??
                                          m['unit_price'] ??
                                          m['old_unit_price']) ??
                                      0;
                                  final oldUnitPrice = (m['old_unit_price'] ??
                                          m['new_unit_price'] ??
                                          m['unit_price']) ??
                                      0;
                                  final q =
                                      num.tryParse(qtyCtrls[id]?.text.trim() ?? '') ??
                                          0;
                                  if (name.isEmpty) continue;
                                  if (q <= 0) return;
                                  items.add({
                                    'material_id': id,
                                    'material_name': name,
                                    'unit': unit.isEmpty ? 'pcs' : unit,
                                    'quantity': q,
                                    'last_order_price': lastOrderPrice,
                                    'old_unit_price': oldUnitPrice,
                                  });
                                }
                                if (items.isEmpty) return;

                                await controller.createRequestsBatch(
                                  items: items,
                                  notes: notes,
                                );
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              child: const Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>?> _pickMaterials({
    required BuildContext context,
    required List<Map<String, dynamic>> allMaterials,
    required Set<String> initialSelectedIds,
  }) async {
    final searchCtrl = TextEditingController();
    final selectedIds = initialSelectedIds.toSet();

    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                final q = searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? allMaterials
                    : allMaterials.where((m) {
                        final name = (m['name']?.toString() ?? '').toLowerCase();
                        return name.contains(q);
                      }).toList(growable: false);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select raw materials',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '${selectedIds.length} selected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No matches',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: scheme.outlineVariant,
                                ),
                                itemBuilder: (context, index) {
                                  final m = filtered[index];
                                  final id = (m['id']?.toString() ?? '').trim();
                                  final name =
                                      (m['name']?.toString() ?? 'Material').trim();
                                  final unit =
                                      (m['unit']?.toString() ?? 'pcs').trim();
                                  final checked = selectedIds.contains(id);
                                  return CheckboxListTile(
                                    value: checked,
                                    onChanged: (v) {
                                      setState(() {
                                        if ((v ?? false) && id.isNotEmpty) {
                                          selectedIds.add(id);
                                        } else {
                                          selectedIds.remove(id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text('Unit: $unit'),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final picked = allMaterials.where((m) {
                                final id = (m['id']?.toString() ?? '').trim();
                                return selectedIds.contains(id);
                              }).toList(growable: false);
                              Navigator.of(ctx).pop(picked);
                            },
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

enum _AuditLayout { cards, table }

class _AuditEventUi {
  final String kindLabel;
  final String who;
  final String dateStr;
  final String timeStr;
  final String detailStr;

  const _AuditEventUi({
    required this.kindLabel,
    required this.who,
    required this.dateStr,
    required this.timeStr,
    required this.detailStr,
  });
}

class _AuditUiFormat {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String kindLabel(String kind) {
    return switch (kind.trim()) {
      'request_created' => 'Request created',
      'admin_approved' => 'Approved',
      'admin_rejected' => 'Rejected',
      'manager_ordered' => 'Ordered',
      'seller_confirmed' => 'Seller confirmed',
      'request_completed' => 'Receipt closed',
      _ => kind.trim().isEmpty ? 'Event' : kind.trim(),
    };
  }

  static String titleCaseRole(String role) {
    final t = role.trim();
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  static String formatDate(DateTime local) {
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  static String formatTime(DateTime local) {
    final hour24 = local.hour;
    final isPm = hour24 >= 12;
    var h12 = hour24 % 12;
    if (h12 == 0) h12 = 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h12:$m ${isPm ? 'PM' : 'AM'}';
  }

  static List<Map<String, dynamic>> parseEvents(List<dynamic> events) {
    final parsed = <Map<String, dynamic>>[];
    for (final e in events) {
      if (e is Map) {
        parsed.add(Map<String, dynamic>.from(e));
      } else if (e is String && e.trim().startsWith('{')) {
        try {
          final m = jsonDecode(e);
          if (m is Map) parsed.add(Map<String, dynamic>.from(m));
        } catch (_) {}
      }
    }
    parsed.sort((a, b) {
      final ta = (a['recorded_at']?.toString() ?? '').trim();
      final tb = (b['recorded_at']?.toString() ?? '').trim();
      return ta.compareTo(tb);
    });
    return parsed;
  }

  static _AuditEventUi toRow(Map<String, dynamic> ev) {
    final kind = (ev['kind']?.toString() ?? '').trim();
    final role = (ev['actor_role']?.toString() ?? '').trim();
    final actorName = (ev['actor_name']?.toString() ?? '').trim();
    final at = (ev['recorded_at']?.toString() ?? '').trim();
    final parsedAt = at.isNotEmpty ? DateTime.tryParse(at) : null;
    final localAt = parsedAt?.toLocal();

    final rolePart = role.isNotEmpty ? titleCaseRole(role) : '';
    final who = actorName.isNotEmpty
        ? (rolePart.isNotEmpty ? '$rolePart · $actorName' : actorName)
        : (rolePart.isNotEmpty ? rolePart : '—');

    final detail = ev['detail'];
    String detailStr = '';
    if (detail is Map && detail.isNotEmpty) {
      detailStr = detail.entries
          .where((e) =>
              e.key.toString() != 'actor_user_id' &&
              e.key.toString() != 'actor_name')
          .map((e) => '${e.key}: ${e.value}')
          .join(' · ');
    }

    final dateStr = localAt != null
        ? formatDate(localAt)
        : (at.isNotEmpty ? at : '—');
    final timeStr =
        localAt != null ? formatTime(localAt) : '';

    return _AuditEventUi(
      kindLabel: kindLabel(kind),
      who: who,
      dateStr: dateStr,
      timeStr: timeStr,
      detailStr: detailStr,
    );
  }
}

class _DecisionHistorySection extends StatefulWidget {
  final List<dynamic> events;
  final ColorScheme scheme;

  const _DecisionHistorySection({
    required this.events,
    required this.scheme,
  });

  @override
  State<_DecisionHistorySection> createState() => _DecisionHistorySectionState();
}

class _DecisionHistorySectionState extends State<_DecisionHistorySection> {
  _AuditLayout _layout = _AuditLayout.cards;

  @override
  Widget build(BuildContext context) {
    final rows = _AuditUiFormat.parseEvents(widget.events);
    if (rows.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Decision history',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_AuditLayout>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<_AuditLayout>(
                value: _AuditLayout.cards,
                label: Text('Cards'),
                icon: Icon(Icons.dashboard_customize_outlined, size: 16),
              ),
              ButtonSegment<_AuditLayout>(
                value: _AuditLayout.table,
                label: Text('Table'),
                icon: Icon(Icons.table_rows_outlined, size: 16),
              ),
            ],
            selected: {_layout},
            onSelectionChanged: (s) {
              setState(() => _layout = s.first);
            },
          ),
        ),
        const SizedBox(height: 10),
        if (_layout == _AuditLayout.cards)
          _AuditCardsBody(rows: rows, scheme: widget.scheme)
        else
          _AuditTableBody(rows: rows, scheme: widget.scheme),
      ],
    );
  }
}

class _AuditCardsBody extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final ColorScheme scheme;

  const _AuditCardsBody({
    required this.rows,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: List.generate(rows.length, (i) {
        final ui = _AuditUiFormat.toRow(rows[i]);
        final isLast = i == rows.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ui.kindLabel,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ui.who,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: scheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        ui.timeStr.isNotEmpty
                            ? '${ui.dateStr} · ${ui.timeStr}'
                            : ui.dateStr,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (ui.detailStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      ui.detailStr,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AuditTableBody extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final ColorScheme scheme;

  const _AuditTableBody({
    required this.rows,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lineColor = scheme.outlineVariant.withValues(alpha: 0.7);

    Widget tableCell(
      String text, {
      bool header = false,
      int flex = 1,
      int maxLines = 4,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            text,
            style: header
                ? textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  )
                : textTheme.bodySmall,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final uiRows = rows.map(_AuditUiFormat.toRow).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tableCell('Step', header: true, maxLines: 1),
                tableCell('Who', header: true, maxLines: 1),
                tableCell('When', header: true, maxLines: 1),
                tableCell('Detail', header: true, flex: 2, maxLines: 1),
              ],
            ),
          ),
          for (var i = 0; i < uiRows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: lineColor),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tableCell(uiRows[i].kindLabel, maxLines: 3),
                tableCell(uiRows[i].who, maxLines: 3),
                tableCell(
                  uiRows[i].timeStr.isNotEmpty
                      ? '${uiRows[i].dateStr}\n${uiRows[i].timeStr}'
                      : uiRows[i].dateStr,
                  maxLines: 3,
                ),
                tableCell(
                  uiRows[i].detailStr.isEmpty ? '—' : uiRows[i].detailStr,
                  flex: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerReceiptSummary extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final ColorScheme scheme;

  const _ManagerReceiptSummary({
    required this.receipt,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final lines = receipt['lines'];
    if (lines is! List || lines.isEmpty) {
      return Text(
        'No line details',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((raw) {
        if (raw is! Map) return const SizedBox.shrink();
        final m = Map<String, dynamic>.from(raw);
        final name =
            (m['name']?.toString() ?? m['material_name']?.toString() ?? '')
                .trim();
        final meters = m['meters'];
        final up = m['unit_price'];
        final g = m['qty_good'];
        final d = m['qty_damaged'];
        final pt = (m['payment_type'] ?? 'cash').toString();
        final rm = (m['remark'] ?? '').toString().trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              [
                if (name.isNotEmpty) name,
                'Payment: ${pt == 'credit' ? 'Credit' : 'Cash'}',
                if (rm.isNotEmpty) 'Note: $rm',
                if (meters != null) 'Meters: $meters',
                if (up != null) 'Price: $up',
                if (g != null) 'Good: $g',
                if (d != null) 'Damaged: $d',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = status.trim().toLowerCase();
    final (Color bg, Color fg, String text) = switch (normalized) {
      'approved' => (
          scheme.tertiaryContainer.withValues(alpha: 0.75),
          scheme.onTertiaryContainer,
          'Approved'
        ),
      'rejected' => (
          scheme.errorContainer.withValues(alpha: 0.85),
          scheme.onErrorContainer,
          'Rejected'
        ),
      'cancelled' => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.85),
          scheme.onSurfaceVariant,
          'Cancelled'
        ),
      'ordered' => (
          scheme.secondaryContainer.withValues(alpha: 0.75),
          scheme.onSecondaryContainer,
          'Ordered'
        ),
      'seller_confirmed' => (
          scheme.primaryContainer.withValues(alpha: 0.75),
          scheme.onPrimaryContainer,
          'Awaiting receipt'
        ),
      'completed' || 'purchased' || 'fulfilled' => (
          scheme.primaryContainer.withValues(alpha: 0.75),
          scheme.onPrimaryContainer,
          normalized == 'purchased' ? 'Purchased' : 'Completed'
        ),
      _ => (
          scheme.surfaceContainerHighest.withValues(alpha: 0.75),
          scheme.onSurfaceVariant,
          'Pending approval'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

