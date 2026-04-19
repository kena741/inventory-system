import 'package:get/get.dart';

import '../modules/auth/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      // Eager + permanent so role is ready before HomeView builds.
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}

