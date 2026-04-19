import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/models/user_model.dart';
import 'storage_service.dart';

class SupabaseUtils {
  static final _client = Supabase.instance.client;

  static String? getCurrentUid() => _client.auth.currentUser?.id;

  static Session? getCurrentSession() => _client.auth.currentSession;

  static bool isAuthenticated() => _client.auth.currentUser != null;

  static Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await _client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw const AuthException(
              'Request timed out. Please check your internet connection and try again.',
            );
          },
        );

    if (response.user == null || response.session == null) {
      throw const AuthException('Invalid login credentials');
    }

    return response;
  }

  static Future<UserModel> signUpWithProfile({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPhone = phone.trim();

    final authResponse = await _client.auth
        .signUp(
          email: trimmedEmail,
          password: password,
          data: {
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'phone': trimmedPhone,
          },
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw const AuthException(
              'Request timed out. Please check your internet connection and try again.',
            );
          },
        );

    final uid = authResponse.user?.id;
    if (uid == null) {
      throw const AuthException('Signup failed. Please try again.');
    }

    // Your updated ERP `public.users` has: first_name, last_name, phone_number,
    // and user_id (FK to auth.users.id). We'll upsert by user_id.
    await _client.from('users').upsert({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'phone_number': trimmedPhone,
      'email': trimmedEmail,
      'user_id': uid,
      'role': 'seller',
      'created_at': DateTime.now().toIso8601String(),
    });

    final profile = await loadCurrentUser();
    if (profile == null) {
      throw Exception(
        'Account created, but profile was not found. Please contact your administrator.',
      );
    }

    return profile;
  }

  /// Creates a new auth user + profile while keeping the current session intact.
  ///
  /// This is intended for admin provisioning flows in client apps where
  /// service-role admin APIs are not available.
  static Future<void> createUserWithProfileKeepingSession({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role,
  }) async {
    final previousSession = getCurrentSession();
    final previousRefreshToken = previousSession?.refreshToken;
    if (previousRefreshToken == null || previousRefreshToken.isEmpty) {
      throw Exception('Admin session is missing refresh token.');
    }

    final trimmedEmail = email.trim();
    final trimmedPhone = phone.trim();

    try {
      final authResponse = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': trimmedPhone,
        },
      );

      final uid = authResponse.user?.id;
      if (uid == null) {
        throw const AuthException('Signup failed. Please try again.');
      }

      await _client.from('users').upsert({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone_number': trimmedPhone,
        'email': trimmedEmail,
        'user_id': uid,
        'role': role.trim().toLowerCase(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } finally {
      // Restore previous admin session.
      await _client.auth.setSession(previousRefreshToken);
      await loadCurrentUser();
    }
  }

  /// Allows phone input by mapping phone -> email via `public.users`.
  static Future<UserModel> signInWithEmailOrPhoneAndPassword(
    String emailOrPhone,
    String password,
  ) async {
    var loginEmail = emailOrPhone.trim();

    if (!loginEmail.contains('@')) {
      final row = await _client
          .from('users')
          .select('email, phone_number')
          .eq('phone_number', loginEmail)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your internet connection and try again.',
              );
            },
          );

      final foundEmail = row?['email'] as String?;
      if (foundEmail == null || foundEmail.isEmpty) {
        throw Exception(
          'Phone number not found. Please check your phone number and try again.',
        );
      }
      loginEmail = foundEmail;
    }

    await signInWithEmailAndPassword(loginEmail, password);

    final profile = await loadCurrentUser().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Profile load timed out. Please try again.');
      },
    );

    if (profile == null) {
      throw Exception(
        'Account profile not found. Please contact your administrator.',
      );
    }

    return profile;
  }

  static Future<UserModel?> loadCurrentUser() async {
    try {
      final uid = getCurrentUid();
      if (uid == null) return null;

      // Prefer ERP `users` table.
      Map<String, dynamic>? row = await _client
          .from('users')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) return null;

      final user = UserModel.fromJson(row);

      StorageService.saveUser(jsonEncode(user.toJson()));
      StorageService.saveUserId(user.id);

      final session = getCurrentSession();
      if (session != null) {
        StorageService.saveToken(session.accessToken);
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } finally {
      StorageService.clearAll();
    }
  }
}

