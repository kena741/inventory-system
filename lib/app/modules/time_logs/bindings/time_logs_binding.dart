import 'package:get/get.dart';

import '../controllers/time_logs_controller.dart';

class TimeLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimeLogsController>(() => TimeLogsController());
  }
}

