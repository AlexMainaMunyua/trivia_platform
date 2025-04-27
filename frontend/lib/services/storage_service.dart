import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    await _prefs.remove('auth_token');
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString('user_data', jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final userData = _prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}