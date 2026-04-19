import 'package:get/get.dart';

import '../controllers/vendors_controller.dart';

class VendorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VendorsController>(() => VendorsController());
  }
}

