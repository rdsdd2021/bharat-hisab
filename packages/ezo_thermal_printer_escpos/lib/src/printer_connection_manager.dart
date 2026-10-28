import 'dart:async';
import 'dart:typed_data';

enum PrinterConnectionType {
  bluetoothSpp,
  bluetoothBle,
  usbOtg,
  networkWifi,
  virtualPreview,
}

class DiscoveredPrinterDevice {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String address; // MAC address or USB port ID
  final bool isConnected;
  final bool isBonded;

  const DiscoveredPrinterDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.isConnected = false,
    this.isBonded = false,
  });

  DiscoveredPrinterDevice copyWith({
    String? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? address,
    bool? isConnected,
    bool? isBonded,
  }) {
    return DiscoveredPrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      isBonded: isBonded ?? this.isBonded,
    );
  }
}

abstract class PrinterTransportDriver {
  Future<bool> connect(String address);
  Future<void> disconnect();
  Future<bool> sendBytes(Uint8List bytes);
  bool get isConnected;
  Future<List<DiscoveredPrinterDevice>> scanDevices({bool activeDiscovery = false});
}

class VirtualMonospacePrinterDriver implements PrinterTransportDriver {
  bool _connected = false;
  final List<Uint8List> printedBuffers = [];
  final StreamController<Uint8List> _streamController = StreamController.broadcast();

  Stream<Uint8List> get onPrintStream => _streamController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect(String address) async {
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<bool> sendBytes(Uint8List bytes) async {
    if (!_connected) return false;
    printedBuffers.add(bytes);
    _streamController.add(bytes);
    return true;
  }

  @override
  Future<List<DiscoveredPrinterDevice>> scanDevices({bool activeDiscovery = false}) async {
    return [
      const DiscoveredPrinterDevice(
        id: 'BT_58MM_01',
        name: 'Bharat Chota 58mm Bluetooth',
        connectionType: PrinterConnectionType.bluetoothSpp,
        address: '00:11:22:33:44:55',
        isBonded: true,
      ),
      const DiscoveredPrinterDevice(
        id: 'BT_80MM_02',
        name: 'Bharat Bada 80mm Bluetooth',
        connectionType: PrinterConnectionType.bluetoothSpp,
        address: '66:77:88:99:AA:BB',
        isBonded: true,
      ),
      const DiscoveredPrinterDevice(
        id: 'USB_POS_80',
        name: 'USB Thermal Receipt Printer',
        connectionType: PrinterConnectionType.usbOtg,
        address: 'USB_PORT_01',
        isBonded: false,
      ),
      const DiscoveredPrinterDevice(
        id: 'VIRTUAL_SCREEN',
        name: 'Virtual On-Screen Monospace Preview',
        connectionType: PrinterConnectionType.virtualPreview,
        address: '127.0.0.1',
        isBonded: false,
      ),
    ];
  }
}

class ThermalPrinterConnectionManager {
  static final ThermalPrinterConnectionManager _instance = ThermalPrinterConnectionManager._internal();
  factory ThermalPrinterConnectionManager() => _instance;
  ThermalPrinterConnectionManager._internal();

  DiscoveredPrinterDevice? _activeDevice;
  PrinterTransportDriver _driver = VirtualMonospacePrinterDriver();
  final List<DiscoveredPrinterDevice> _pairedDevices = [];
  bool _isAutoReconnectEnabled = true;

  DiscoveredPrinterDevice? get activeDevice => _activeDevice;
  bool get isConnected => _driver.isConnected;
  PrinterTransportDriver get currentDriver => _driver;

  void registerTransportDriver(PrinterTransportDriver customDriver) {
    _driver = customDriver;
  }

  Future<List<DiscoveredPrinterDevice>> scanForPrinters({bool activeDiscovery = false}) async {
    return _driver.scanDevices(activeDiscovery: activeDiscovery);
  }

  Future<bool> connectPrinter(DiscoveredPrinterDevice device) async {
    final success = await _driver.connect(device.address);
    if (success) {
      _activeDevice = DiscoveredPrinterDevice(
        id: device.id,
        name: device.name,
        connectionType: device.connectionType,
        address: device.address,
        isConnected: true,
        isBonded: device.isBonded,
      );
      if (!_pairedDevices.any((d) => d.id == device.id)) {
        _pairedDevices.add(_activeDevice!);
      }
    }
    return success;
  }

  Future<void> disconnectPrinter() async {
    await _driver.disconnect();
    _activeDevice = null;
  }

  Future<bool> printBytes(Uint8List bytes) async {
    if (!_driver.isConnected && _isAutoReconnectEnabled && _activeDevice != null) {
      await connectPrinter(_activeDevice!);
    }
    return _driver.sendBytes(bytes);
  }

  void setAutoReconnect(bool enabled) {
    _isAutoReconnectEnabled = enabled;
  }
}
