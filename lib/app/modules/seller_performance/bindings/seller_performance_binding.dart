import 'package:get/get.dart';

import '../controllers/seller_performance_controller.dart';

class SellerPerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerPerformanceController>(() => SellerPerformanceController());
  }
}

