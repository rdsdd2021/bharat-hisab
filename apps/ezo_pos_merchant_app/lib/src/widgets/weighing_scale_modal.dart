import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';
import '../services/android_weighing_scale_driver.dart';
import '../services/hardware_permission_service.dart';

class WeighingScaleModal extends StatefulWidget {
  final int? targetCartLineIndex;
  final String? targetItemName;
  final Function(double weightKg)? onWeightApplied;

  const WeighingScaleModal({
    super.key,
    this.targetCartLineIndex,
    this.targetItemName,
    this.onWeightApplied,
  });

  static Future<void> show(
    BuildContext context, {
    int? targetCartLineIndex,
    String? targetItemName,
    Function(double weightKg)? onWeightApplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => WeighingScaleModal(
        targetCartLineIndex: targetCartLineIndex,
        targetItemName: targetItemName,
        onWeightApplied: onWeightApplied,
      ),
    );
  }

  @override
  State<WeighingScaleModal> createState() => _WeighingScaleModalState();
}

class _WeighingScaleModalState extends State<WeighingScaleModal> with SingleTickerProviderStateMixin {
  final WeighingScaleManager _scaleMgr = WeighingScaleManager();
  StreamSubscription<WeighingScaleReading>? _readingSub;
  late TabController _tabController;

