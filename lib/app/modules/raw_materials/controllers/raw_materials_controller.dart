import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class RawMaterialsController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> materials = <Map<String, dynamic>>[].obs;
  final RxBool isTableView = true.obs;

  @override
  void onInit() {
    super.onInit();
    refreshMaterials();
  }

  Future<void> refreshMaterials() async {
    try {
      isLoading.value = true;
      error.value = '';
      materials.value = await _repo.listRawMaterials();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create({
    required String name,
    required String unit,
    required num newQuantity,
    required num unitPrice,
  }) async {
    await _repo.createRawMaterial(
      name: name,
      unit: unit,
      newQuantity: newQuantity,
      unitPrice: unitPrice,
    );
    await refreshMaterials();
  }

  Future<void> remove(String id) async {
    await _repo.deleteRawMaterial(id);
    await refreshMaterials();
  }

  void toggleTableView(bool v) => isTableView.value = v;
}

