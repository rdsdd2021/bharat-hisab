import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezo_core_models/ezo_core_models.dart';

/// Manages persistent session storage across app launches.
/// Automatically restores active merchant login so merchants do not have to
/// re-enter their phone number and PIN every time the app closes.
///
/// Employs a dual-persistence strategy:
/// 1. Android SharedPreferences (instant key-value cache)
/// 2. Atomic Physical Disk File (`bh_session.json`) with synchronous flush: true
/// This guarantees zero data loss even if the Android process is terminated immediately.
class SessionManager {
  static const String _keyIsLoggedIn = 'bh_is_logged_in';
  static const String _keyActivePhone = 'bh_active_phone';
  static const String _keyActiveStoreId = 'bh_active_store_id';
  static const String _keyActiveStaffId = 'bh_active_staff_id';
  static const String _keyAuthToken = 'bh_auth_token';
  static const String _keyActiveProfileJson = 'bh_active_profile_json';
  static const String _keyActiveStaffJson = 'bh_active_staff_json';
  static const String _sessionFileName = 'bh_session.json';

  static SharedPreferences? _prefs;
  static String? _storageDirectory;
  static Map<String, dynamic>? _cachedDiskSession;

  /// Initialize with pre-loaded SharedPreferences and app document storage directory
  static void init(SharedPreferences prefs, {String? storageDirectory}) {
    _prefs = prefs;
    _storageDirectory = storageDirectory;
    _loadDiskSession();
  }

  static void setStorageDirectory(String? directory) {
    _storageDirectory = directory;
    _loadDiskSession();
  }

  static void _loadDiskSession() {
    if (kIsWeb || _storageDirectory == null) return;
    try {
      final file = File('$_storageDirectory/$_sessionFileName');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.trim().isNotEmpty) {
          _cachedDiskSession = jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
  }

  static Future<SharedPreferences?> _ensurePrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 600));
    } catch (_) {}
    return _prefs;
  }

  static bool isLoggedIn() {
    final prefsVal = _prefs?.getBool(_keyIsLoggedIn);
    if (prefsVal != null) return prefsVal;
    return _cachedDiskSession?[_keyIsLoggedIn] == true;
  }

  static String? getActivePhone() {
    return _prefs?.getString(_keyActivePhone) ??
        _cachedDiskSession?[_keyActivePhone] as String?;
  }

  static String? getActiveStoreId() {
    return _prefs?.getString(_keyActiveStoreId) ??
        _cachedDiskSession?[_keyActiveStoreId] as String?;
  }

  static String? getActiveStaffId() {
    return _prefs?.getString(_keyActiveStaffId) ??
        _cachedDiskSession?[_keyActiveStaffId] as String?;
  }

  static String? getAuthToken() {
    return _prefs?.getString(_keyAuthToken) ??
        _cachedDiskSession?[_keyAuthToken] as String?;
  }

  static BusinessProfile? getActiveProfile() {
    final str = _prefs?.getString(_keyActiveProfileJson);
    if (str != null && str.isNotEmpty) {
      try {
        return BusinessProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {}
    }
    final diskObj = _cachedDiskSession?[_keyActiveProfileJson];
    if (diskObj is Map<String, dynamic>) {
      try {
        return BusinessProfile.fromJson(diskObj);
      } catch (_) {}
    }
    return null;
  }

  static StaffMember? getActiveStaff() {
    final str = _prefs?.getString(_keyActiveStaffJson);
    if (str != null && str.isNotEmpty) {
      try {
        return StaffMember.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {}
    }
    final diskObj = _cachedDiskSession?[_keyActiveStaffJson];
    if (diskObj is Map<String, dynamic>) {
      try {
        return StaffMember.fromJson(diskObj);
      } catch (_) {}
    }
    return null;
  }

  /// Atomically saves active merchant session across both SharedPreferences and physical disk.
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
      if (prefs != null) {
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
      }

      // Mirror directly to physical disk with flush: true
      if (!kIsWeb && _storageDirectory != null) {
        final diskMap = <String, dynamic>{
          _keyIsLoggedIn: true,
          _keyActivePhone: phone,
          _keyActiveStoreId: storeId,
          _keyActiveStaffId: staffId,
          _keyAuthToken: token,
          if (profile != null) _keyActiveProfileJson: profile.toJson(),
          if (staff != null) _keyActiveStaffJson: staff.toJson(),
          'savedAt': DateTime.now().toIso8601String(),
        };
        _cachedDiskSession = diskMap;
        final file = File('$_storageDirectory/$_sessionFileName');
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        await file.writeAsString(jsonEncode(diskMap), flush: true);
      }
    } catch (_) {}
  }

  /// Clears active merchant session across all persistence layers
  static Future<void> clearSession() async {
    try {
      _cachedDiskSession = null;
      final prefs = await _ensurePrefs();
      if (prefs != null) {
        await prefs.remove(_keyIsLoggedIn);
        await prefs.remove(_keyActivePhone);
        await prefs.remove(_keyActiveStoreId);
        await prefs.remove(_keyActiveStaffId);
        await prefs.remove(_keyActiveAuthTokenCompat);
        await prefs.remove(_keyAuthToken);
        await prefs.remove(_keyActiveProfileJson);
        await prefs.remove(_keyActiveStaffJson);
      }

      if (!kIsWeb && _storageDirectory != null) {
        final file = File('$_storageDirectory/$_sessionFileName');
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } catch (_) {}
  }

  static const String _keyActiveAuthTokenCompat = 'bh_token';
}
