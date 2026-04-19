import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/utils/storage_service.dart';
import '../../../models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final userJson = StorageService.getUser();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        user.value =
            UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    await Get.find<AuthController>().logout();
  }

  void setTab(int index) {
    tabIndex.value = index;
  }
}

