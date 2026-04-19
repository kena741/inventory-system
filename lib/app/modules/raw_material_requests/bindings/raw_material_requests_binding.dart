import 'package:get/get.dart';

import '../controllers/raw_material_requests_controller.dart';

class RawMaterialRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RawMaterialRequestsController>(() => RawMaterialRequestsController());
  }
}

