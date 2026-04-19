import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/utils/storage_service.dart';
import '../../../../core/utils/supabase_utils.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';

      final cached = StorageService.getUser();
      if (cached != null && cached.isNotEmpty) {
        try {
          user.value = UserModel.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      if (SupabaseUtils.isAuthenticated()) {
        final refreshed = await SupabaseUtils.loadCurrentUser();
        if (refreshed != null) user.value = refreshed;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      error.value = '';
      await SupabaseUtils.signOut();
    } catch (e) {
      // Even if remote sign-out fails, we still clear local state and route out.
      error.value = e.toString();
      StorageService.clearAll();
    } finally {
      isLoading.value = false;
      user.value = null;
      Get.offAllNamed(Routes.AUTH);
    }
  }
}

