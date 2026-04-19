import 'package:get/get.dart';

import '../controllers/raw_materials_controller.dart';

class RawMaterialsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RawMaterialsController>(() => RawMaterialsController());
  }
}

