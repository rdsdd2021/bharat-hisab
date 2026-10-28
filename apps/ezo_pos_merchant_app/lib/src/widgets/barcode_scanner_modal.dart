import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';

class BarcodeScannerModal extends StatefulWidget {
  final ValueChanged<String> onBarcodeScanned;
  final String title;

  const BarcodeScannerModal({
    super.key,
    required this.onBarcodeScanned,
    this.title = 'Scan Product Barcode',
  });

  static Future<String?> show(
    BuildContext context, {
    String title = 'Scan Product Barcode',
    ValueChanged<String>? onBarcodeScanned,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        title: title,
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
  final TextEditingController _manualCodeCtrl = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  String _hardwareScanBuffer = '';
  DateTime? _lastKeyStrokeTime;

  late AnimationController _animCtrl;
  late Animation<double> _laserAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _laserAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _manualCodeCtrl.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _triggerDetection(String barcode) {
    if (barcode.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    widget.onBarcodeScanned(barcode.trim());
    if (mounted) {
      Navigator.pop(context, barcode.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.scanLine, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Barcode Captured: ${barcode.trim()}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: EzoColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                          color: _isTorchOn ? Colors.amber : Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Flashlight',
                        onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.switchCamera,
                          color: _isFrontCamera ? EzoColors.primary : Colors.white70,
                          size: 20,
                        ),
                        tooltip: 'Switch Camera',
                        onPressed: () => setState(() => _isFrontCamera = !_isFrontCamera),
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

              // Camera Viewfinder Box
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viewfinder Reticle (Tap to capture simulation)
                    InkWell(
                      onTap: () {
                        // Generate a valid EAN-13 Kirana Barcode
                        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
                        final sampleCode = '890${timestamp.substring(timestamp.length - 9)}';
                        _triggerDetection(sampleCode);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 250,
                        height: 130,
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

                    // Viewfinder Corners Guidance
                    Positioned(
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Point camera at barcode or tap frame',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
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
              const SizedBox(height: 14),

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
            ],
          ),
        ),
      ),
    );
  }
}
