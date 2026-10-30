import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';
import '../services/hardware_permission_service.dart';
import '../services/android_bluetooth_printer_driver.dart';

class BluetoothPrinterScannerModal extends StatefulWidget {
  final VoidCallback? onPrinterConnected;

  const BluetoothPrinterScannerModal({super.key, this.onPrinterConnected});

  static Future<void> show(BuildContext context, {VoidCallback? onPrinterConnected}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => BluetoothPrinterScannerModal(onPrinterConnected: onPrinterConnected),
    );
  }

  @override
  State<BluetoothPrinterScannerModal> createState() => _BluetoothPrinterScannerModalState();
}

class _BluetoothPrinterScannerModalState extends State<BluetoothPrinterScannerModal> {
  final ThermalPrinterConnectionManager _printerMgr = ThermalPrinterConnectionManager();
  List<DiscoveredPrinterDevice> _devices = [];
  bool _isScanning = false;
  String? _connectingAddress;
  String _statusMessage = '';

  bool _isBluetoothEnabled = true;

  @override
  void initState() {
    super.initState();
    HardwarePermissionService.ensureBluetoothPermission();
    _checkBluetoothState();
    _loadPairedPrinters();
  }

  Future<void> _checkBluetoothState() async {
    final enabled = await AndroidBluetoothPrinterDriver.isBluetoothEnabled();
    if (mounted) {
      setState(() => _isBluetoothEnabled = enabled);
    }
  }

  Future<void> _loadPairedPrinters({bool activeDiscovery = false}) async {
    await _checkBluetoothState();
    setState(() {
      _isScanning = true;
      _statusMessage = activeDiscovery ? 'Searching for nearby Bluetooth devices...' : 'Loading paired printers...';
    });

    try {
      final list = await _printerMgr.scanForPrinters(activeDiscovery: activeDiscovery);
      if (mounted) {
        setState(() {
          _devices = list;
          _isScanning = false;
          _statusMessage = list.isEmpty
              ? 'No Bluetooth printers found. Make sure printer is turned on and paired.'
              : 'Found ${list.length} printer(s). Tap to connect.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Error scanning for printers: $e';
        });
      }
    }
  }

  Future<void> _connectToDevice(DiscoveredPrinterDevice device) async {
    setState(() {
      _connectingAddress = device.address;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    final success = await _printerMgr.connectPrinter(device);

    if (mounted) {
      setState(() {
        _connectingAddress = null;
        if (success) {
          _statusMessage = 'Connected to ${device.name}! Ready to print.';
        } else {
          _statusMessage = 'Failed to connect to ${device.name}. Check if printer is turned on.';
        }
      });

      if (success) {
        widget.onPrinterConnected?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to printer "${device.name}"'),
            backgroundColor: EzoColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _printTestSlip() async {
    if (!_printerMgr.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect a printer first!'),
          backgroundColor: EzoColors.warning,
        ),
      );
      return;
    }

    setState(() => _statusMessage = 'Sending ESC/POS test slip to printer...');

    final sampleProfile = BusinessProfile(
      id: 'store_test_001',
      storeName: 'BharatHisab POS',
      legalEntityName: 'Retail POS',
      gstin: '27AABCT1234F1Z5',
      stateCode: '27',
      stateName: 'Maharashtra',
      address: 'Billing Counter',
      phone: '9876543210',
      email: 'store@pos.local',
      upiId: 'pos@upi',
    );

    final testBytes = EscPosThermalEngine.buildTestSlipByteStream(
      storeProfile: sampleProfile,
      rollWidth: ThermalRollWidth.chota58mm,
    );

    final success = await _printerMgr.printBytes(testBytes);

    if (mounted) {
      setState(() {
        _statusMessage = success ? 'Test slip printed successfully! ✅' : 'Failed to print test slip.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeDevice = _printerMgr.activeDevice;
    final isConnected = _printerMgr.isConnected;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 18,
        right: 18,
        bottom: bottomInset + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EzoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.printer, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluetooth Thermal Printer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.textPrimary,
                        ),
                      ),
                      Text(
                        isConnected && activeDevice != null
                            ? 'Connected: ${activeDevice.name}'
                            : '58mm / 80mm ESC/POS Receipt Printer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isConnected ? EzoColors.success : EzoColors.textMuted,
                          fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: EzoColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bluetooth Off Alert Banner
          if (!_isBluetoothEnabled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.bluetoothOff, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bluetooth is turned OFF on your phone.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                    onPressed: () async {
                      await AndroidBluetoothPrinterDriver.requestEnableBluetooth();
                      await Future.delayed(const Duration(milliseconds: 800));
                      await _checkBluetoothState();
                      _loadPairedPrinters();
                    },
                    child: const Text('Turn ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Active Connection Status Card
          if (isConnected && activeDevice != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: EzoColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EzoColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: EzoColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeDevice.name,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: EzoColors.textPrimary),
                        ),
                        Text(
                          'MAC: ${activeDevice.address} • Online',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: EzoColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _printTestSlip,
                    child: const Text('Test Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EzoColors.error,
                      side: BorderSide(color: EzoColors.error.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(50, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () async {
                      await _printerMgr.disconnectPrinter();
                      setState(() => _statusMessage = 'Disconnected.');
                    },
                    child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Scan Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isScanning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan Paired Devices'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isScanning ? null : () => _loadPairedPrinters(activeDiscovery: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.bluetoothSearching, size: 14),
                  label: const Text('Search Nearby'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isScanning ? null : () => _loadPairedPrinters(activeDiscovery: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status Banner
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EzoColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusMessage,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textSecondary),
              ),
            ),
          const SizedBox(height: 10),

          // Devices List
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bluetoothOff, size: 36, color: EzoColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'No Bluetooth Printers Found',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: EzoColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Turn ON your 58mm / 80mm thermal printer.\n2. Pair it once in phone Settings -> Bluetooth.\n3. Tap "Scan Paired Devices" above.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.settings, size: 14),
                          label: const Text('Open Phone Bluetooth Settings (Pair)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            await AndroidBluetoothPrinterDriver.openBluetoothSettings();
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final d = _devices[idx];
                      final isCurrent = activeDevice?.address == d.address && isConnected;
                      final isConnecting = _connectingAddress == d.address;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: isCurrent
                              ? EzoColors.success.withValues(alpha: 0.15)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          child: Icon(
                            LucideIcons.printer,
                            size: 18,
                            color: isCurrent ? EzoColors.success : const Color(0xFF2563EB),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                            ),
                            if (d.isBonded)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Paired',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Address: ${d.address}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: EzoColors.textMuted),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: EzoColors.successBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: EzoColors.success.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'Active',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: EzoColors.success,
                                  ),
                                ),
                              )
                            : isConnecting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EzoColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(60, 30),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () => _connectToDevice(d),
                                    child: const Text('Connect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
