import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

abstract class SharedPreferencesProvider {
  Future<String?> getUserId();
  Future<void> setUserId(String userId);
}

class SharedPreferencesRepository implements SharedPreferencesProvider {
  static const String _userIdKey = 'user_id';

  late SharedPreferences _prefs;

  SharedPreferencesRepository._();

  static Future<SharedPreferencesRepository> create() async {
    final repository = SharedPreferencesRepository._();
    await repository._initialize();
    return repository;
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize SharedPreferences: $e');
      }
      rethrow;
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      return _prefs.getString(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get user ID: $e');
      }
      return null;
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await _prefs.setString(_userIdKey, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user ID: $e');
      }
      rethrow;
    }
  }
}
