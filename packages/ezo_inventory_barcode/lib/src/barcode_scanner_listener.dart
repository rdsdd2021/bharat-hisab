typedef BarcodeScanCallback = void Function(String barcode);

/// Handles high-speed keyboard emulation inputs from external USB / Bluetooth HID barcode scanner guns
class BarcodeScannerListener {
  final BarcodeScanCallback onBarcodeScanned;
  final Duration interCharTimeout;

  final StringBuffer _buffer = StringBuffer();
  DateTime _lastCharTime = DateTime.now();

  BarcodeScannerListener({
    required this.onBarcodeScanned,
    this.interCharTimeout = const Duration(milliseconds: 60),
  });

  /// Feeds raw character inputs from physical keyboard / barcode gun
  void onKeyEvent(String char) {
    final now = DateTime.now();
    if (now.difference(_lastCharTime) > interCharTimeout) {
      _buffer.clear();
    }
    _lastCharTime = now;

    if (char == '\n' || char == '\r') {
      final barcode = _buffer.toString().trim();
      if (barcode.isNotEmpty) {
        onBarcodeScanned(barcode);
      }
      _buffer.clear();
    } else {
      _buffer.write(char);
    }
  }

  void reset() {
    _buffer.clear();
  }
}
