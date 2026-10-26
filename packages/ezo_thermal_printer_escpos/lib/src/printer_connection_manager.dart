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

  const DiscoveredPrinterDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.address,
    this.isConnected = false,
  });
}

abstract class PrinterTransportDriver {
  Future<bool> connect(String address);
  Future<void> disconnect();
  Future<bool> sendBytes(Uint8List bytes);
  bool get isConnected;
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

  void registerTransportDriver(PrinterTransportDriver customDriver) {
    _driver = customDriver;
  }

  Future<List<DiscoveredPrinterDevice>> scanForPrinters() async {
    // Returns simulated local devices if hardware bridge not attached
    final devices = [
      const DiscoveredPrinterDevice(
        id: 'BT_58MM_01',
        name: 'Bharat Chota 58mm Bluetooth',
        connectionType: PrinterConnectionType.bluetoothSpp,
        address: '00:11:22:33:44:55',
      ),
      const DiscoveredPrinterDevice(
        id: 'BT_80MM_02',
        name: 'Bharat Bada 80mm Bluetooth',
        connectionType: PrinterConnectionType.bluetoothSpp,
        address: '66:77:88:99:AA:BB',
      ),
      const DiscoveredPrinterDevice(
        id: 'USB_POS_80',
        name: 'USB Thermal Receipt Printer',
        connectionType: PrinterConnectionType.usbOtg,
        address: 'USB_PORT_01',
      ),
      const DiscoveredPrinterDevice(
        id: 'VIRTUAL_SCREEN',
        name: 'Virtual On-Screen Monospace Preview',
        connectionType: PrinterConnectionType.virtualPreview,
        address: '127.0.0.1',
      ),
    ];
    return devices;
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
      );
      if (!_pairedDevices.any((d) => d.id == device.id)) {
        _pairedDevices.add(_activeDevice!);
      }
    }
    return success;
  }

  Future<void> disconnectPrinter() async {
    await _driver.disconnect();
    if (_activeDevice != null) {
      _activeDevice = DiscoveredPrinterDevice(
        id: _activeDevice!.id,
        name: _activeDevice!.name,
        connectionType: _activeDevice!.connectionType,
        address: _activeDevice!.address,
        isConnected: false,
      );
    }
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
