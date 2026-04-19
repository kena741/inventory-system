import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class VendorsController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> vendors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshVendors();
  }

  Future<void> refreshVendors() async {
    try {
      isLoading.value = true;
      error.value = '';
      vendors.value = await _repo.listVendors();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createVendor({
    required String name,
    String? phone,
    String? address,
  }) async {
    await _repo.createVendor(name: name, phone: phone, address: address);
    await refreshVendors();
  }

  Future<void> updateVendor({
    required String id,
    required String name,
    String? phone,
    String? address,
  }) async {
    await _repo.updateVendor(id: id, name: name, phone: phone, address: address);
    await refreshVendors();
  }

  Future<void> deleteVendor(String id) async {
    await _repo.deleteVendor(id);
    await refreshVendors();
  }
}

