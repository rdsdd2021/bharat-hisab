import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_pos_merchant_app/src/services/android_bluetooth_printer_driver.dart';
import 'package:ezo_pos_merchant_app/src/widgets/bluetooth_printer_scanner_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.bharathisab.pos/bluetooth_printer');

  group('Bluetooth Printer Hardware & Transport Driver Tests', () {
    test('AndroidBluetoothPrinterDriver falls back gracefully in test environment', () async {
      final driver = AndroidBluetoothPrinterDriver();
      expect(driver.isConnected, isFalse);

      final devices = await driver.scanDevices();
      expect(devices, isNotEmpty);
      expect(devices.first.name, contains('System Print / PDF Dialog'));

      final connected = await driver.connect(devices.first.address);
      expect(connected, isTrue);
      expect(driver.isConnected, isTrue);

      final printSuccess = await driver.sendBytes(Uint8List.fromList([0x1B, 0x40]));
      expect(printSuccess, isTrue);

      await driver.disconnect();
      expect(driver.isConnected, isFalse);
    });

    test('ThermalPrinterConnectionManager dynamically delegates to registered driver', () async {
      final manager = ThermalPrinterConnectionManager();
      final customDriver = AndroidBluetoothPrinterDriver();
      manager.registerTransportDriver(customDriver);

      final devices = await manager.scanForPrinters();
      expect(devices, isNotEmpty);

      final success = await manager.connectPrinter(devices.first);
      expect(success, isTrue);
      expect(manager.isConnected, isTrue);
      expect(manager.activeDevice?.address, devices.first.address);

      final printResult = await manager.printBytes(Uint8List.fromList([0x1B, 0x40]));
      expect(printResult, isTrue);

      await manager.disconnectPrinter();
      expect(manager.isConnected, isFalse);
      expect(manager.activeDevice, isNull);
    });

    testWidgets('BluetoothPrinterScannerModal renders UI, scans devices, and connects', (tester) async {
      // Mock the native Kotlin platform channel
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall call) async {
          if (call.method == 'getBondedDevices') {
            return [
              {'name': 'Bharat Thermal 58mm', 'address': 'AA:BB:CC:DD:EE:FF'}
            ];
          }
          if (call.method == 'connect') return true;
          if (call.method == 'disconnect') return null;
          if (call.method == 'sendBytes') return true;
          return null;
        },
      );

      final manager = ThermalPrinterConnectionManager();
      manager.registerTransportDriver(AndroidBluetoothPrinterDriver());
      await manager.disconnectPrinter();

      bool onConnectedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BluetoothPrinterScannerModal(
              onPrinterConnected: () {
                onConnectedCalled = true;
              },
            ),
          ),
        ),
      );

      // Pump to settle the initial scan
      await tester.pump();
      await tester.pump();

      // Verify header and UI elements
      expect(find.text('Bluetooth Thermal Printer'), findsOneWidget);
      expect(find.text('Scan Paired Devices'), findsOneWidget);
      expect(find.text('Search Nearby'), findsOneWidget);

      // Verify discovered device from mock Kotlin channel is listed
      expect(find.text('Bharat Thermal 58mm'), findsOneWidget);
      expect(find.textContaining('AA:BB:CC:DD:EE:FF'), findsOneWidget);

      // Tap Connect
      final connectFinder = find.text('Connect');
      expect(connectFinder, findsWidgets);
      await tester.tap(connectFinder.first);
      await tester.pump();
      await tester.pump();

      expect(manager.isConnected, isTrue);
      expect(onConnectedCalled, isTrue);

      // Verify "Test Slip" button appears on the active connection card
      expect(find.text('Test Slip'), findsOneWidget);

      // Tap test print
      await tester.tap(find.text('Test Slip'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Test slip printed successfully'), findsOneWidget);
    });
  });
}
