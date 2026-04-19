import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class AssignedOrdersController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshAssigned();
  }

  Future<void> refreshAssigned() async {
    try {
      isLoading.value = true;
      error.value = '';
      orders.value = await _repo.listAssignedOrdersForCurrentTailor();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

