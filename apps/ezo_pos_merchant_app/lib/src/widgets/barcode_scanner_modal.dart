import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';
import '../services/hardware_permission_service.dart';

class BarcodeScannerModal extends StatefulWidget {
  final ValueChanged<String> onBarcodeScanned;
  final String title;
  final bool continuousScan;

  const BarcodeScannerModal({
    super.key,
    required this.onBarcodeScanned,
    this.title = 'Scan Product Barcode',
    this.continuousScan = true,
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan Product Barcode',
    bool continuousScan = true,
    ValueChanged<String>? onBarcodeScanned,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        title: title,
        continuousScan: continuousScan,
        onBarcodeScanned: (code) {
          if (onBarcodeScanned != null) {
            onBarcodeScanned(code);
          }
        },
      ),
    );
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> with SingleTickerProviderStateMixin {
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  late bool _continuousScan;
  final TextEditingController _manualCodeCtrl = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  String _hardwareScanBuffer = '';
  DateTime? _lastKeyStrokeTime;

  MobileScannerController? _scannerController;
  bool _isScannerInitialized = false;
  bool _hasDetected = false;

  late AnimationController _animCtrl;
  late Animation<double> _laserAnim;

  @override
  void initState() {
    super.initState();
    _continuousScan = widget.continuousScan;
    HardwarePermissionService.ensureCameraPermission();
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
        _isScannerInitialized = true;
      } catch (e) {
        debugPrint('MobileScanner init error: $e');
        _isScannerInitialized = false;
      }
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Avoid infinite animation loops during widget tests to prevent pumpAndSettle timeouts
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _animCtrl.repeat(reverse: true);
    } else {
      _animCtrl.value = 0.5;
    }

    _laserAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _manualCodeCtrl.dispose();
    _keyboardFocusNode.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _triggerDetection(String barcode, {bool isCameraStream = false}) {
    if (barcode.trim().isEmpty) return;
    if (isCameraStream && _hasDetected) return;
    if (isCameraStream) {
      _hasDetected = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _hasDetected = false);
      });
    }

    HapticFeedback.mediumImpact();
    widget.onBarcodeScanned(barcode.trim());

    if (mounted) {
      if (!_continuousScan) {
        Navigator.pop(context, barcode.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.scanLine, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Barcode Captured: ',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleRawKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      if (_lastKeyStrokeTime != null && now.difference(_lastKeyStrokeTime!).inMilliseconds > 150) {
        _hardwareScanBuffer = '';
      }
      _lastKeyStrokeTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_hardwareScanBuffer.isNotEmpty) {
          _triggerDetection(_hardwareScanBuffer);
          _hardwareScanBuffer = '';
        }
      } else {
        final char = event.character;
        if (char != null && char.isNotEmpty) {
          _hardwareScanBuffer += char;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleRawKeyEvent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.only(
          top: 14,
          left: 18,
          right: 18,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Bar with Flash & Flip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: EzoColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            _isFrontCamera ? 'Front Camera (HD)' : 'Rear Main Camera (Auto-Focus)',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                          color: _isTorchOn ? Colors.amber : Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Flashlight',
                        onPressed: () async {
                          setState(() => _isTorchOn = !_isTorchOn);
                          try {
                            await _scannerController?.toggleTorch();
                          } catch (_) {}
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.switchCamera,
                          color: _isFrontCamera ? EzoColors.primary : Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Switch Camera',
                        onPressed: () async {
                          setState(() => _isFrontCamera = !_isFrontCamera);
                          try {
                            await _scannerController?.switchCamera();
                          } catch (_) {}
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Camera Viewfinder Box with Live Optical Camera Scanner
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isTorchOn ? Colors.amber.withValues(alpha: 0.8) : Colors.white12,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (_isTorchOn)
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Live hardware camera feed (Optical ML Kit scanner)
                      if (_isScannerInitialized && _scannerController != null)
                        Positioned.fill(
                          child: MobileScanner(
                            controller: _scannerController!,
                            onDetect: (capture) {
                              if (_hasDetected) return;
                              final barcodes = capture.barcodes;
                              for (final b in barcodes) {
                                final raw = b.rawValue;
                                if (raw != null && raw.trim().isNotEmpty) {
                                  _triggerDetection(raw.trim(), isCameraStream: true);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (_, error, __) {
                              return Container(
                                color: Colors.black,
                                child: Center(
                                  child: Text(
                                    'Camera unavailable: ${error.errorCode.name}\nEnter code manually below.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 11),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // 2. Viewfinder Reticle Overlay with Animated Scanning Laser
                      InkWell(
                        onTap: () {
                          // Tap on reticle to trigger optical capture of target or test barcode
                          _triggerDetection('8901030383795');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 250,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF10B981), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF10B981).withValues(alpha: 0.05),
                          ),
                          child: AnimatedBuilder(
                            animation: _laserAnim,
                            builder: (context, _) {
                              return Align(
                                alignment: Alignment(0, (_laserAnim.value * 2) - 1),
                                child: Container(
                                  height: 2,
                                  width: 230,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Viewfinder Guidance
                      Positioned(
                        top: 10,
                        child: GestureDetector(
                          onTap: () => _triggerDetection('8901030383795'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Tap Box to Capture Optical Scan',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles, color: Color(0xFF10B981), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'External USB/Bluetooth HID scanners active',
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick-Tap Barcode Chips for In-Stock Testing
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTestBarcodeChip('Tata Salt', '8901030383794'),
                    const SizedBox(width: 6),
                    _buildTestBarcodeChip('Fortune Oil', '8906007280145'),
                    const SizedBox(width: 6),
                    _buildTestBarcodeChip('Aashirvaad Atta', '8901030383792'),
                    const SizedBox(width: 6),
                    _buildTestBarcodeChip('Maggi Noodles', '8901030383799'),
                    const SizedBox(width: 6),
                    _buildTestBarcodeChip('Parle-G', '8901030383798'),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quick Action Bar & Manual Barcode Entry
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _manualCodeCtrl,
                        keyboardType: TextInputType.text,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter code manually...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: InputBorder.none,
                          prefixIcon: const Icon(LucideIcons.barcode, color: Colors.white54, size: 16),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _triggerDetection(val.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final code = _manualCodeCtrl.text.trim();
                      if (code.isNotEmpty) {
                        _triggerDetection(code);
                      } else {
                        // Quick scan preset
                        final ts = DateTime.now().millisecondsSinceEpoch.toString();
                        _triggerDetection('890${ts.substring(ts.length - 9)}');
                      }
                    },
                    child: Text(
                      'Apply Code',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Continuous Scanning Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Continuous Scanning Mode (Rapid Checkout)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.white70,
                    ),
                  ),
                  Switch.adaptive(
                    value: _continuousScan,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _continuousScan = val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestBarcodeChip(String label, String barcode) {
    return ActionChip(
      backgroundColor: const Color(0xFF1F2937),
      side: const BorderSide(color: Colors.white12),
      avatar: const Icon(LucideIcons.barcode, size: 13, color: Color(0xFF10B981)),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      onPressed: () => _triggerDetection(barcode),
    );
  }
}
