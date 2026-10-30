import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';

class DiscoveredScaleDevice {
  final String name;
  final String address;
  final String type; // 'bluetooth' or 'usb'

  const DiscoveredScaleDevice({
    required this.name,
    required this.address,
    required this.type,
  });
}

class AndroidWeighingScaleDriver implements WeighingScaleDriver {
  static const MethodChannel _channel = MethodChannel('com.bharathisab.pos/weighing_scale');
  static const EventChannel _streamChannel = EventChannel('com.bharathisab.pos/weighing_scale_stream');

  /// Open Android OS Bluetooth Settings page directly to pair scales
  static Future<void> openBluetoothSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      const printerChannel = MethodChannel('com.bharathisab.pos/bluetooth_printer');
      await printerChannel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  bool _connected = false;
  WeighingScaleReading _latestReading = WeighingScaleReading.zero();
  StreamSubscription? _rawSubscription;

  final StreamController<WeighingScaleReading> _readingController =
      StreamController<WeighingScaleReading>.broadcast();

  // Simulated fallback driver for web, desktop and tests
  final VirtualSimulatedWeighingScaleDriver _simulatedFallback =
      VirtualSimulatedWeighingScaleDriver();

  AndroidWeighingScaleDriver() {
    _simulatedFallback.readingStream.listen((r) {
      if (!_connectedToNative) {
        _latestReading = r;
        _readingController.add(r);
      }
    });
  }

  bool _connectedToNative = false;

  @override
  bool get isConnected => _connected;

  @override
  WeighingScaleReading get latestReading => _latestReading;

  @override
  Stream<WeighingScaleReading> get readingStream => _readingController.stream;

  Future<List<DiscoveredScaleDevice>> getAvailableScales() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [
        DiscoveredScaleDevice(
          name: 'Essae DS-252 Electronic Scale (Bluetooth)',
          address: 'BT_SCALE_01',
          type: 'bluetooth',
        ),
        DiscoveredScaleDevice(
          name: 'Phoenix Smart Weight (RS-232 / USB)',
          address: 'USB_SCALE_01',
          type: 'usb',
        ),
        DiscoveredScaleDevice(
          name: 'CAS Digital Kirana Scale (9600 bps)',
          address: 'CAS_SCALE_01',
          type: 'usb',
        ),
      ];
    }

    final results = <DiscoveredScaleDevice>[];

    // 1. Bluetooth paired scales
    try {
      final List<dynamic>? btDevices = await _channel.invokeMethod('getBondedScales');
      if (btDevices != null) {
        for (final item in btDevices) {
          final map = Map<String, dynamic>.from(item as Map);
          results.add(DiscoveredScaleDevice(
            name: map['name'] as String? ?? 'Bluetooth Scale',
            address: map['address'] as String,
            type: 'bluetooth',
          ));
        }
      }
    } on MissingPluginException {
      // In tests or desktop VM
      return const [
        DiscoveredScaleDevice(
          name: 'Virtual Essae Digital Scale',
          address: 'VIRTUAL_SCALE_01',
          type: 'bluetooth',
        ),
      ];
    } catch (e) {
      debugPrint('[SCALE_DRIVER] getBondedScales error: $e');
    }

    // 2. USB OTG devices
    try {
      final List<dynamic>? usbDevices = await _channel.invokeMethod('getUsbDevices');
      if (usbDevices != null) {
        for (final item in usbDevices) {
          final map = Map<String, dynamic>.from(item as Map);
          results.add(DiscoveredScaleDevice(
            name: map['name'] as String? ?? 'USB Scale',
            address: map['address'] as String,
            type: 'usb',
          ));
        }
      }
    } catch (e) {
      debugPrint('[SCALE_DRIVER] getUsbDevices error: $e');
    }

    return results;
  }

  @override
  Future<bool> connect(String addressOrPort) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _connected = true;
      _connectedToNative = false;
      await _simulatedFallback.connect(addressOrPort);
      return true;
    }

    try {
      final success = await _channel.invokeMethod<bool>(
        'connectBluetoothScale',
        {'address': addressOrPort},
      );

      if (success == true) {
        _connected = true;
        _connectedToNative = true;
        _startListeningToNativeStream();
        return true;
      } else {
        _connected = false;
        return false;
      }
    } on MissingPluginException {
      _connected = true;
      _connectedToNative = false;
      await _simulatedFallback.connect(addressOrPort);
      return true;
    } catch (e) {
      debugPrint('[SCALE_DRIVER] connect error: $e');
      _connected = false;
      return false;
    }
  }

  void _startListeningToNativeStream() {
    _rawSubscription?.cancel();
    _rawSubscription = _streamChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is String) {
          final reading = WeighingScaleParser.parse(data);
          if (reading != null) {
            _latestReading = reading;
            _readingController.add(reading);
          }
        }
      },
      onError: (err) {
        debugPrint('[SCALE_DRIVER] Stream error: $err');
      },
    );
  }

  @override
  Future<void> disconnect() async {
    if (!_connectedToNative) {
      _connected = false;
      await _simulatedFallback.disconnect();
      return;
    }

    try {
      await _channel.invokeMethod('disconnectScale');
    } catch (e) {
      debugPrint('[SCALE_DRIVER] disconnect error: $e');
    } finally {
      _rawSubscription?.cancel();
      _rawSubscription = null;
      _connected = false;
      _connectedToNative = false;
    }
  }

  @override
  Future<void> tare() async {
    if (!_connectedToNative) {
      await _simulatedFallback.tare();
      return;
    }
    try {
      await _channel.invokeMethod('tareScale');
    } catch (e) {
      debugPrint('[SCALE_DRIVER] tare error: $e');
    }
  }

  @override
  Future<void> zero() async {
    if (!_connectedToNative) {
      await _simulatedFallback.zero();
      return;
    }
    try {
      await _channel.invokeMethod('zeroScale');
    } catch (e) {
      debugPrint('[SCALE_DRIVER] zero error: $e');
    }
  }

  void setSimulatedWeight(double weightKg, {bool isStable = true}) {
    _simulatedFallback.setWeight(weightKg, isStable: isStable);
  }
}
