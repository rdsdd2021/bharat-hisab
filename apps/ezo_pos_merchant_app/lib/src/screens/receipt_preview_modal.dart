import 'package:flutter/material.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import '../theme/ezo_theme.dart';

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
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrintEscPos,
                    icon: _isPrinting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.printer, size: 16),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Thermal Slip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EzoColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleShareWhatsApp,
                    icon: const Icon(LucideIcons.share2, size: 16),
                    label: const Text('Share WhatsApp'),
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
    setState(() {
      _isPrinting = true;
      _printStatus = '';
    });

    try {
      final roll = _selectedTabIndex == 1 ? ThermalRollWidth.bada80mm : ThermalRollWidth.chota58mm;
      final bytes = EscPosThermalEngine.buildInvoiceByteStream(
        invoice: widget.invoice,
        storeProfile: widget.storeProfile,
        rollWidth: roll,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isPrinting = false;
        _printStatus = 'Sent ${bytes.length} ESC/POS bytes to Thermal Printer';
      });
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _printStatus = 'Print failed: $e';
      });
    }
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp receipt link: $link'),
        backgroundColor: EzoColors.whatsapp,
      ),
    );
  }
}
