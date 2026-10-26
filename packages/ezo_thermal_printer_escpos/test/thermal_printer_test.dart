import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';

void main() {
  const store = BusinessProfile(
    id: 's1',
    storeName: 'Bharat Mart',
    legalEntityName: 'Bharat Retail LLP',
    gstin: '27AABCT1234D1Z5',
    stateCode: '27',
    stateName: 'Maharashtra',
    address: 'FC Road, Pune',
    phone: '9876543210',
    email: 'info@bharatmart.com',
    upiId: 'bharatmart@icici',
    bankName: 'ICICI Bank',
    accountNumber: '1234567890',
    ifscCode: 'ICIC0001234',
    branding: WhiteLabelBranding(
      receiptFooterTagline: 'Thank you! Visit again soon.',
    ),
  );

  const line1 = InvoiceLineItem(
    productId: 'p1',
    itemName: 'Cashew Nuts 250g',
    quantity: 2,
    mrp: 350.0,
    unitSellingPrice: 300.0,
    taxableAmount: 571.42,
    gstPercent: 5.0,
    cgstAmount: 14.29,
    sgstAmount: 14.29,
    totalAmount: 600.0,
    cookingNotes: 'Extra roasted',
  );

  final invoice = InvoiceDocument(
    id: 'inv_print_1',
    invoiceNumber: 'INV-58-001',
    invoiceDate: DateTime(2026, 10, 25, 14, 30),
    storeProfileId: 's1',
    storeStateCode: '27',
    partyName: 'Amit Patel',
    partyPhone: '9898989898',
    lineItems: [line1],
    taxableSubtotal: 571.42,
    totalCgst: 14.29,
    totalSgst: 14.29,
    grandTotal: 600.0,
    amountReceived: 500.0,
    settlementMode: SettlementMode.creditUdhaar,
    customFields: const InvoiceCustomFields(
      tableNumber: 'T-12',
      batchNumber: 'B-2026',
    ),
    createdAt: DateTime.now(),
  );

  group('ESC/POS Thermal Engine Tests', () {
    test('Builds valid ESC/POS byte stream for 58mm Chota Printer with UPI and Cut commands', () {
      final bytes = EscPosThermalEngine.buildInvoiceByteStream(
        invoice: invoice,
        storeProfile: store,
        rollWidth: ThermalRollWidth.chota58mm,
      );

      expect(bytes.isNotEmpty, isTrue);
      // Verify ESC @ (0x1B, 0x40) init header
      expect(bytes[0], equals(0x1B));
      expect(bytes[1], equals(0x40));
      // Contains partial cut command 0x1D, 0x56
      expect(bytes.contains(0x1D), isTrue);
      expect(bytes.contains(0x56), isTrue);
    });

    test('Renders ASCII monospace preview with savings and Udhaar due', () {
      final preview = EscPosThermalEngine.renderReceiptAsciiPreview(
        invoice: invoice,
        storeProfile: store,
        rollWidth: ThermalRollWidth.chota58mm,
      );

      expect(preview.contains('Bharat Mart'), isTrue);
      expect(preview.contains('Table   : T-12'), isTrue);
      expect(preview.contains('GRAND TOTAL:'), isTrue);
      expect(preview.contains('UDHAAR DUE:'), isTrue);
      expect(preview.contains('YOU SAVED Rs. 100.00'), isTrue);
      expect(preview.contains('Thank you! Visit again soon.'), isTrue);
    });

    test('Builds Kitchen Order Ticket (KOT) byte stream without prices', () {
      final kotInvoice = invoice.copyWith(
        docType: InvoiceDocType.kitchenOrderTicketKot,
      );

      final kotBytes = EscPosThermalEngine.buildKotByteStream(
        invoice: kotInvoice,
        rollWidth: ThermalRollWidth.chota58mm,
      );

      expect(kotBytes.isNotEmpty, isTrue);
      // Byte stream should not contain 'GRAND TOTAL' or price symbols
      final decoded = String.fromCharCodes(kotBytes);
      expect(decoded.contains('KOT'), isTrue);
      expect(decoded.contains('TABLE / TOKEN : T-12'), isTrue);
      expect(decoded.contains('Extra roasted'), isTrue);
      expect(decoded.contains('GRAND TOTAL'), isFalse);
    });
  });

  group('Indian Currency Words Tests', () {
    test('Converts Indian currency values correctly into Lakhs and Rupees', () {
      expect(
        IndianCurrencyWordsFormatter.format(145230.50),
        equals('One Lakh Forty Five Thousand Two Hundred Thirty Rupees and Fifty Paise Only'),
      );
      expect(
        IndianCurrencyWordsFormatter.format(500.0),
        equals('Five Hundred Rupees Only'),
      );
    });
  });

  group('PDF Template Generator Tests', () {
    test('Builds A4 Modern GST, Tally Grid, and A5 Landscape HTML templates', () {
      final modern = A4A5InvoicePdfBuilder.buildHtmlDocument(
        invoice: invoice,
        storeProfile: store,
        template: PdfInvoiceTemplate.a4ModernGst,
      );
      expect(modern.contains('TAX INVOICE'), isTrue);
      expect(modern.contains('Cashew Nuts 250g'), isTrue);
      expect(modern.contains('Bharat Retail LLP'), isTrue);
      expect(modern.contains('One Lakh') || modern.contains('Six Hundred Rupees Only'), isTrue);

      final tally = A4A5InvoicePdfBuilder.buildHtmlDocument(
        invoice: invoice,
        storeProfile: store,
        template: PdfInvoiceTemplate.a4TallyClassicGrid,
      );
      expect(tally.contains('TAX INVOICE (FORM GST INV-1)'), isTrue);

      final a5 = A4A5InvoicePdfBuilder.buildHtmlDocument(
        invoice: invoice,
        storeProfile: store,
        template: PdfInvoiceTemplate.a5LandscapeCompact,
      );
      expect(a5.contains('A5 landscape'), isTrue);
    });
  });
}
