import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';

class AndroidBluetoothPrinterDriver implements PrinterTransportDriver {
  static const MethodChannel _channel = MethodChannel('com.bharathisab.pos/bluetooth_printer');

  static const List<DiscoveredPrinterDevice> _virtualFallbacks = [
    DiscoveredPrinterDevice(
      id: 'SYS_PRINT',
      name: 'System Print / PDF Dialog (Desktop/Web)',
      connectionType: PrinterConnectionType.virtualPreview,
      address: 'browser_system_print',
      isBonded: true,
    ),
    DiscoveredPrinterDevice(
      id: 'VIRTUAL_58',
      name: 'Virtual Chota 58mm Monospace Preview',
      connectionType: PrinterConnectionType.virtualPreview,
      address: '127.0.0.1:58',
      isBonded: false,
    ),
  ];

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect(String address) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _connected = true;
      return true;
    }

    try {
      final success = await _channel.invokeMethod<bool>('connect', {'address': address});
      _connected = success == true;
      return _connected;
    } on MissingPluginException {
      // In test runner or unsupported native desktop target
      _connected = true;
      return true;
    } catch (e) {
      debugPrint('[BT_DRIVER] Connect error: $e');
      _connected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _connected = false;
      return;
    }

    try {
      await _channel.invokeMethod('disconnect');
    } on MissingPluginException {
      // Ignored in test / non-native
    } catch (e) {
      debugPrint('[BT_DRIVER] Disconnect error: $e');
    } finally {
      _connected = false;
    }
  }

  @override
  Future<bool> sendBytes(Uint8List bytes) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final success = await _channel.invokeMethod<bool>('sendBytes', {'bytes': bytes});
      return success == true;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('[BT_DRIVER] SendBytes error: $e');
      return false;
    }
  }

  @override
  Future<List<DiscoveredPrinterDevice>> scanDevices({bool activeDiscovery = false}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _virtualFallbacks;
    }

    final results = <DiscoveredPrinterDevice>[];

    // 1. Fetch bonded/paired devices
    try {
      final List<dynamic>? bondedList = await _channel.invokeMethod('getBondedDevices');
      if (bondedList != null) {
        for (final item in bondedList) {
          final map = Map<String, dynamic>.from(item as Map);
          results.add(DiscoveredPrinterDevice(
            id: map['address'] as String,
            name: map['name'] as String? ?? 'Paired Thermal Printer',
            connectionType: PrinterConnectionType.bluetoothSpp,
            address: map['address'] as String,
            isBonded: true,
          ));
        }
      }
    } on MissingPluginException {
      // Native Kotlin channel unavailable (e.g. Flutter test VM on Windows)
      return _virtualFallbacks;
    } catch (e) {
      debugPrint('[BT_DRIVER] getBondedDevices error: $e');
    }

    // 2. Active discovery for nearby unbonded devices if requested
    if (activeDiscovery) {
      try {
        await _channel.invokeMethod('startDiscovery');
        // Allow radio to scan nearby broadcasting devices
        await Future.delayed(const Duration(milliseconds: 3500));
        final List<dynamic>? discoveredList = await _channel.invokeMethod('getDiscoveredDevices');
        await _channel.invokeMethod('stopDiscovery');

        if (discoveredList != null) {
          for (final item in discoveredList) {
            final map = Map<String, dynamic>.from(item as Map);
            final addr = map['address'] as String;
            if (!results.any((d) => d.address == addr)) {
              results.add(DiscoveredPrinterDevice(
                id: addr,
                name: map['name'] as String? ?? 'Nearby Bluetooth Printer',
                connectionType: PrinterConnectionType.bluetoothSpp,
                address: addr,
                isBonded: false,
              ));
            }
          }
        }
      } on MissingPluginException {
        // Ignored in test / non-native
      } catch (e) {
        debugPrint('[BT_DRIVER] Active discovery error: $e');
      }
    }

    return results;
  }
}
