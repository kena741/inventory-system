import 'package:get_storage/get_storage.dart';

class StorageService {
  static final GetStorage _storage = GetStorage();

  // User data
  static void saveUser(String userJson) {
    _storage.write('user', userJson);
  }

  static String? getUser() {
    return _storage.read('user');
  }

  static void removeUser() {
    _storage.remove('user');
  }

  // Auth token
  static void saveToken(String token) {
    _storage.write('token', token);
  }

  static String? getToken() {
    return _storage.read('token');
  }

  static void removeToken() {
    _storage.remove('token');
  }

  static void saveUserId(String userId) {
    _storage.write('user_id', userId);
  }

  static String? getUserId() {
    return _storage.read('user_id');
  }

  static void removeUserId() {
    _storage.remove('user_id');
  }

  static void clearAll() {
    _storage.erase();
  }
}

