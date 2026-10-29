import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized service for requesting and verifying Android hardware permissions:
/// - Bluetooth (Nearby Devices `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` on Android 12+)
/// - Location (`ACCESS_FINE_LOCATION` on Android 11 and below)
/// - Camera (`android.permission.CAMERA` for barcode scanning & product photos)
class HardwarePermissionService {
  static const MethodChannel _channel = MethodChannel('com.bharathisab.pos/permissions');

  /// Check current status of all hardware permissions without prompting
  static Future<Map<String, bool>> checkPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return {'allGranted': true, 'bluetooth': true, 'camera': true};
    }

    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPermissions');
      if (res == null) return {'allGranted': true};
      return res.map((k, v) => MapEntry(k.toString(), v == true));
    } catch (_) {
      return {'allGranted': true};
    }
  }

  /// Request all necessary hardware permissions (triggers Android OS system popup)
  static Future<bool> requestAllHardwarePermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>('requestPermissions');
      return res ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Request Bluetooth & Location permissions specifically
  static Future<bool> ensureBluetoothPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>('requestBluetoothPermission');
      return res ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Request Camera permission specifically
  static Future<bool> ensureCameraPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>('requestCameraPermission');
      return res ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }
}
