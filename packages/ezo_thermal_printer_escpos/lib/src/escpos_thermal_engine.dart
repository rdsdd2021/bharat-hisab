import 'dart:convert';
import 'dart:typed_data';
import 'package:ezo_core_models/ezo_core_models.dart';

enum ThermalRollWidth {
  chota58mm(32),
  bada80mm(48);

  final int maxChars;
  const ThermalRollWidth(this.maxChars);
}

class EscPosThermalEngine {
  /// Compiles a standard retail bill or KOT into raw ESC/POS byte streams
  static Uint8List buildInvoiceByteStream({
    required InvoiceDocument invoice,
    required BusinessProfile storeProfile,
    ThermalRollWidth rollWidth = ThermalRollWidth.chota58mm,
    bool kickCashDrawer = false,
  }) {
    if (invoice.docType == InvoiceDocType.kitchenOrderTicketKot) {
      return buildKotByteStream(
        invoice: invoice,
        rollWidth: rollWidth,
      );
    }

    final BytesBuilder builder = BytesBuilder();

    // 1. Initialize Printer
    builder.add([0x1B, 0x40]);

    if (kickCashDrawer) {
      // Pulse to open cash drawer
      builder.add([0x1B, 0x70, 0x00, 0x19, 0xFA]);
    }

    // 2. Header (Centered, Store Name Bold Double Height)
    builder.add([0x1B, 0x61, 0x01]); // Align Center
    builder.add([0x1D, 0x21, 0x11]); // Double width & height
    builder.add(_encodeText('${storeProfile.storeName}\n'));
    builder.add([0x1D, 0x21, 0x00]); // Normal font size

    if (storeProfile.address.isNotEmpty) {
      builder.add(_encodeText('${storeProfile.address}\n'));
    }
    if (storeProfile.phone.isNotEmpty) {
      builder.add(_encodeText('Ph: ${storeProfile.phone}\n'));
    }
    if (storeProfile.isGstRegistered) {
      builder.add([0x1B, 0x45, 0x01]); // Bold
      builder.add(_encodeText('GSTIN: ${storeProfile.gstin}\n'));
      builder.add([0x1B, 0x45, 0x00]);
    }

    // Bill Title
    builder.add([0x1B, 0x45, 0x01]);
    final billTitle = invoice.docType == InvoiceDocType.gstTaxInvoice
        ? 'TAX INVOICE'
        : (invoice.docType == InvoiceDocType.nonGstBillOfSupply
            ? 'BILL OF SUPPLY'
            : invoice.docType.name.toUpperCase());
    builder.add(_encodeText('=== $billTitle ===\n'));
    builder.add([0x1B, 0x45, 0x00]);

    // 3. Metadata (Left aligned)
    builder.add([0x1B, 0x61, 0x00]); // Align Left
    builder.add(_encodeText('Bill No : ${invoice.invoiceNumber}\n'));
    builder.add(_encodeText('Date    : ${_formatDateTime(invoice.invoiceDate)}\n'));
    if (invoice.cashierStaffName.isNotEmpty) {
      builder.add(_encodeText('Cashier : ${invoice.cashierStaffName}\n'));
    }

    if (invoice.partyName.isNotEmpty && invoice.partyName != 'Cash Customer') {
      builder.add(_encodeText('Customer: ${invoice.partyName}\n'));
      if (invoice.partyPhone.isNotEmpty) {
        builder.add(_encodeText('Phone   : ${invoice.partyPhone}\n'));
      }
      if (invoice.partyGstin.isNotEmpty) {
        builder.add(_encodeText('Cust GST: ${invoice.partyGstin}\n'));
      }
    }

    // Custom Fields (Batch, PO, E-Way Bill, IMEI, Table)
    final cf = invoice.customFields;
    if (cf.tableNumber.isNotEmpty) {
      builder.add(_encodeText('Table/Token: ${cf.tableNumber}\n'));
    }
    if (cf.batchNumber.isNotEmpty) {
      builder.add(_encodeText('Batch No   : ${cf.batchNumber}\n'));
    }
    if (cf.poNumber.isNotEmpty) {
      builder.add(_encodeText('PO Number  : ${cf.poNumber}\n'));
    }
    if (cf.ewayBillNumber.isNotEmpty) {
      builder.add(_encodeText('E-Way Bill : ${cf.ewayBillNumber}\n'));
    }
    if (cf.ticketOrImeiNumber.isNotEmpty) {
      builder.add(_encodeText('IMEI/Ticket: ${cf.ticketOrImeiNumber}\n'));
    }
    if (cf.vehicleNumber.isNotEmpty) {
      builder.add(_encodeText('Vehicle No : ${cf.vehicleNumber}\n'));
    }

    // 4. Divider Line
    builder.add(_encodeText('${"-" * rollWidth.maxChars}\n'));

    // 5. Line Items Table
    builder.add([0x1B, 0x45, 0x01]); // Bold header
    if (rollWidth == ThermalRollWidth.chota58mm) {
      // 32 Chars: ITEM (14) QTY(4) RATE(6) AMT(8)
      builder.add(_encodeText(_formatRow(['ITEM', 'QTY', 'RATE', 'AMT'], [14, 4, 6, 8])));
    } else {
      // 48 Chars: ITEM (20) HSN (6) QTY(5) RATE(8) AMT(9)
      builder.add(_encodeText(_formatRow(['ITEM', 'HSN', 'QTY', 'RATE', 'AMT'], [20, 6, 5, 8, 9])));
    }
    builder.add([0x1B, 0x45, 0x00]);
    builder.add(_encodeText('${"-" * rollWidth.maxChars}\n'));

    // Populate rows
    for (final line in invoice.lineItems) {
      final itemText = line.itemName;
      final qtyText = _formatQty(line.quantity);
      final rateText = line.unitSellingPrice.toStringAsFixed(1);
      final amtText = line.totalAmount.toStringAsFixed(1);

      if (rollWidth == ThermalRollWidth.chota58mm) {
        builder.add(_encodeText(_formatRow([itemText, qtyText, rateText, amtText], [14, 4, 6, 8])));
      } else {
        builder.add(_encodeText(_formatRow([itemText, line.hsnSacCode, qtyText, rateText, amtText], [20, 6, 5, 8, 9])));
      }

      if (line.cookingNotes.isNotEmpty) {
        builder.add(_encodeText('  * Note: ${line.cookingNotes}\n'));
      }
    }

    builder.add(_encodeText('${"-" * rollWidth.maxChars}\n'));

    // 6. Totals & Tax Breakup
    builder.add(_encodeText(_formatSummaryRow('Taxable Subtotal:', invoice.taxableSubtotal.toStringAsFixed(2), rollWidth)));
    if (invoice.totalCgst > 0) {
      builder.add(_encodeText(_formatSummaryRow('CGST:', invoice.totalCgst.toStringAsFixed(2), rollWidth)));
    }
    if (invoice.totalSgst > 0) {
      builder.add(_encodeText(_formatSummaryRow('SGST:', invoice.totalSgst.toStringAsFixed(2), rollWidth)));
    }
    if (invoice.totalIgst > 0) {
      builder.add(_encodeText(_formatSummaryRow('IGST:', invoice.totalIgst.toStringAsFixed(2), rollWidth)));
    }
    if (invoice.billDiscountAmount > 0) {
      builder.add(_encodeText(_formatSummaryRow('Discount:', '-${invoice.billDiscountAmount.toStringAsFixed(2)}', rollWidth)));
    }
    if (invoice.roundOffAdjustment != 0) {
      builder.add(_encodeText(_formatSummaryRow('Round Off:', invoice.roundOffAdjustment.toStringAsFixed(2), rollWidth)));
    }

    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));

    // Bold Grand Total
    builder.add([0x1B, 0x45, 0x01]);
    builder.add([0x1D, 0x21, 0x01]); // Double height
    builder.add(_encodeText(_formatSummaryRow('GRAND TOTAL:', 'Rs. ${invoice.grandTotal.toStringAsFixed(2)}', rollWidth)));
    builder.add([0x1D, 0x21, 0x00]);
    builder.add([0x1B, 0x45, 0x00]);

    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));

    // Settlement Mode
    builder.add(_encodeText(_formatSummaryRow('Settlement:', invoice.settlementMode.name.toUpperCase(), rollWidth)));
    builder.add(_encodeText(_formatSummaryRow('Paid Amount:', 'Rs. ${invoice.amountReceived.toStringAsFixed(2)}', rollWidth)));
    if (invoice.balanceUdhaarDue > 0) {
      builder.add([0x1B, 0x45, 0x01]);
      builder.add(_encodeText(_formatSummaryRow('UDHAAR DUE:', 'Rs. ${invoice.balanceUdhaarDue.toStringAsFixed(2)}', rollWidth)));
      builder.add([0x1B, 0x45, 0x00]);
    }

    // Prominent "YOU SAVED Rs. X" Banner
    if (invoice.customerSavings > 0) {
      builder.add([0x1B, 0x61, 0x01]); // Center
      builder.add([0x1B, 0x45, 0x01]);
      builder.add(_encodeText('\n*** YOU SAVED Rs. ${invoice.customerSavings.toStringAsFixed(2)} ***\n\n'));
      builder.add([0x1B, 0x45, 0x00]);
    }

    // Dynamic NPCI UPI QR Code (if UPI ID exists)
    if (storeProfile.upiId.isNotEmpty && (invoice.balanceUdhaarDue > 0 || invoice.settlementMode == SettlementMode.upiQr)) {
      final dueAmt = invoice.balanceUdhaarDue > 0 ? invoice.balanceUdhaarDue : invoice.grandTotal;
      final upiUri = 'upi://pay?pa=${storeProfile.upiId}&pn=${Uri.encodeComponent(storeProfile.storeName)}&am=${dueAmt.toStringAsFixed(2)}&cu=INR&tn=Bill-${invoice.invoiceNumber}';

      builder.add([0x1B, 0x61, 0x01]); // Center
      builder.add(_encodeText('Scan to Pay via UPI\n'));
      builder.add(_buildNativeEscPosQrCode(upiUri));
      builder.add(_encodeText('\n'));
    }

    // White-Label Footer Tagline
    builder.add([0x1B, 0x61, 0x01]); // Center
    builder.add(_encodeText('${storeProfile.branding.receiptFooterTagline}\n'));
    if (storeProfile.branding.supportWhatsApp.isNotEmpty) {
      builder.add(_encodeText('Support: +${storeProfile.branding.supportWhatsApp}\n'));
    }

    // Feed lines & Cut Paper
    builder.add([0x1B, 0x64, 0x04]); // Feed 4 lines
    builder.add([0x1D, 0x56, 0x41, 0x03]); // Partial Cut

    return builder.toBytes();
  }

  /// Builds a Kitchen Order Ticket (KOT) byte stream for restaurants/cafes
  static Uint8List buildKotByteStream({
    required InvoiceDocument invoice,
    ThermalRollWidth rollWidth = ThermalRollWidth.chota58mm,
  }) {
    final BytesBuilder builder = BytesBuilder();
    builder.add([0x1B, 0x40]); // Init

    // Center Big Header
    builder.add([0x1B, 0x61, 0x01]);
    builder.add([0x1D, 0x21, 0x11]); // Double height & width
    builder.add(_encodeText('*** KOT ***\n'));
    builder.add([0x1D, 0x21, 0x00]);

    builder.add([0x1B, 0x61, 0x00]); // Left
    final tableNo = invoice.customFields.tableNumber.isNotEmpty
        ? invoice.customFields.tableNumber
        : 'Counter';

    builder.add([0x1B, 0x45, 0x01]);
    builder.add(_encodeText('TABLE / TOKEN : $tableNo\n'));
    builder.add([0x1B, 0x45, 0x00]);

    builder.add(_encodeText('KOT No  : ${invoice.invoiceNumber}\n'));
    builder.add(_encodeText('Waiter  : ${invoice.cashierStaffName}\n'));
    builder.add(_encodeText('Time    : ${_formatDateTime(invoice.invoiceDate)}\n'));

    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));
    builder.add([0x1B, 0x45, 0x01]);
    builder.add(_encodeText(_formatRow(['ITEM NAME', 'QTY'], [rollWidth.maxChars - 8, 8])));
    builder.add([0x1B, 0x45, 0x00]);
    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));

    for (final line in invoice.lineItems) {
      builder.add([0x1B, 0x45, 0x01]);
      builder.add(_encodeText(_formatRow([line.itemName, _formatQty(line.quantity)], [rollWidth.maxChars - 8, 8])));
      builder.add([0x1B, 0x45, 0x00]);

      if (line.cookingNotes.isNotEmpty) {
        builder.add(_encodeText('  -> Special: ${line.cookingNotes}\n'));
      }
    }

    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));
    if (invoice.notes.isNotEmpty) {
      builder.add(_encodeText('Order Notes: ${invoice.notes}\n'));
    }

    builder.add([0x1B, 0x64, 0x04]);
    builder.add([0x1D, 0x56, 0x41, 0x03]); // Cut

    return builder.toBytes();
  }

  /// Generates a test print slip to verify ESC/POS communication, font scaling, alignment and cutter
  static Uint8List buildTestSlipByteStream({
    required BusinessProfile storeProfile,
    ThermalRollWidth rollWidth = ThermalRollWidth.chota58mm,
  }) {
    final BytesBuilder builder = BytesBuilder();
    builder.add([0x1B, 0x40]); // Initialize
    builder.add([0x1B, 0x61, 0x01]); // Align Center
    builder.add([0x1D, 0x21, 0x11]); // Double Size
    builder.add(_encodeText('${storeProfile.storeName}\n'));
    builder.add([0x1D, 0x21, 0x00]); // Normal size
    builder.add(_encodeText('THERMAL PRINTER TEST SLIP\n'));
    builder.add(_encodeText('Roll Width: ${rollWidth == ThermalRollWidth.chota58mm ? "58mm (32 Col)" : "80mm (48 Col)"}\n'));
    builder.add(_encodeText('Date: ${_formatDateTime(DateTime.now())}\n'));
    builder.add(_encodeText('${"-" * rollWidth.maxChars}\n'));
    builder.add([0x1B, 0x61, 0x00]); // Align Left
    builder.add(_encodeText('ESC/POS Command Set: OK\n'));
    builder.add(_encodeText('Bluetooth SPP / USB OTG: OK\n'));
    builder.add(_encodeText('Text Encoding (Latin1/UTF8): OK\n'));
    builder.add([0x1B, 0x45, 0x01]); // Bold
    builder.add(_encodeText('Print Engine Status: READY\n'));
    builder.add([0x1B, 0x45, 0x00]);
    builder.add(_encodeText('${"=" * rollWidth.maxChars}\n'));
    builder.add([0x1B, 0x61, 0x01]); // Center
    builder.add(_encodeText('Bharat Hisab POS • High Speed\n\n'));
    builder.add([0x1B, 0x64, 0x04]); // Feed 4 lines
    builder.add([0x1D, 0x56, 0x41, 0x03]); // Partial Cut
    return builder.toBytes();
  }

  /// Builds a virtual monospace string representation for on-screen receipt preview
  static String renderReceiptAsciiPreview({
    required InvoiceDocument invoice,
    required BusinessProfile storeProfile,
    ThermalRollWidth rollWidth = ThermalRollWidth.chota58mm,
  }) {
    final buffer = StringBuffer();
    final width = rollWidth.maxChars;

    void center(String text) {
      if (text.length >= width) {
        buffer.writeln(text.substring(0, width));
      } else {
        final leftPad = (width - text.length) ~/ 2;
        buffer.writeln(' ' * leftPad + text);
      }
    }

    center(storeProfile.storeName);
    if (storeProfile.address.isNotEmpty) center(storeProfile.address);
    if (storeProfile.phone.isNotEmpty) center('Ph: ${storeProfile.phone}');
    if (storeProfile.isGstRegistered) center('GSTIN: ${storeProfile.gstin}');

    center('=== ${invoice.docType.name.toUpperCase()} ===');
    buffer.writeln('Bill No : ${invoice.invoiceNumber}');
    buffer.writeln('Date    : ${_formatDateTime(invoice.invoiceDate)}');
    if (invoice.customFields.tableNumber.isNotEmpty) {
      buffer.writeln('Table   : ${invoice.customFields.tableNumber}');
    }
    buffer.writeln('-' * width);

    for (final line in invoice.lineItems) {
      final name = line.itemName.length > 14 ? line.itemName.substring(0, 14) : line.itemName;
      final row = _formatRow([name, _formatQty(line.quantity), line.unitSellingPrice.toStringAsFixed(1), line.totalAmount.toStringAsFixed(1)], [14, 4, 6, 8]);
      buffer.write(row);
      if (line.cookingNotes.isNotEmpty) {
        buffer.writeln('  * ${line.cookingNotes}');
      }
    }
    buffer.writeln('-' * width);
    buffer.writeln(_formatSummaryRow('Taxable Subtotal:', invoice.taxableSubtotal.toStringAsFixed(2), rollWidth));
    if (invoice.totalTax > 0) {
      buffer.writeln(_formatSummaryRow('Tax (GST):', invoice.totalTax.toStringAsFixed(2), rollWidth));
    }
    buffer.writeln('=' * width);
    buffer.writeln(_formatSummaryRow('GRAND TOTAL:', 'Rs. ${invoice.grandTotal.toStringAsFixed(2)}', rollWidth));
    buffer.writeln('=' * width);
    buffer.writeln(_formatSummaryRow('Payment Mode:', invoice.settlementMode.name.toUpperCase(), rollWidth));
    buffer.writeln(_formatSummaryRow('Paid Amount:', 'Rs. ${invoice.amountReceived.toStringAsFixed(2)}', rollWidth));
    if (invoice.balanceUdhaarDue > 0) {
      buffer.writeln(_formatSummaryRow('UDHAAR DUE:', 'Rs. ${invoice.balanceUdhaarDue.toStringAsFixed(2)}', rollWidth));
    }

    if (invoice.customerSavings > 0) {
      center('');
      center('*** YOU SAVED Rs. ${invoice.customerSavings.toStringAsFixed(2)} ***');
      center('');
    }

    center(storeProfile.branding.receiptFooterTagline);
    return buffer.toString();
  }

  /// ESC/POS Native QR Code Commands (GS ( k)
  static List<int> _buildNativeEscPosQrCode(String data) {
    final List<int> bytes = [];
    final textBytes = utf8.encode(data);
    final len = textBytes.length + 3;
    final pL = len % 256;
    final pH = len ~/ 256;

    // Model: Model 2
    bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // Module Size: 6
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]);
    // Error Correction: Level M
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
    // Store Data
    bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    bytes.addAll(textBytes);
    // Print QR
    bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

    return bytes;
  }

  static List<int> _encodeText(String text) {
    return latin1.encode(text);
  }

  static String _formatRow(List<String> items, List<int> widths) {
    final buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      final width = widths[i];
      final item = items[i];
      if (item.length > width) {
        buffer.write(item.substring(0, width));
      } else {
        if (i == 0) {
          buffer.write(item.padRight(width));
        } else {
          buffer.write(item.padLeft(width));
        }
      }
    }
    buffer.write('\n');
    return buffer.toString();
  }

  static String _formatSummaryRow(String label, String value, ThermalRollWidth rollWidth) {
    final available = rollWidth.maxChars - value.length;
    if (available <= 0) return '$label $value\n';
    return '${label.padRight(available)}$value\n';
  }

  static String _formatQty(double qty) {
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(2);
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
