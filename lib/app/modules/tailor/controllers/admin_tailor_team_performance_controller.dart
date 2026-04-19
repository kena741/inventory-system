import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class AdminTailorTeamPerformanceController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// Monday 00:00 local for the visible week.
  final weekStart = Rx<DateTime>(mondayOfWeekContaining(DateTime.now()));

  final RxList<Map<String, dynamic>> tailors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  final RxMap<String, String> tailorDisplayNames = <String, String>{}.obs;

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime mondayOfWeekContaining(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  DateTime get weekStartDay => _dateOnly(weekStart.value);

  DateTime get weekEndExclusive => weekStartDay.add(const Duration(days: 7));

  String _tailorLabelFromRow(Map<String, dynamic> t) {
    final fn = (t['first_name']?.toString() ?? '').trim();
    final ln = (t['last_name']?.toString() ?? '').trim();
    final n = [fn, ln].where((e) => e.isNotEmpty).join(' ').trim();
    return n.isEmpty ? 'Tailor' : n;
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final list = await _repo.listTailors();
      tailors.assignAll(list);

      final start = weekStartDay;
      final end = weekEndExclusive;
      final completed = await _repo.listCompletedOrdersForTailorTeam(
        rangeStartLocal: start,
        rangeEndExclusiveLocal: end,
      );
      orders.assignAll(completed);

      final names = <String, String>{};
      for (final t in list) {
        final id = (t['id']?.toString() ?? '').trim();
        if (id.isEmpty) continue;
        names[id] = _tailorLabelFromRow(t);
      }
      for (final o in completed) {
        final id = (o['tailor_id']?.toString() ?? '').trim();
        if (id.isEmpty || names.containsKey(id)) continue;
        final resolved = await _repo.getUserDisplayNameById(id);
        names[id] = (resolved ?? '').trim().isNotEmpty
            ? resolved!.trim()
            : 'Tailor ${id.length >= 6 ? id.substring(0, 6) : id}';
      }
      tailorDisplayNames.assignAll(names);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void goPrevWeek() {
    weekStart.value = weekStartDay.subtract(const Duration(days: 7));
    load();
  }

  void goNextWeek() {
    weekStart.value = weekStartDay.add(const Duration(days: 7));
    load();
  }

  DateTime? _completionLocal(Map<String, dynamic> o) {
    final raw = o['completed_at'] ?? o['order_date'];
    final dt = DateTime.tryParse(raw?.toString() ?? '');
    return dt?.toLocal();
  }

  int dayIndexForOrder(Map<String, dynamic> o) {
    final c = _completionLocal(o);
    if (c == null) return -1;
    final cDay = _dateOnly(c);
    return cDay.difference(weekStartDay).inDays;
  }

  /// Listed tailors first (stable), then any other tailor ids seen this week.
  List<String> columnTailorIds() {
    final ordered = <String>[];
    final seen = <String>{};
    for (final t in tailors) {
      final id = (t['id']?.toString() ?? '').trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      ordered.add(id);
    }
    final rest = <String>[];
    for (final o in orders) {
      final id = (o['tailor_id']?.toString() ?? '').trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      rest.add(id);
    }
    rest.sort();
    return [...ordered, ...rest];
  }

  String columnLabel(String tailorId) {
    return tailorDisplayNames[tailorId] ??
        tailors
            .where((t) => (t['id']?.toString() ?? '') == tailorId)
            .map(_tailorLabelFromRow)
            .firstOrNull ??
        tailorId;
  }

  int countForCell(String tailorId, int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) return 0;
    var n = 0;
    for (final o in orders) {
      if (dayIndexForOrder(o) != dayIndex) continue;
      if ((o['tailor_id']?.toString() ?? '').trim() == tailorId) n++;
    }
    return n;
  }

  int piecesForCell(String tailorId, int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) return 0;
    var qty = 0;
    for (final o in orders) {
      if (dayIndexForOrder(o) != dayIndex) continue;
      if ((o['tailor_id']?.toString() ?? '').trim() != tailorId) continue;
      qty += (o['quantity'] as int?) ?? 0;
    }
    return qty;
  }

  int maxCellCount(List<String> cols) {
    var m = 0;
    for (var d = 0; d < 7; d++) {
      for (final id in cols) {
        final v = countForCell(id, d);
        if (v > m) m = v;
      }
    }
    return m;
  }

  int dayTotalDelivered(int dayIndex) {
    var n = 0;
    for (final o in orders) {
      if (dayIndexForOrder(o) == dayIndex) n++;
    }
    return n;
  }

  int tailorWeekTotal(String tailorId) {
    var n = 0;
    for (var d = 0; d < 7; d++) {
      n += countForCell(tailorId, d);
    }
    return n;
  }

  int weekGrandTotal() => orders.length;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