  WeighingScaleReading _reading = WeighingScaleReading.zero();
  List<DiscoveredScaleDevice> _availableDevices = [];
  bool _isLoadingDevices = false;
  String _selectedBaudRate = '9600';
  String? _statusBanner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reading = _scaleMgr.currentReading;
    _readingSub = _scaleMgr.weightStream.listen((r) {
      if (mounted) {
        setState(() => _reading = r);
      }
    });
    HardwarePermissionService.ensureBluetoothPermission();
    _loadAvailableScales();
  }

  @override
  void dispose() {
    _readingSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableScales() async {
    setState(() => _isLoadingDevices = true);
    final driver = _scaleMgr.currentDriver;
    if (driver is AndroidWeighingScaleDriver) {
      final list = await driver.getAvailableScales();
      if (mounted) {
        setState(() {
          _availableDevices = list;
          _isLoadingDevices = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _availableDevices = const [
            DiscoveredScaleDevice(
              name: 'Virtual Essae Digital Scale',
              address: 'VIRTUAL_SCALE_01',
              type: 'bluetooth',
            ),
            DiscoveredScaleDevice(
              name: 'Phoenix RS-232 USB Serial',
              address: 'USB_SCALE_01',
              type: 'usb',
            ),
          ];
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _connectToScale(DiscoveredScaleDevice dev) async {
    setState(() => _statusBanner = 'Connecting to ${dev.name}...');
    final success = await _scaleMgr.connectScale(
      addressOrPort: dev.address,
      deviceName: dev.name,
    );
    if (mounted) {
      setState(() {
        if (success) {
          _statusBanner = 'Connected to ${dev.name}! Live weight streaming.';
        } else {
          _statusBanner = 'Failed to connect. Check scale power and cable.';
        }
      });
    }
  }

  void _applyCurrentWeight() {
    if (_reading.weightKg <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place item on scale (weight must be > 0.000 KG)'),
          backgroundColor: EzoColors.warning,
        ),
      );
      return;
    }

    widget.onWeightApplied?.call(_reading.weightKg);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${_reading.formattedWeight} to ${widget.targetItemName ?? "Item"}'),
        backgroundColor: EzoColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isConnected = _scaleMgr.isConnected;
    final isTargetingItem = widget.targetItemName != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
          // Drag handle
          Center(
            child: Container(
              width: 38,
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
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.scale, color: Color(0xFF1E88E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Electronic Weighing Scale',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.textPrimary,
                        ),
                      ),
                      Text(
                        isConnected
                            ? 'Online • ${_scaleMgr.connectedDeviceName ?? "Connected"}'
                            : 'RS-232 / USB / Bluetooth Serial',
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
          const SizedBox(height: 12),

          // DIGITAL SCALE BEZEL DISPLAY (High-contrast electronic readout)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Dark terminal slate
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top status annunciator LEDs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildAnnunciatorBadge(
                          label: 'STABLE',
                          isActive: _reading.isStable,
                          activeColor: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _buildAnnunciatorBadge(
                          label: 'NET',
                          isActive: _reading.isTare || _scaleMgr.manualTareKg > 0,
                          activeColor: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 8),
                        _buildAnnunciatorBadge(
                          label: 'ZERO',
                          isActive: _reading.weightKg == 0.0,
                          activeColor: const Color(0xFFE2E8F0),
                        ),
                      ],
                    ),
                    if (_scaleMgr.manualTareKg > 0)
                      Text(
                        'TARE: ${_scaleMgr.manualTareKg.toStringAsFixed(3)} kg',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Large Digital Weight Readout
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _reading.weightKg.toStringAsFixed(3),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: _reading.isStable ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KG',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Zero & Tare Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.rotateCcw, size: 14),
                        label: const Text('ZERO SCALE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _scaleMgr.zeroScale(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.packageMinus, size: 14),
                        label: Text(_scaleMgr.manualTareKg > 0 ? 'RESET TARE' : 'TARE BOWL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: const Color(0xFF93C5FD),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (_scaleMgr.manualTareKg > 0) {
                            _scaleMgr.resetTare();
                            setState(() {});
                          } else {
                            _scaleMgr.tareScale();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Apply to bill action if opened for specific loose item
          if (isTargetingItem) ...[
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(
                'Apply ${_reading.formattedWeight} to "${widget.targetItemName}"',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: EzoColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _applyCurrentWeight,
            ),
            const SizedBox(height: 12),
          ],

          // Status Banner
          if (_statusBanner != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EzoColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusBanner!,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Tab Header for Hardware Setup
          TabBar(
            controller: _tabController,
            labelColor: EzoColors.primary,
            unselectedLabelColor: EzoColors.textMuted,
            indicatorColor: EzoColors.primary,
            labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Bluetooth Scale'),
              Tab(text: 'USB-OTG Serial'),
              Tab(text: 'Simulator'),
            ],
          ),
          const SizedBox(height: 8),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Bluetooth Scales List
                _buildBluetoothTab(),

                // 2. USB OTG Serial Tab
                _buildUsbTab(),

                // 3. Digital Simulator Tab
                _buildSimulatorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnunciatorBadge({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? activeColor.withValues(alpha: 0.6) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? activeColor : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildBluetoothTab() {
    final btDevices = _availableDevices.where((d) => d.type == 'bluetooth').toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paired & Nearby Bluetooth Scales',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: EzoColors.textSecondary),
            ),
            TextButton.icon(
              icon: _isLoadingDevices
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.refreshCw, size: 12),
              label: const Text('Refresh', style: TextStyle(fontSize: 11)),
              onPressed: _isLoadingDevices ? null : _loadAvailableScales,
            ),
          ],
        ),
        Expanded(
          child: btDevices.isEmpty
              ? Center(
                  child: Text(
                    'No Bluetooth scales paired.\nPair your Essae or Phoenix scale in phone Bluetooth settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: btDevices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final dev = btDevices[idx];
                    final isCurrent = _scaleMgr.connectedAddress == dev.address && _scaleMgr.isConnected;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? EzoColors.successBg : const Color(0xFF1E88E5).withValues(alpha: 0.1),
                        child: Icon(LucideIcons.scale, size: 16, color: isCurrent ? EzoColors.success : const Color(0xFF1E88E5)),
                      ),
                      title: Text(dev.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('MAC: ${dev.address}', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: EzoColors.textMuted)),
                      trailing: isCurrent
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: EzoColors.error),
                              onPressed: () => _scaleMgr.disconnectScale(),
                              child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EzoColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(64, 30),
                              ),
                              onPressed: () => _connectToScale(dev),
                              child: const Text('Connect', style: TextStyle(fontSize: 11)),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUsbTab() {
    final usbDevices = _availableDevices.where((d) => d.type == 'usb').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RS-232 / USB-Serial OTG Port',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: EzoColors.textSecondary),
            ),
            Row(
              children: [
                Text('Baud: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                DropdownButton<String>(
                  value: _selectedBaudRate,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EzoColors.textPrimary, fontWeight: FontWeight.w700),
                  items: const [
                    DropdownMenuItem(value: '9600', child: Text('9600')),
                    DropdownMenuItem(value: '4800', child: Text('4800')),
                    DropdownMenuItem(value: '2400', child: Text('2400')),
                    DropdownMenuItem(value: '19200', child: Text('19200')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBaudRate = val);
                  },
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: usbDevices.isEmpty
              ? Center(
                  child: Text(
                    'No USB Serial Scale detected.\nConnect scale DB9 cable to phone via USB-OTG adapter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: usbDevices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final dev = usbDevices[idx];
                    final isCurrent = _scaleMgr.connectedAddress == dev.address && _scaleMgr.isConnected;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? EzoColors.successBg : const Color(0xFF6366F1).withValues(alpha: 0.1),
                        child: Icon(LucideIcons.cable, size: 16, color: isCurrent ? EzoColors.success : const Color(0xFF6366F1)),
                      ),
                      title: Text(dev.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Port: ${dev.address} • $_selectedBaudRate-8-N-1', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: EzoColors.textMuted)),
                      trailing: isCurrent
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: EzoColors.error),
                              onPressed: () => _scaleMgr.disconnectScale(),
                              child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(64, 30),
                              ),
                              onPressed: () => _connectToScale(dev),
                              child: const Text('Open Port', style: TextStyle(fontSize: 11)),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSimulatorTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Scale Simulator (Testing & Demo)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: EzoColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap quick weight presets to test loose-item billing without physical hardware:',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
          ),
          const SizedBox(height: 10),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip(0.250, '250g'),
              _buildPresetChip(0.500, '500g'),
              _buildPresetChip(0.750, '750g'),
              _buildPresetChip(1.000, '1.000 KG'),
              _buildPresetChip(1.500, '1.500 KG'),
              _buildPresetChip(2.000, '2.000 KG'),
              _buildPresetChip(2.500, '2.500 KG'),
              _buildPresetChip(5.000, '5.000 KG'),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Weight Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Pan Weight: ${_reading.weightKg.toStringAsFixed(3)} KG', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  _scaleMgr.simulateWeight(0.0);
                  setState(() {});
                },
                child: const Text('Clear Pan', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Slider(
            value: _reading.weightKg.clamp(0.0, 10.0),
            min: 0.0,
            max: 10.0,
            divisions: 100,
            label: '${_reading.weightKg.toStringAsFixed(2)} KG',
            onChanged: (val) {
              _scaleMgr.simulateWeight(val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(double kg, String label) {
    final isSelected = (_reading.weightKg - kg).abs() < 0.001;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? const Color(0xFF1E88E5) : EzoColors.surfaceSecondary,
      labelStyle: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : EzoColors.textPrimary,
      ),
      onPressed: () {
        _scaleMgr.simulateWeight(kg);
        setState(() {});
      },
    );
  }
}
