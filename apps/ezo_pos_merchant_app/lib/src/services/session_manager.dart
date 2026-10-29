import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent session storage across app launches.
/// Automatically restores active merchant login so merchants do not have to
/// re-enter their phone number and PIN every time the app closes.
class SessionManager {
  static const String _keyIsLoggedIn = 'bh_is_logged_in';
  static const String _keyActivePhone = 'bh_active_phone';
  static const String _keyActiveStoreId = 'bh_active_store_id';
  static const String _keyActiveStaffId = 'bh_active_staff_id';
  static const String _keyAuthToken = 'bh_auth_token';

  static Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 300));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession({
    required String phone,
    required String storeId,
    required String staffId,
    String? token,
  }) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyActivePhone, phone);
      await prefs.setString(_keyActiveStoreId, storeId);
      await prefs.setString(_keyActiveStaffId, staffId);
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyAuthToken, token);
      }
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await _getPrefs();
      return prefs?.getBool(_keyIsLoggedIn) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getActivePhone() async {
    try {
      final prefs = await _getPrefs();
      return prefs?.getString(_keyActivePhone);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getActiveStoreId() async {
    try {
      final prefs = await _getPrefs();
      return prefs?.getString(_keyActiveStoreId);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getActiveStaffId() async {
    try {
      final prefs = await _getPrefs();
      return prefs?.getString(_keyActiveStaffId);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs?.getString(_keyAuthToken);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyActivePhone);
      await prefs.remove(_keyActiveStoreId);
      await prefs.remove(_keyActiveStaffId);
      await prefs.remove(_keyAuthToken);
    } catch (_) {}
  }
}
