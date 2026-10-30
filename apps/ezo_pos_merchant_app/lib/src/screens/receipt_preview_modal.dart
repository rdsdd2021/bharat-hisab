import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import 'package:flutter/foundation.dart';
import '../theme/ezo_theme.dart';
import '../widgets/bluetooth_printer_scanner_modal.dart';
import '../services/web_printer_helper.dart';

class ReceiptPreviewModal extends StatefulWidget {
  final InvoiceDocument invoice;
  final BusinessProfile storeProfile;

  const ReceiptPreviewModal({
    super.key,
    required this.invoice,
    required this.storeProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required InvoiceDocument invoice,
    required BusinessProfile storeProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReceiptPreviewModal(
        invoice: invoice,
        storeProfile: storeProfile,
      ),
    );
  }

  @override
  State<ReceiptPreviewModal> createState() => _ReceiptPreviewModalState();
}

class _ReceiptPreviewModalState extends State<ReceiptPreviewModal> {
  int _selectedTabIndex = 0; // 0: 58mm, 1: 80mm, 2: A4 Modern, 3: A4 Tally
  bool _isPrinting = false;
  String _printStatus = '';

  @override
  Widget build(BuildContext context) {
    final preview58 = EscPosThermalEngine.renderReceiptAsciiPreview(
      invoice: widget.invoice,
      storeProfile: widget.storeProfile,
      rollWidth: ThermalRollWidth.chota58mm,
    );

    final preview80 = EscPosThermalEngine.renderReceiptAsciiPreview(
      invoice: widget.invoice,
      storeProfile: widget.storeProfile,
      rollWidth: ThermalRollWidth.bada80mm,
    );

    return Dialog(
      backgroundColor: EzoColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        height: 640,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EzoColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.receipt, color: EzoColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Preview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.textPrimary,
                        ),
                      ),
                      Text(
                        '#${widget.invoice.invoiceNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: EzoColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: EzoColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Format Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFormatChip(0, '58mm Chota'),
                  const SizedBox(width: 6),
                  _buildFormatChip(1, '80mm Bada'),
                  const SizedBox(width: 6),
                  _buildFormatChip(2, 'A4 Modern PDF'),
                  const SizedBox(width: 6),
                  _buildFormatChip(3, 'A4 Tally Grid'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Thermal Slip Container (Paper Simulation)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EzoColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Text(
                      _selectedTabIndex == 0
                          ? preview58
                          : (_selectedTabIndex == 1
                              ? preview80
                              : (_selectedTabIndex == 2
                                  ? '=== A4 MODERN GST INVOICE TEMPLATE ===\n'
                                      'Format: Full Page PDF Vector\n'
                                      'Invoice No: ${widget.invoice.invoiceNumber}\n'
                                      'Seller: ${widget.storeProfile.storeName}\n'
                                      'GSTIN: ${widget.storeProfile.gstin}\n'
                                      'State: ${widget.storeProfile.stateName} (${widget.storeProfile.stateCode})\n'
                                      '-----------------------------------------\n'
                                      'Total Items: ${widget.invoice.lineItems.length}\n'
                                      'Taxable Subtotal: Rs. ${widget.invoice.taxableSubtotal.toStringAsFixed(2)}\n'
                                      'CGST: Rs. ${widget.invoice.totalCgst.toStringAsFixed(2)}\n'
                                      'SGST: Rs. ${widget.invoice.totalSgst.toStringAsFixed(2)}\n'
                                      'Grand Total: Rs. ${widget.invoice.grandTotal.toStringAsFixed(2)}\n'
                                      'You Saved: Rs. ${widget.invoice.customerSavings.toStringAsFixed(2)}\n'
                                      '-----------------------------------------\n'
                                      '[Ready for High-Res Vector Print]'
                                  : '=== TALLY-STYLE GRID TAX INVOICE ===\n'
                                      'Format: Boxed Multi-Rate GST Ledger\n'
                                      'HSN Table & Statutory Tax Breakup Included.\n'
                                      'Invoice No: ${widget.invoice.invoiceNumber}\n'
                                      'Seller GSTIN: ${widget.storeProfile.gstin}\n'
                                      'Total Due: Rs. ${widget.invoice.grandTotal.toStringAsFixed(2)}')),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: _selectedTabIndex == 0 ? 11 : 12,
                        height: 1.35,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Print Status Notification
            if (_printStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: EzoColors.success, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _printStatus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EzoColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrintEscPos,
                    icon: _isPrinting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.printer, size: 15),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Slip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bluetooth Printer Settings',
                  icon: const Icon(LucideIcons.bluetooth, color: Color(0xFF2563EB)),
                  onPressed: () => BluetoothPrinterScannerModal.show(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _handleShowUpiQr,
                    icon: const Icon(LucideIcons.qrCode, size: 15),
                    label: const Text('UPI QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: _handleShareWhatsApp,
                    icon: const Icon(LucideIcons.share2, size: 15),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.whatsapp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(int index, String label) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EzoColors.primary : EzoColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? EzoColors.primary : EzoColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : EzoColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _handlePrintEscPos() async {
    // 1. On Web: Use universal browser system print formatted for thermal rolls
    if (kIsWeb) {
      final rollWidthMm = _selectedTabIndex == 1 ? 80 : 58;
      final previewText = EscPosThermalEngine.renderReceiptAsciiPreview(
        invoice: widget.invoice,
        storeProfile: widget.storeProfile,
        rollWidth: _selectedTabIndex == 1 ? ThermalRollWidth.bada80mm : ThermalRollWidth.chota58mm,
      );

      triggerWebPrintReceipt(
        asciiReceipt: previewText,
        invoiceNumber: widget.invoice.invoiceNumber,
        rollWidthMm: rollWidthMm,
      );

      setState(() {
        _isPrinting = false;
        _printStatus = 'System Print Dialog opened! Print to any connected thermal or desktop printer.';
      });
      return;
    }

    // 2. On Native Mobile (Android/iOS): Transmit ESC/POS byte stream via Bluetooth driver
    final printerMgr = ThermalPrinterConnectionManager();

    // If not connected on Android, prompt user to select/pair printer
    if (!printerMgr.isConnected && defaultTargetPlatform == TargetPlatform.android) {
      final shouldContinue = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: EzoColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) => BluetoothPrinterScannerModal(
          onPrinterConnected: () => Navigator.pop(ctx, true),
        ),
      );

      if (shouldContinue != true && !printerMgr.isConnected) {
        setState(() {
          _printStatus = 'Printer connection cancelled. Pair printer in Bluetooth to print.';
        });
        return;
      }
    }

    setState(() {
      _isPrinting = true;
      _printStatus = 'Transmitting ESC/POS bytes to printer...';
    });

    try {
      final roll = _selectedTabIndex == 1 ? ThermalRollWidth.bada80mm : ThermalRollWidth.chota58mm;
      final bytes = EscPosThermalEngine.buildInvoiceByteStream(
        invoice: widget.invoice,
        storeProfile: widget.storeProfile,
        rollWidth: roll,
      );

      final success = await printerMgr.printBytes(bytes);

      setState(() {
        _isPrinting = false;
        if (success) {
          final printerName = printerMgr.activeDevice?.name ?? 'Thermal Printer';
          _printStatus = 'Sent ${bytes.length} ESC/POS bytes to $printerName ✅';
        } else {
          _printStatus = 'Failed to transmit ESC/POS bytes. Check printer connection.';
        }
      });
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _printStatus = 'Print failed: $e';
      });
    }
  }

  void _handleShowUpiQr() {
    final upiId = widget.storeProfile.upiId.isNotEmpty
        ? widget.storeProfile.upiId
        : '${widget.storeProfile.phone}@upi';

    final upiUri = UpiQrGenerator.buildUpiPaymentUri(
      merchantUpiId: upiId,
      merchantName: widget.storeProfile.storeName,
      amount: widget.invoice.grandTotal,
      note: 'Bill #${widget.invoice.invoiceNumber}',
      transactionRef: widget.invoice.invoiceNumber,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.qrCode, color: Color(0xFF0D9488), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instant UPI Dynamic QR',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.storeProfile.storeName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount Locked to Bill',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF0D9488), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${widget.invoice.grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // High Fidelity QR Simulation Box
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D9488), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // QR grid aesthetic pattern
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQrCorner(),
                            _buildQrCorner(),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQrCorner(),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.indianRupee, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'SCAN TO PAY\nANY UPI APP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // VPA and Intent String
            Text(
              'UPI VPA: $upiId',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: EzoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Works with PhonePe, Google Pay, Paytm, BHIM & all UPI apps',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.copy, size: 14),
            label: const Text('Copy UPI Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: upiUri));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UPI Intent URI copied to clipboard!'),
                  backgroundColor: Color(0xFF0D9488),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: EzoColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(LucideIcons.checkCircle2, size: 14),
            label: const Text('Confirm Received'),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _printStatus = 'UPI Payment of ₹${widget.invoice.grandTotal.toStringAsFixed(2)} confirmed!';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQrCorner() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0F172A), width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  void _handleShareWhatsApp() {
    final customer = PartyAccount(
      id: 'party_temp',
      name: widget.invoice.partyName.isNotEmpty ? widget.invoice.partyName : 'Customer',
      phone: widget.invoice.partyPhone.isNotEmpty ? widget.invoice.partyPhone : '9876543210',
      partyType: PartyType.customer,
    );

    final link = WhatsAppReminderBuilder.buildWaMeLink(
      customer: customer,
      storeProfile: widget.storeProfile,
    );

    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp receipt link copied: $link'),
        backgroundColor: EzoColors.whatsapp,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
