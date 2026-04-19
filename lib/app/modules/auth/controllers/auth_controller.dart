import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/utils/storage_service.dart';
import '../../../../core/utils/supabase_utils.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_pages.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isSignUpMode = false.obs;

  void toggleMode() {
    errorMessage.value = '';
    isSignUpMode.value = !isSignUpMode.value;
  }

  void _offAllHomeNextFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.HOME);
    });
  }

  void _offAllAuthNextFrame() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.AUTH);
    });
  }

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final userJson = StorageService.getUser();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        currentUser.value =
            UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _offAllHomeNextFrame();
        return;
      } catch (_) {
        StorageService.clearAll();
      }
    }

    if (SupabaseUtils.isAuthenticated()) {
      final user = await SupabaseUtils.loadCurrentUser();
      if (user != null) {
        currentUser.value = user;
        _offAllHomeNextFrame();
      }
    }
  }

  Future<void> login(String emailOrPhone, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await SupabaseUtils.signInWithEmailOrPhoneAndPassword(
        emailOrPhone,
        password,
      );
      currentUser.value = user;
      _offAllHomeNextFrame();
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      errorMessage.value =
          msg.isNotEmpty ? msg : 'Login failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await SupabaseUtils.signUpWithProfile(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      currentUser.value = user;
      _offAllHomeNextFrame();
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').trim();
      errorMessage.value =
          msg.isNotEmpty ? msg : 'Signup failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await SupabaseUtils.signOut();
    currentUser.value = null;
    _offAllAuthNextFrame();
  }
}

