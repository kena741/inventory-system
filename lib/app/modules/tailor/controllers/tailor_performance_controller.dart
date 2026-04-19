import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

enum PerformanceRange { day, week, month }

class TailorPerformanceController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<PerformanceRange> range = PerformanceRange.day.obs;

  /// Local calendar day that defines which day / week / month is shown.
  final Rx<DateTime> periodAnchor = Rx<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  final RxInt deliveredCount = 0.obs;
  final RxList<MapEntry<String, int>> deliveredByDay =
      <MapEntry<String, int>>[].obs;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static DateTime _dateOnlyLocal(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Start of the filter window (local calendar), aligned with [ErpRepository] `day` / `week` / `month`.
  DateTime _filterWindowStart(PerformanceRange r) {
    final anchor = _dateOnlyLocal(periodAnchor.value.toLocal());
    switch (r) {
      case PerformanceRange.day:
        return anchor;
      case PerformanceRange.week:
        final start =
            anchor.subtract(Duration(days: anchor.weekday - DateTime.monday));
        return _dateOnlyLocal(start);
      case PerformanceRange.month:
        return DateTime(anchor.year, anchor.month, 1);
    }
  }

  /// Short label for the date selector (depends on [range] + [periodAnchor]).
  String get anchorSummary {
    final start = _filterWindowStart(range.value);
    switch (range.value) {
      case PerformanceRange.day:
        return _formatLongDate(start);
      case PerformanceRange.week:
        final end = start.add(const Duration(days: 6));
        if (start.year == end.year) {
          if (start.month == end.month) {
            return '${_months[start.month - 1]} ${start.day}–${end.day}, ${start.year}';
          }
          return '${_months[start.month - 1]} ${start.day} – ${_months[end.month - 1]} ${end.day}, ${end.year}';
        }
        return '${_months[start.month - 1]} ${start.day}, ${start.year} – ${_months[end.month - 1]} ${end.day}, ${end.year}';
      case PerformanceRange.month:
        return _monthYear(start);
    }
  }

  /// Human-readable description of which dates are included.
  String get periodCaption {
    final start = _filterWindowStart(range.value);
    switch (range.value) {
      case PerformanceRange.day:
        return 'Showing completions on ${_formatLongDate(start)} (your local day).';
      case PerformanceRange.week:
        final end = start.add(const Duration(days: 6));
        return 'Showing completions from ${_formatLongDate(start)} through ${_formatLongDate(end)} (calendar week Mon–Sun, local).';
      case PerformanceRange.month:
        return 'Showing completions in ${_monthYear(start)} (local calendar month).';
    }
  }

  static String _monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static String _formatLongDate(DateTime d) {
    final wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final w = wd[d.weekday - 1];
    return '$w, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// Display label for a bucket key (`yyyy-MM-dd` or internal unknown key).
  static String formatDayBucketTitle(String key) {
    if (key == '__unknown__') {
      return 'Date not on record (used order created time for period only)';
    }
    final d = DateTime.tryParse(key);
    if (d == null) return key;
    final local = _dateOnlyLocal(d.toLocal());
    return _formatLongDate(local);
  }

  /// Same precedence as [ErpRepository] tailor delivered filter: completed → order → created.
  static DateTime? _completionLocal(Map<String, dynamic> o) {
    for (final key in ['completed_at', 'order_date', 'created_at']) {
      final v = o[key];
      if (v == null) continue;
      if (v is DateTime) return v.toLocal();
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt.toLocal();
      }
    }
    return null;
  }

  static String? _daySortKey(Map<String, dynamic> o) {
    final local = _completionLocal(o);
    if (local == null) return null;
    final d = _dateOnlyLocal(local);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setRange(PerformanceRange r) async {
    range.value = r;
    await load();
  }

  /// Previous / next period (day ±1, week ±7 days, month ±1 calendar month).
  Future<void> shiftPeriod(int direction) async {
    assert(direction == -1 || direction == 1);
    final a = periodAnchor.value;
    switch (range.value) {
      case PerformanceRange.day:
        periodAnchor.value = _dateOnlyLocal(
          a.toLocal().add(Duration(days: direction)),
        );
      case PerformanceRange.week:
        periodAnchor.value = _dateOnlyLocal(
          a.toLocal().add(Duration(days: 7 * direction)),
        );
      case PerformanceRange.month:
        periodAnchor.value = DateTime(a.year, a.month + direction, 1);
    }
    await load();
  }

  Future<void> goToToday() async {
    final n = DateTime.now();
    periodAnchor.value = DateTime(n.year, n.month, n.day);
    await load();
  }

  Future<void> pickAnchorDate() async {
    final context = Get.context;
    if (context == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: periodAnchor.value,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      periodAnchor.value = _dateOnlyLocal(picked.toLocal());
      await load();
    }
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final rows = await _repo.listTailorDeliveredOrdersRaw(
        range: range.value.name,
        periodAnchor: periodAnchor.value,
      );
      final map = <String, int>{};
      for (final o in rows) {
        final key = _daySortKey(o);
        if (key == null) {
          map['__unknown__'] = (map['__unknown__'] ?? 0) + 1;
        } else {
          map[key] = (map[key] ?? 0) + 1;
        }
      }
      final entries = map.entries.toList()
        ..sort((a, b) {
          if (a.key == '__unknown__') return 1;
          if (b.key == '__unknown__') return -1;
          return b.key.compareTo(a.key);
        });
      deliveredByDay.value = entries;
      deliveredCount.value = rows.length;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
