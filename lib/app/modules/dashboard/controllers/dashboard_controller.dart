import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';
import '../../../models/erp/location_model.dart';

class DashboardController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxInt locationsCount = 0.obs;
  final RxInt rawMaterialsCount = 0.obs;
  final RxDouble rawInventoryValue = 0.0.obs;

  final RxInt ordersTotal = 0.obs;
  final RxInt ordersPending = 0.obs;
  final RxInt ordersInProgress = 0.obs;
  final RxInt ordersCompleted = 0.obs;
  final RxDouble ordersOutstanding = 0.0.obs;

  final RxInt expensesCount = 0.obs;
  final RxDouble expensesThisMonth = 0.0.obs;

  final RxInt rawRequestsTotal = 0.obs;
  final RxInt rawRequestsPendingAdmin = 0.obs;
  final RxInt rawRequestsInPipeline = 0.obs;

  @override
  void onInit() {
    super.onInit();
    refreshSummary();
  }

  static bool _isOrderStatus(String row, String target) =>
      (row).trim().toLowerCase() == target;

  static DateTime? _parseExpenseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  Future<void> refreshSummary() async {
    try {
      isLoading.value = true;
      error.value = '';
      final results = await Future.wait<dynamic>([
        _repo.listLocations(),
        _repo.listRawMaterials(),
        _repo.listCustomerOrders(),
        _repo.listExpenses(),
        _repo.listRawMaterialRequests(),
      ]);

      final locs = results[0] as List<LocationModel>;
      locationsCount.value = locs.length;

      final materials = results[1] as List<Map<String, dynamic>>;
      rawMaterialsCount.value = materials.length;
      num inv = 0;
      for (final m in materials) {
        inv += (m['total_price'] as num?) ?? 0;
      }
      rawInventoryValue.value = inv.toDouble();

      final orders = results[2] as List<Map<String, dynamic>>;
      ordersTotal.value = orders.length;
      var p = 0, ip = 0, c = 0;
      num outstanding = 0;
      for (final o in orders) {
        final s = (o['status']?.toString() ?? 'pending').trim().toLowerCase();
        if (_isOrderStatus(s, 'pending')) p++;
        if (_isOrderStatus(s, 'in_progress')) ip++;
        if (_isOrderStatus(s, 'completed')) c++;
        outstanding += (o['remaining_payment'] as num?) ?? 0;
      }
      ordersPending.value = p;
      ordersInProgress.value = ip;
      ordersCompleted.value = c;
      ordersOutstanding.value = outstanding.toDouble();

      final expenses = results[3] as List<Map<String, dynamic>>;
      expensesCount.value = expenses.length;
      final now = DateTime.now();
      num month = 0;
      for (final e in expenses) {
        final d = _parseExpenseDate(e['date']);
        if (d != null && d.year == now.year && d.month == now.month) {
          month += (e['amount'] as num?) ?? 0;
        }
      }
      expensesThisMonth.value = month.toDouble();

      final requests = results[4] as List<Map<String, dynamic>>;
      rawRequestsTotal.value = requests.length;
      var pendingAdmin = 0;
      var pipeline = 0;
      for (final r in requests) {
        final s = (r['status']?.toString() ?? 'pending').trim().toLowerCase();
        if (s == 'pending') pendingAdmin++;
        if (s == 'approved' || s == 'ordered' || s == 'seller_confirmed') {
          pipeline++;
        }
      }
      rawRequestsPendingAdmin.value = pendingAdmin;
      rawRequestsInPipeline.value = pipeline;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
