import 'package:get/get.dart';

import '../controllers/assigned_orders_controller.dart';
import '../controllers/tailor_performance_controller.dart';

class TailorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssignedOrdersController>(() => AssignedOrdersController());
    Get.lazyPut<TailorPerformanceController>(() => TailorPerformanceController());
  }
}

