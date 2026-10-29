import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezo_core_models/ezo_core_models.dart';

/// Manages persistent session storage across app launches.
/// Automatically restores active merchant login so merchants do not have to
/// re-enter their phone number and PIN every time the app closes.
class SessionManager {
  static const String _keyIsLoggedIn = 'bh_is_logged_in';
  static const String _keyActivePhone = 'bh_active_phone';
  static const String _keyActiveStoreId = 'bh_active_store_id';
  static const String _keyActiveStaffId = 'bh_active_staff_id';
  static const String _keyAuthToken = 'bh_auth_token';
  static const String _keyActiveProfileJson = 'bh_active_profile_json';
  static const String _keyActiveStaffJson = 'bh_active_staff_json';

  static SharedPreferences? _prefs;

  /// Initialize with pre-loaded SharedPreferences instance from main()
  static void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static bool isLoggedIn() {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  static String? getActivePhone() {
    return _prefs?.getString(_keyActivePhone);
  }

  static String? getActiveStoreId() {
    return _prefs?.getString(_keyActiveStoreId);
  }

  static String? getActiveStaffId() {
    return _prefs?.getString(_keyActiveStaffId);
  }

  static String? getAuthToken() {
    return _prefs?.getString(_keyAuthToken);
  }

  static BusinessProfile? getActiveProfile() {
    final str = _prefs?.getString(_keyActiveProfileJson);
    if (str == null || str.isEmpty) return null;
    try {
      return BusinessProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static StaffMember? getActiveStaff() {
    final str = _prefs?.getString(_keyActiveStaffJson);
    if (str == null || str.isEmpty) return null;
    try {
      return StaffMember.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession({
    required String phone,
    required String storeId,
    required String staffId,
    String? token,
    BusinessProfile? profile,
    StaffMember? staff,
  }) async {
    try {
      final prefs = await _ensurePrefs();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyActivePhone, phone);
      await prefs.setString(_keyActiveStoreId, storeId);
      await prefs.setString(_keyActiveStaffId, staffId);
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyAuthToken, token);
      }
      if (profile != null) {
        await prefs.setString(_keyActiveProfileJson, jsonEncode(profile.toJson()));
      }
      if (staff != null) {
        await prefs.setString(_keyActiveStaffJson, jsonEncode(staff.toJson()));
      }
    } catch (_) {}
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await _ensurePrefs();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyActivePhone);
      await prefs.remove(_keyActiveStoreId);
      await prefs.remove(_keyActiveStaffId);
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyActiveProfileJson);
      await prefs.remove(_keyActiveStaffJson);
    } catch (_) {}
  }
}
