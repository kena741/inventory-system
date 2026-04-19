import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';
import '../../../models/erp/location_model.dart';

class LocationsController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<LocationModel> locations = <LocationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshLocations();
  }

  Future<void> refreshLocations() async {
    try {
      isLoading.value = true;
      error.value = '';
      locations.value = await _repo.listLocations();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createLocation({
    required String name,
    required String type,
  }) async {
    await _repo.createLocation(name: name, type: type);
    await refreshLocations();
  }

  Future<void> deleteLocation(String id) async {
    await _repo.deleteLocation(id);
    await refreshLocations();
  }
}

