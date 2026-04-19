import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/models/erp/location_model.dart';
import '../utils/storage_service.dart';
import '../utils/supabase_utils.dart';
import 'db_service.dart';

class SellerPerformanceStats {
  final int ordersCount;
  final num totalPaid;
  final Map<String, int> ordersByDay;
  final Map<String, num> paidByDay;

  const SellerPerformanceStats({
    required this.ordersCount,
    required this.totalPaid,
    required this.ordersByDay,
    required this.paidByDay,
  });
}

class ErpRepository {
  SupabaseClient get _db => DbService().client;

  /// Matches `public.raw_material_requests` (see Supabase DDL).
  static const String _rawMaterialRequestsTable = 'raw_material_requests';

  /// DB CHECK uses `fulfilled`; app screens use `completed`.
  static String _requestStatusToDb(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'completed') return 'fulfilled';
    return status;
  }

  static String _requestStatusFromDb(dynamic status) {
    final s = (status?.toString() ?? '').trim().toLowerCase();
    if (s == 'fulfilled') return 'completed';
    return (status?.toString() ?? 'pending').trim();
  }

  static Map<String, dynamic> _normalizeRawMaterialRequestRow(
    Map<String, dynamic> row,
  ) {
    final m = Map<String, dynamic>.from(row);
    m['status'] = _requestStatusFromDb(m['status']);
    return m;
  }

  static Map<String, dynamic> _requestUpdatePatchForDb(
    Map<String, dynamic> patch,
  ) {
    final p = Map<String, dynamic>.from(patch);
    if (p['status'] is String) {
      p['status'] = _requestStatusToDb(p['status'] as String);
    }
    return p;
  }

  // ===== Raw Materials (raw_materials table) =====
  Future<List<Map<String, dynamic>>> listRawMaterials() async {
    final rows = await _db
        .from('raw_materials')
        .select()
        .order('new_quantity_added_date', ascending: false)
        .order('name', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> createRawMaterial({
    required String name,
    required String unit,
    required num newQuantity,
    required num unitPrice,
  }) async {
    final totalPrice = newQuantity * unitPrice;
    await _db.from('raw_materials').insert({
      'name': name,
      'unit': unit,
      'existing_quantity': 0,
      'new_quantity': newQuantity,
      'new_quantity_added_date': DateTime.now().toIso8601String(),
      // Schema update: unit_price -> new_unit_price, add old_unit_price
      'new_unit_price': unitPrice,
      'old_unit_price': unitPrice,
      'total_price': totalPrice,
    });
  }

  Future<void> deleteRawMaterial(String id) async {
    await _db.from('raw_materials').delete().eq('id', id);
  }

  // ===== Locations =====
  Future<List<LocationModel>> listLocations() async {
    final rows = await _db
        .from('locations')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createLocation({
    required String name,
    required String type,
  }) async {
    await _db.from('locations').insert({'name': name, 'type': type});
  }

  Future<void> deleteLocation(String id) async {
    await _db.from('locations').delete().eq('id', id);
  }

  // ===== Expenses =====
  Future<List<Map<String, dynamic>>> listExpenses() async {
    final rows =
        await _db.from('expenses').select().order('date', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> createExpense({
    required String category,
    required num amount,
    required String locationId,
    String? description,
  }) async {
    await _db.from('expenses').insert({
      'category': category,
      'amount': amount,
      'location_id': locationId,
      'description': description,
    });
  }

  // ===== Vendors =====
  Future<List<Map<String, dynamic>>> listVendors() async {
    final rows =
        await _db.from('vendors').select().order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> createVendor({
    required String name,
    String? phone,
    String? address,
  }) async {
    await _db.from('vendors').insert({
      'name': name,
      'phone': phone,
      'address': address,
    });
  }

  Future<void> updateVendor({
    required String id,
    required String name,
    String? phone,
    String? address,
  }) async {
    await _db.from('vendors').update({
      'name': name,
      'phone': phone,
      'address': address,
    }).eq('id', id);
  }

  Future<void> deleteVendor(String id) async {
    await _db.from('vendors').delete().eq('id', id);
  }

  // ===== Customer Orders =====
  Future<List<Map<String, dynamic>>> listCustomerOrders() async {
    final rows = await _db
        .from('customer_orders')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getCustomerOrder(String orderId) async {
    final row = await _db.from('customer_orders').select().eq('id', orderId).maybeSingle();
    return row;
  }

  /// Stored as lowercase `cash` | `bank` for DB CHECK constraints.
  static String? _paymentChannelForDb(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s == 'bank') return 'bank';
    if (s == 'cash') return 'cash';
    return null;
  }

  Future<String> createCustomerOrder({
    required String customerName,
    String? clothCode,
    required int quantity,
    required num initialPayment,
    required num remainingPayment,
    num? totalAmount,
    DateTime? deliveryDate,
    String? description,
    String status = 'pending',
    String? customerInterest,
    String? customerAddress,
    String? customerNumber,
    String initialPaymentPaymentType = 'cash',
  }) async {
    final createdBy = StorageService.getUserId() ?? SupabaseUtils.getCurrentUid();
    final completedAt = status == 'completed'
        ? DateTime.now().toIso8601String()
        : null;
    final initialPt =
        _paymentChannelForDb(initialPaymentPaymentType) ?? 'cash';
    final row = await _db
        .from('customer_orders')
        .insert({
          'customer_name': customerName,
          'cloth_code': clothCode,
          'quantity': quantity,
          'initial_payment': initialPayment,
          'remaining_payment': remainingPayment,
          'total_amount': totalAmount,
          'delivery_date': deliveryDate?.toIso8601String(),
          'description': description,
          'status': status,
          if ((customerInterest ?? '').trim().isNotEmpty)
            'customer_interest': customerInterest!.trim(),
          if ((customerAddress ?? '').trim().isNotEmpty)
            'customer_address': customerAddress!.trim(),
          if ((customerNumber ?? '').trim().isNotEmpty)
            'customer_number': customerNumber!.trim(),
          'initial_payment_payment_type': initialPt,
          if (createdBy != null) 'created_by': createdBy,
          if (completedAt != null) 'completed_at': completedAt,
        })
        .select()
        .single();
    return row['id'] as String;
  }

  Future<void> updateCustomerOrderFinalPaymentType({
    required String orderId,
    required String finalPaymentPaymentType,
  }) async {
    final t = _paymentChannelForDb(finalPaymentPaymentType) ?? 'cash';
    await _db.from('customer_orders').update({
      'final_payment_payment_type': t,
    }).eq('id', orderId);
  }

  Future<void> ensureMeasurementsForOrder({
    required String orderId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    final existing = await listMeasurements(orderId);
    final existingIndexes = existing
        .map((m) => (m['item_index'] as int?) ?? -1)
        .where((i) => i > 0)
        .toSet();

    final inserts = <Map<String, dynamic>>[];
    for (var i = 1; i <= quantity; i++) {
      if (!existingIndexes.contains(i)) {
        inserts.add({'order_id': orderId, 'item_index': i});
      }
    }
    if (inserts.isNotEmpty) {
      await _db.from('measurements').insert(inserts);
    }
  }

  Future<void> updateCustomerOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _db.from('customer_orders').update({
      'status': status,
      if (status == 'completed') 'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> listTailors() async {
    final rows = await _db
        .from('users')
        .select('id,first_name,last_name,role')
        .eq('role', 'tailor')
        .order('first_name', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Completed orders with `tailor_id` in local-date window `[rangeStart, rangeEndExclusive)`.
  Future<List<Map<String, dynamic>>> listCompletedOrdersForTailorTeam({
    required DateTime rangeStartLocal,
    required DateTime rangeEndExclusiveLocal,
  }) async {
    final rows = await _db
        .from('customer_orders')
        .select('id,status,completed_at,order_date,tailor_id,quantity')
        .eq('status', 'completed');
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.where((o) {
      final tid = o['tailor_id']?.toString();
      if (tid == null || tid.isEmpty) return false;
      final completedAt =
          _parseDate(o['completed_at']) ?? _parseDate(o['order_date']);
      if (completedAt == null) return false;
      final local = completedAt.toLocal();
      if (local.isBefore(rangeStartLocal)) return false;
      if (!local.isBefore(rangeEndExclusiveLocal)) return false;
      return true;
    }).toList();
  }

  Future<String?> getUserDisplayNameById(String userId) async {
    final row = await _db
        .from('users')
        .select('first_name,last_name,email,phone_number')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    final fn = (row['first_name']?.toString() ?? '').trim();
    final ln = (row['last_name']?.toString() ?? '').trim();
    final full = [fn, ln].where((e) => e.isNotEmpty).join(' ').trim();
    if (full.isNotEmpty) return full;
    final email = (row['email']?.toString() ?? '').trim();
    if (email.isNotEmpty) return email;
    final phone = (row['phone_number']?.toString() ?? '').trim();
    if (phone.isNotEmpty) return phone;
    return null;
  }

  Future<void> assignOrderToTailor({
    required String orderId,
    required String tailorId,
  }) async {
    final managerId = StorageService.getUserId();
    await _db
        .from('customer_orders')
        .update({
          'tailor_id': tailorId,
          if (managerId != null && managerId.isNotEmpty) 'manager_id': managerId,
        })
        .eq('id', orderId);
  }

  // ===== Measurements =====
  Future<List<Map<String, dynamic>>> listMeasurements(String orderId) async {
    final rows = await _db
        .from('measurements')
        .select()
        .eq('order_id', orderId)
        .order('item_index', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> createMeasurement({
    required String orderId,
    required int itemIndex,
    String? customerLabel,
    num? height,
    num? chest,
    num? waist,
    num? hip,
    num? shoulder,
    num? sleeveLength,
    num? neck,
    num? inseam,
    num? thigh,
    num? calf,
    String? notes,
  }) async {
    await _db.from('measurements').insert({
      'order_id': orderId,
      'item_index': itemIndex,
      'customer_label': customerLabel,
      'height': height,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'shoulder': shoulder,
      'sleeve_length': sleeveLength,
      'neck': neck,
      'inseam': inseam,
      'thigh': thigh,
      'calf': calf,
      'notes': notes,
    });
  }

  Future<String> ensureMeasurementRow({
    required String orderId,
    required int itemIndex,
  }) async {
    final row = await _db
        .from('measurements')
        .select('id')
        .eq('order_id', orderId)
        .eq('item_index', itemIndex)
        .maybeSingle();
    final id = row?['id'] as String?;
    if (id != null && id.isNotEmpty) return id;

    final inserted = await _db
        .from('measurements')
        .insert({'order_id': orderId, 'item_index': itemIndex})
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<void> updateMeasurement({
    required String measurementId,
    String? customerLabel,
    num? height,
    num? chest,
    num? waist,
    num? hip,
    num? shoulder,
    num? sleeveLength,
    num? neck,
    num? inseam,
    num? thigh,
    num? calf,
    String? notes,
  }) async {
    await _db.from('measurements').update({
      'customer_label': customerLabel,
      'height': height,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'shoulder': shoulder,
      'sleeve_length': sleeveLength,
      'neck': neck,
      'inseam': inseam,
      'thigh': thigh,
      'calf': calf,
      'notes': notes,
    }).eq('id', measurementId);
  }

  // ===== Raw Material Purchase Requests =====
  Future<List<Map<String, dynamic>>> listRawMaterialRequests() async {
    final rows = await _db
        .from(_rawMaterialRequestsTable)
        .select()
        .order('created_at', ascending: false);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(_normalizeRawMaterialRequestRow).toList(growable: false);
  }

  Future<void> createRawMaterialRequest({
    required String materialName,
    required String unit,
    required num quantity,
    String? notes,
    String? actorName,
  }) async {
    final uid = SupabaseUtils.getCurrentUid();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final auditEntry = <String, dynamic>{
      'kind': 'request_created',
      'actor_user_id': uid ?? '',
      'actor_role': 'manager',
      'recorded_at': createdAt,
      'detail': {'mode': 'single_item'},
    };
    final name = (actorName ?? '').trim();
    if (name.isNotEmpty) auditEntry['actor_name'] = name;
    await _db.from(_rawMaterialRequestsTable).insert({
      'requested_by': uid,
      'items': [
        {
          'name': materialName,
          'material_name': materialName,
          'qty': quantity,
          'quantity': quantity,
          'unit': unit,
          'material_id': '',
        },
      ],
      'notes': notes,
      'status': 'pending',
      'workflow_audit': [auditEntry],
    });
  }

  /// Creates ONE request row, storing selected items in jsonb `items`.
   /// Expects `items` jsonb (array of line objects).
  Future<void> createRawMaterialRequestJsonb({
    required List<Map<String, dynamic>> items,
    required String? notes,
    String? actorName,
  }) async {
    if (items.isEmpty) return;
    final uid = SupabaseUtils.getCurrentUid();
    final payloadItems = items.map((i) {
      final name = (i['material_name'] ?? i['name'] ?? '').toString().trim();
      final qty = i['quantity'] ?? i['qty'] ?? 0;
      final unitRaw = (i['unit'] ?? '').toString().trim();
      final unit = unitRaw.isEmpty ? 'pcs' : unitRaw;
      final materialId = (i['material_id'] ?? i['id'] ?? '').toString().trim();
      final lastOrderPrice = i['last_order_price'] ?? i['lastOrderPrice'] ?? 0;
      return <String, dynamic>{
        // Keep JSONB small + consistent (no duplicate keys)
        'name': name,
        'qty': qty,
        'material_id': materialId,
        'unit': unit,
        'last_order_price': lastOrderPrice,
      };
    }).toList(growable: false);

    final createdAt = DateTime.now().toUtc().toIso8601String();
    final auditEntry = <String, dynamic>{
      'kind': 'request_created',
      'actor_user_id': uid ?? '',
      'actor_role': 'manager',
      'recorded_at': createdAt,
      'detail': {'item_count': payloadItems.length},
    };
    final name = (actorName ?? '').trim();
    if (name.isNotEmpty) auditEntry['actor_name'] = name;
    await _db.from(_rawMaterialRequestsTable).insert({
      'requested_by': uid,
      'items': payloadItems,
      'notes': notes,
      'status': 'pending',
      'workflow_audit': [auditEntry],
    });
  }

  Future<void> updateRawMaterialRequestStatus({
    required String id,
    required String status,
  }) async {
    await _db
        .from(_rawMaterialRequestsTable)
        .update({'status': _requestStatusToDb(status)})
        .eq('id', id);
  }

  /// Normalizes `workflow_audit` from jsonb[] or a single JSON array value.
  static List<Map<String, dynamic>> _normalizeWorkflowAuditList(dynamic raw) {
    if (raw == null) return [];
    if (raw is String && raw.trim().startsWith('[')) {
      try {
        final d = jsonDecode(raw);
        return _normalizeWorkflowAuditList(d);
      } catch (_) {
        return [];
      }
    }
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      } else if (e is String && e.trim().startsWith('{')) {
        try {
          final m = jsonDecode(e);
          if (m is Map) out.add(Map<String, dynamic>.from(m));
        } catch (_) {}
      }
    }
    return out;
  }

  /// Appends one entry to [workflow_audit] (JSONB array) and applies [rowPatch]
  /// (must include `status` when the status changes).
  ///
  /// Each event: `{ kind, actor_user_id, actor_name?, actor_role?, recorded_at, detail }`.
  Future<void> appendRawMaterialRequestWorkflowEvent({
    required String id,
    required Map<String, dynamic> rowPatch,
    required String kind,
    required String actorUserId,
    String? actorName,
    String? actorRole,
    Map<String, dynamic>? detail,
  }) async {
    final row = await _db
        .from(_rawMaterialRequestsTable)
        .select('workflow_audit')
        .eq('id', id)
        .maybeSingle();
    final list = _normalizeWorkflowAuditList(row?['workflow_audit']);
    final event = <String, dynamic>{
      'kind': kind,
      'actor_user_id': actorUserId,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
      'detail': detail ?? <String, dynamic>{},
    };
    if (actorRole != null && actorRole.isNotEmpty) {
      event['actor_role'] = actorRole;
    }
    final name = (actorName ?? '').trim();
    if (name.isNotEmpty) event['actor_name'] = name;
    list.add(event);
    final dbPatch = _requestUpdatePatchForDb(rowPatch);
    await _db.from(_rawMaterialRequestsTable).update({
      ...dbPatch,
      'workflow_audit': list,
    }).eq('id', id);
  }

  /// Persists [managerReceipt] (meters, prices, good/damaged qty per line) and
  /// adds [qty_good] to `raw_materials.new_quantity` when [material_id] is set.
  Future<void> completeRawMaterialRequestWithReceipt({
    required String id,
    required Map<String, dynamic> managerReceipt,
    required String auditActorUserId,
    String? auditActorName,
    String? auditActorRole,
    Map<String, dynamic>? auditDetail,
  }) async {
    final lines = managerReceipt['lines'];
    final lineCount = lines is List ? lines.length : 0;
    await appendRawMaterialRequestWorkflowEvent(
      id: id,
      rowPatch: {
        'status': 'completed',
        'manager_receipt': managerReceipt,
      },
      kind: 'request_completed',
      actorUserId: auditActorUserId,
      actorName: auditActorName,
      actorRole: auditActorRole,
      detail: {
        ...?auditDetail,
        'line_count': lineCount,
      },
    );

    if (lines is! List) return;
    for (final entry in lines) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final materialId = (m['material_id']?.toString() ?? '').trim();
      final qtyGood = _coerceNum(m['qty_good']);
      final unitPrice = _coerceNum(m['unit_price']);
      if (materialId.isEmpty || qtyGood <= 0) continue;
      await _incrementRawMaterialStockFromReceipt(
        materialId: materialId,
        quantityGood: qtyGood,
        unitPrice: unitPrice,
      );
    }

    await _recordPurchaseFromReceipt(
      rawMaterialRequestId: id,
      managerReceipt: managerReceipt,
    );
  }

  Future<void> _recordPurchaseFromReceipt({
    required String rawMaterialRequestId,
    required Map<String, dynamic> managerReceipt,
  }) async {
    final linesRaw = managerReceipt['lines'];
    if (linesRaw is! List || linesRaw.isEmpty) return;

    DateTime purchaseDate = DateTime.now();
    final pds = managerReceipt['purchase_date']?.toString().trim();
    if (pds != null && pds.isNotEmpty) {
      purchaseDate = DateTime.tryParse(pds) ?? purchaseDate;
    }
    final dateOnly =
        DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    final dateStr =
        '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

    num totalAmount = 0;
    final parsedLines = <Map<String, dynamic>>[];
    for (final entry in linesRaw) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final qtyGood = _coerceNum(m['qty_good']);
      final unitPrice = _coerceNum(m['unit_price']);
      final lineTotal = qtyGood * unitPrice;
      totalAmount += lineTotal;
      m['line_total'] = lineTotal;
      parsedLines.add(m);
    }
    if (parsedLines.isEmpty) return;

    String? headerVendorId;
    for (final l in parsedLines) {
      final v = (l['vendor_id']?.toString() ?? '').trim();
      if (v.isNotEmpty) {
        headerVendorId = v;
        break;
      }
    }

    final purchaseRow = await _db
        .from('purchases')
        .insert({
          'raw_material_request_id': rawMaterialRequestId,
          'vendor_id': headerVendorId,
          'purchase_date': dateStr,
          'payment_type': null,
          'remark': null,
          'total_amount': totalAmount,
        })
        .select('id')
        .maybeSingle();

    final purchaseId = purchaseRow?['id']?.toString();
    if (purchaseId == null || purchaseId.isEmpty) return;

    final lastPriceByMaterial = <String, num>{};
    for (final pl in parsedLines) {
      final materialId = (pl['material_id']?.toString() ?? '').trim();
      final vendorId = (pl['vendor_id']?.toString() ?? '').trim();

      final ptRaw =
          (pl['payment_type'] ?? 'cash').toString().trim().toLowerCase();
      final linePaymentType = ptRaw == 'credit' ? 'credit' : 'cash';
      final lineRemark = pl['remark']?.toString().trim();

      await _db.from('purchase_lines').insert({
        'purchase_id': purchaseId,
        'vendor_id': vendorId.isEmpty ? null : vendorId,
        'raw_material_id': materialId.isEmpty ? null : materialId,
        'payment_type': linePaymentType,
        'remark':
            (lineRemark == null || lineRemark.isEmpty) ? null : lineRemark,
        'meters': _coerceNum(pl['meters']),
        'qty_good': _coerceNum(pl['qty_good']),
        'qty_damaged': _coerceNum(pl['qty_damaged']),
        'unit_price': _coerceNum(pl['unit_price']),
        'line_total': _coerceNum(pl['line_total']),
      });

      final up = _coerceNum(pl['unit_price']);
      if (materialId.isNotEmpty && up > 0) {
        lastPriceByMaterial[materialId] = up;
      }
    }

    for (final e in lastPriceByMaterial.entries) {
      await _applyPriceHistoryForMaterial(
        rawMaterialId: e.key,
        price: e.value,
        startDate: dateOnly,
      );
    }
  }

  Future<void> _applyPriceHistoryForMaterial({
    required String rawMaterialId,
    required num price,
    required DateTime startDate,
  }) async {
    final prevEnd = startDate.subtract(const Duration(days: 1));
    final prevEndStr =
        '${prevEnd.year}-${prevEnd.month.toString().padLeft(2, '0')}-${prevEnd.day.toString().padLeft(2, '0')}';

    final openRows = await _db
        .from('price_history')
        .select('id,end_date')
        .eq('raw_material_id', rawMaterialId);

    final list = (openRows as List).cast<Map<String, dynamic>>();
    for (final r in list) {
      if (r['end_date'] != null) continue;
      final hid = r['id']?.toString();
      if (hid == null || hid.isEmpty) continue;
      await _db
          .from('price_history')
          .update({'end_date': prevEndStr})
          .eq('id', hid);
    }

    final startStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    await _db.from('price_history').insert({
      'raw_material_id': rawMaterialId,
      'price': price,
      'start_date': startStr,
      'end_date': null,
    });
  }

  static num _coerceNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString().trim()) ?? 0;
  }

  Future<void> _incrementRawMaterialStockFromReceipt({
    required String materialId,
    required num quantityGood,
    required num unitPrice,
  }) async {
    final row = await _db
        .from('raw_materials')
        .select()
        .eq('id', materialId)
        .maybeSingle();
    if (row == null) return;

    final nq = _coerceNum(row['new_quantity']);
    final oldTotal = _coerceNum(row['total_price']);
    final lineValue = quantityGood * unitPrice;
    final patch = <String, dynamic>{
      'new_quantity': nq + quantityGood,
      'new_quantity_added_date': DateTime.now().toIso8601String(),
      'total_price': oldTotal + lineValue,
    };
    if (unitPrice > 0) {
      final prevUnit = row['new_unit_price'];
      patch['old_unit_price'] = prevUnit ?? unitPrice;
      patch['new_unit_price'] = unitPrice;
    }
    await _db.from('raw_materials').update(patch).eq('id', materialId);
  }

  // ===== Tailor Assigned Orders =====
  Future<List<Map<String, dynamic>>> listAssignedOrdersForCurrentTailor() async {
    final profileId = StorageService.getUserId();
    final uid = SupabaseUtils.getCurrentUid();

    dynamic q = _db.from('customer_orders').select();
    if (profileId != null && profileId.isNotEmpty) {
      q = q.eq('tailor_id', profileId);
    } else if (uid != null && uid.isNotEmpty) {
      q = q.eq('tailor_id', uid);
    }

    final rows = await q.order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  DateTime _rangeStart(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        final weekday = now.weekday; // 1=Mon
        final start = now.subtract(Duration(days: weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  /// Local calendar bounds for tailor delivered stats. [anchor] is any instant; only its local date matters.
  (DateTime startInclusive, DateTime endExclusive) _tailorPerformanceRangeBounds(
    String range,
    DateTime anchor,
  ) {
    final local = anchor.toLocal();
    final d = DateTime(local.year, local.month, local.day);
    switch (range) {
      case 'day':
        return (d, d.add(const Duration(days: 1)));
      case 'week':
        final start = d.subtract(Duration(days: d.weekday - DateTime.monday));
        final s = DateTime(start.year, start.month, start.day);
        return (s, s.add(const Duration(days: 7)));
      case 'month':
        final s = DateTime(d.year, d.month, 1);
        final end = d.month == 12
            ? DateTime(d.year + 1, 1, 1)
            : DateTime(d.year, d.month + 1, 1);
        return (s, end);
      default:
        return (d, d.add(const Duration(days: 1)));
    }
  }

  bool _completionInTailorRange(
    Map<String, dynamic> o,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    final at = _parseDate(o['completed_at']) ??
        _parseDate(o['order_date']) ??
        _parseDate(o['created_at']);
    if (at == null) return false;
    final local = at.toLocal();
    return !local.isBefore(startInclusive) && local.isBefore(endExclusive);
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  // ===== Tailor Performance =====
  Future<int> getTailorDeliveredCount({
    required String range,
    DateTime? periodAnchor,
  }) async {
    final anchor = periodAnchor ?? DateTime.now();
    final bounds = _tailorPerformanceRangeBounds(range, anchor);
    final profileId = StorageService.getUserId();
    final uid = SupabaseUtils.getCurrentUid();

    dynamic q = _db
        .from('customer_orders')
        .select('id,status,completed_at,order_date,created_at,tailor_id');

    if (profileId != null && profileId.isNotEmpty) {
      q = q.eq('tailor_id', profileId);
    } else if (uid != null && uid.isNotEmpty) {
      q = q.eq('tailor_id', uid);
    }

    // We use status=completed as your definition of delivered.
    q = q.eq('status', 'completed');

    final rows = await q;
    final list = (rows as List).cast<Map<String, dynamic>>();
    final filtered = list
        .where((o) => _completionInTailorRange(o, bounds.$1, bounds.$2))
        .length;
    return filtered;
  }

  Future<List<Map<String, dynamic>>> listTailorDeliveredOrdersRaw({
    required String range,
    DateTime? periodAnchor,
  }) async {
    final anchor = periodAnchor ?? DateTime.now();
    final bounds = _tailorPerformanceRangeBounds(range, anchor);
    final profileId = StorageService.getUserId();
    final uid = SupabaseUtils.getCurrentUid();

    dynamic q = _db
        .from('customer_orders')
        .select('id,status,completed_at,order_date,created_at,tailor_id,quantity');

    if (profileId != null && profileId.isNotEmpty) {
      q = q.eq('tailor_id', profileId);
    } else if (uid != null && uid.isNotEmpty) {
      q = q.eq('tailor_id', uid);
    }

    q = q.eq('status', 'completed');
    final rows = await q;
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list
        .where((o) => _completionInTailorRange(o, bounds.$1, bounds.$2))
        .toList();
  }

  // ===== Time logs (clock-in/out) =====
  Future<List<Map<String, dynamic>>> listMyTimeLogs() async {
    final uid = SupabaseUtils.getCurrentUid();
    if (uid == null) return <Map<String, dynamic>>[];
    final rows = await _db
        .from('time_logs')
        .select()
        .eq('user_id', uid)
        .order('clock_in', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<DateTime?> getMyActiveClockIn() async {
    final uid = SupabaseUtils.getCurrentUid();
    if (uid == null) return null;
    final rows = await _db
        .from('time_logs')
        .select('clock_in,clock_out')
        .eq('user_id', uid)
        .order('clock_in', ascending: false);
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      if (r['clock_out'] == null) return _parseDate(r['clock_in']);
    }
    return null;
  }

  Future<void> clockIn() async {
    final uid = SupabaseUtils.getCurrentUid();
    if (uid == null) return;
    await _db.from('time_logs').insert({
      'user_id': uid,
      'clock_in': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clockOut() async {
    final uid = SupabaseUtils.getCurrentUid();
    if (uid == null) return;
    final rows = await _db
        .from('time_logs')
        .select('id,clock_in,clock_out')
        .eq('user_id', uid)
        .order('clock_in', ascending: false);
    String? activeId;
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      if (r['clock_out'] == null) {
        activeId = r['id'] as String?;
        break;
      }
    }
    if (activeId == null) return;
    await _db.from('time_logs').update({
      'clock_out': DateTime.now().toIso8601String(),
    }).eq('id', activeId);
  }

  // ===== Seller Performance =====
  Future<SellerPerformanceStats> getSellerPerformance({
    required String range,
  }) async {
    final start = _rangeStart(range);
    final profileId = StorageService.getUserId();
    final uid = SupabaseUtils.getCurrentUid();

    dynamic q = _db
        .from('customer_orders')
        .select('id,created_at,created_by,initial_payment');

    if (profileId != null && profileId.isNotEmpty) {
      q = q.eq('created_by', profileId);
    } else if (uid != null && uid.isNotEmpty) {
      q = q.eq('created_by', uid);
    }

    final rows = await q;
    final list = (rows as List).cast<Map<String, dynamic>>();

    var count = 0;
    num paid = 0;
    final ordersByDay = <String, int>{};
    final paidByDay = <String, num>{};
    for (final o in list) {
      final createdAt = _parseDate(o['created_at']);
      if (createdAt == null) continue;
      if (createdAt.isBefore(start)) continue;
      count += 1;
      paid += (o['initial_payment'] as num?) ?? 0;

      final key =
          '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      ordersByDay[key] = (ordersByDay[key] ?? 0) + 1;
      paidByDay[key] = (paidByDay[key] ?? 0) + ((o['initial_payment'] as num?) ?? 0);
    }

    return SellerPerformanceStats(
      ordersCount: count,
      totalPaid: paid,
      ordersByDay: ordersByDay,
      paidByDay: paidByDay,
    );
  }
}

