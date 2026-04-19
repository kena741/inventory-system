import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class ExpensesController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> expenses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshExpenses();
  }

  Future<void> refreshExpenses() async {
    try {
      isLoading.value = true;
      error.value = '';
      expenses.value = await _repo.listExpenses();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createExpense({
    required String category,
    required num amount,
    required String locationId,
    String? description,
  }) async {
    await _repo.createExpense(
      category: category,
      amount: amount,
      locationId: locationId,
      description: description,
    );
    await refreshExpenses();
  }
}

