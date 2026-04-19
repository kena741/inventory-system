import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

enum PerformanceRange { day, week, month }

class SellerPerformanceController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<PerformanceRange> range = PerformanceRange.day.obs;

  final RxInt ordersCount = 0.obs;
  final Rx<num> totalPaid = 0.obs;
  final RxList<MapEntry<String, int>> ordersByDay =
      <MapEntry<String, int>>[].obs;
  final RxList<MapEntry<String, num>> paidByDay =
      <MapEntry<String, num>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setRange(PerformanceRange r) async {
    range.value = r;
    await load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      final stats = await _repo.getSellerPerformance(range: range.value.name);
      ordersCount.value = stats.ordersCount;
      totalPaid.value = stats.totalPaid;
      final oEntries = stats.ordersByDay.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      final pEntries = stats.paidByDay.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      ordersByDay.value = oEntries;
      paidByDay.value = pEntries;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

