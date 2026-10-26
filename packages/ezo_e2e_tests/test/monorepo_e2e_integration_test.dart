import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import 'package:ezo_online_dukan_ai/ezo_online_dukan_ai.dart';
import 'package:ezo_l10n_vernacular/ezo_l10n_vernacular.dart';

void main() {
  late LocalDatabase db;
  late EzoOfflineRepository repo;

  const storeProfile = BusinessProfile(
    id: 'store_e2e',
    storeName: 'EZO Mega Kirana',
    legalEntityName: 'EZO Retail Technologies LLP',
    gstin: '27AABCT9999F1Z5',
    stateCode: '27',
    stateName: 'Maharashtra',
    address: 'FC Road, Shivaji Nagar, Pune - 411005',
    phone: '9822112233',
    email: 'contact@ezokirana.com',
    upiId: 'ezokirana@icici',
    bankName: 'ICICI Bank',
    accountNumber: '001122334455',
    ifscCode: 'ICIC0000011',
    branding: WhiteLabelBranding(
      brandAppName: 'EZO POS',
      resellerCompanyName: 'EZO Technologies',
      supportWhatsApp: '919822112233',
      primaryColorHex: '#1E88E5',
      accentColorHex: '#FF6F00',
      receiptFooterTagline: 'Thank you for shopping! Powered by EZO POS',
    ),
  );

  setUp(() async {
    db = LocalDatabase();
    await db.initialize();
    repo = EzoOfflineRepository(db: db);
    await repo.saveProfile(storeProfile);
  });

  group('E2E Test 1: 2-Click GST & Non-GST Billing and Stock Deduction', () {
    test('Processes GST invoice, computes CGST/SGST, and deducts inventory atomically', () async {
      const rice = ProductItem(
        id: 'prod_rice',
        name: 'Basmati Rice 5kg',
        skuCode: 'RICE-5K',
        mrp: 600.0,
        sellingPrice: 500.0,
        purchasePrice: 420.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 20.0,
        lowStockThreshold: 5.0,
      );
      await repo.upsertProduct(rice);

      final line = EzoGstTaxEngine.buildLineItem(
        product: rice,
        quantity: 3,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      final invoice = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_e2e_1',
        invoiceNumber: 'EZO-2026-001',
        invoiceDate: DateTime.now(),
        storeProfile: storeProfile,
        lineItems: [line],
        settlementMode: SettlementMode.cash,
        amountReceived: 1500.0,
      );

      // Verify tax mathematics
      expect(invoice.grandTotal, equals(1500.0));
      expect(invoice.totalCgst + invoice.totalSgst, greaterThan(0.0));
      expect(invoice.totalIgst, equals(0.0));
      // Savings = (600 - 500) * 3 = 300
      expect(invoice.customerSavings, equals(300.0));

      // Commit to offline repository
      await repo.commitSalesInvoice(invoice);

      // Verify stock was deducted from 20 to 17
      final updatedRice = repo.getProduct('prod_rice');
      expect(updatedRice?.currentStock, equals(17.0));
      expect(updatedRice?.totalUnitsSold, equals(3.0));
    });

    test('Processes Non-GST Bill of Supply with zero tax fields', () async {
      const milk = ProductItem(
        id: 'prod_milk',
        name: 'Fresh Cow Milk 1L',
        skuCode: 'MILK-1L',
        mrp: 70.0,
        sellingPrice: 65.0,
        purchasePrice: 55.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 30.0,
      );
      await repo.upsertProduct(milk);

      final line = EzoGstTaxEngine.buildLineItem(
        product: milk,
        quantity: 2,
        isGstInvoice: false, // Non-GST Bill of Supply
      );

      final bill = EzoGstTaxEngine.createInvoiceDocument(
        id: 'bill_non_gst_1',
        invoiceNumber: 'BOS-001',
        docType: InvoiceDocType.nonGstBillOfSupply,
        invoiceDate: DateTime.now(),
        storeProfile: storeProfile,
        lineItems: [line],
      );

      expect(bill.taxableSubtotal, equals(130.0));
      expect(bill.totalTax, equals(0.0));
      expect(bill.grandTotal, equals(130.0));
    });
  });

  group('E2E Test 2: ESC/POS 58mm Chota vs 80mm Bada Printing & Dynamic UPI QR', () {
    test('Builds ESC/POS streams and confirms UPI QR command and savings banner', () {
      const item = ProductItem(
        id: 'p1',
        name: 'Cashew 500g',
        skuCode: 'CASH-500',
        mrp: 700.0,
        sellingPrice: 600.0,
      );
      final line = EzoGstTaxEngine.buildLineItem(product: item, quantity: 1);
      final inv = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_p_1',
        invoiceNumber: 'INV-PRINT-1',
        invoiceDate: DateTime.now(),
        storeProfile: storeProfile,
        lineItems: [line],
        amountReceived: 0.0,
        settlementMode: SettlementMode.creditUdhaar,
      );

      // 58mm Chota Stream
      final chotaBytes = EscPosThermalEngine.buildInvoiceByteStream(
        invoice: inv,
        storeProfile: storeProfile,
        rollWidth: ThermalRollWidth.chota58mm,
      );
      expect(chotaBytes.isNotEmpty, isTrue);

      // 80mm Bada Stream
      final badaBytes = EscPosThermalEngine.buildInvoiceByteStream(
        invoice: inv,
        storeProfile: storeProfile,
        rollWidth: ThermalRollWidth.bada80mm,
      );
      expect(badaBytes.isNotEmpty, isTrue);

      // Monospace ASCII Preview contains store name and savings
      final preview = EscPosThermalEngine.renderReceiptAsciiPreview(
        invoice: inv,
        storeProfile: storeProfile,
        rollWidth: ThermalRollWidth.chota58mm,
      );
      expect(preview.contains('EZO Mega Kirana'), isTrue);
      expect(preview.contains('YOU SAVED Rs. 100.00'), isTrue);
      expect(preview.contains('UDHAAR DUE:'), isTrue);
    });
  });

  group('E2E Test 3: Bulk Edit Batch Processing & Discount Barcode Stickers', () {
    test('Applies percentage markup and saves multiple SKUs in a single commit', () async {
      final editor = BulkInventoryEditor();
      final p1 = const ProductItem(id: 'i1', name: 'Item 1', skuCode: 'S1', category: 'General', mrp: 100.0, sellingPrice: 80.0);
      final p2 = const ProductItem(id: 'i2', name: 'Item 2', skuCode: 'S2', category: 'General', mrp: 200.0, sellingPrice: 160.0);
      await repo.upsertProduct(p1);
      await repo.upsertProduct(p2);

      editor.loadProducts([p1, p2]);
      editor.applyMarkupPercentage(percentage: 25.0);

      expect(editor.drafts[0].sellingPrice, equals(100.0));
      expect(editor.drafts[1].sellingPrice, equals(200.0));

      final committed = await editor.commitBulkEdit(repo);
      expect(committed, equals(2));
      expect(repo.getProduct('i1')?.sellingPrice, equals(100.0));
    });

    test('Generates discount-printed barcode stickers with SAVE banner', () {
      const garment = ProductItem(
        id: 'g1',
        name: 'Denim Jeans 32',
        skuCode: 'JEANS-32',
        mrp: 1999.0,
        sellingPrice: 1499.0,
      );

      final svg = BarcodeStickerDesigner.renderStickerSvg(
        product: garment,
        storeName: 'EZO Fashion',
      );

      expect(svg.contains('EZO Fashion'), isTrue);
      expect(svg.contains('MRP ₹1999'), isTrue);
      expect(svg.contains('Offer ₹1499'), isTrue);
      expect(svg.contains('SAVE 25%'), isTrue);
    });
  });

  group('E2E Test 4: Role-Based Access Control (RBAC) & License Enforcement', () {
    test('Cashier role prevents profit viewing and bill deletion', () {
      final cashier = StaffMember(
        id: 'c1',
        storeProfileId: storeProfile.id,
        fullName: 'Rajesh Cashier',
        phone: '9988776655',
        pinCode: '4321',
        role: StaffRole.counterCashier,
        canEditPrices: false,
        canDeleteBills: false,
        canViewProfitReports: false,
        canCollectUdhaar: true,
        createdAt: DateTime.now(),
      );

      expect(cashier.canEditPrices, isFalse);
      expect(cashier.canDeleteBills, isFalse);
      expect(cashier.canViewProfitReports, isFalse);
      expect(cashier.canCollectUdhaar, isTrue);

      final owner = StaffMember.owner(
        id: 'o1',
        storeProfileId: storeProfile.id,
        fullName: 'Store Owner',
        phone: '9999999999',
        pinCode: '0000',
      );
      expect(owner.canViewProfitReports, isTrue);
      expect(owner.canDeleteBills, isTrue);
    });

    test('Merchant license key validity and expiration logic', () {
      final activeProKey = MerchantLicenseKey(
        key: 'EZO-PRO-2026',
        merchantId: 'm1',
        storeName: 'Test Store',
        tier: SubscriptionTier.threeYearPro,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1000)),
      );
      expect(activeProKey.isValid, isTrue);
      expect(activeProKey.daysRemaining, greaterThan(900));

      final expiredKey = MerchantLicenseKey(
        key: 'EZO-EXP-2026',
        merchantId: 'm2',
        storeName: 'Old Store',
        tier: SubscriptionTier.freeTrial,
        issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        expiresAt: DateTime.now().subtract(const Duration(days: 15)),
      );
      expect(expiredKey.isValid, isFalse);
      expect(expiredKey.daysRemaining, equals(0));
    });
  });

  group('E2E Test 5: Online Dukan, Dhanda AI & WhatsApp Payment Collection', () {
    test('Converts incoming WhatsApp Online Dukan order to POS bill and generates reminder link', () {
      const snack = ProductItem(
        id: 's1',
        name: 'Potato Chips 100g',
        skuCode: 'CHIP-100',
        mrp: 50.0,
        sellingPrice: 40.0,
        showOnOnlineDukan: true,
      );

      final order = OnlineDukanOrder(
        orderId: 'DUKAN-900',
        customerName: 'Aakash Verma',
        customerPhone: '9876543210',
        deliveryAddress: 'Lane 4, Model Colony, Pune',
        items: const [OnlineDukanCartItem(product: snack, quantity: 5)],
        paymentMode: 'cod',
        createdAt: DateTime.now(),
      );

      expect(order.totalPayable, equals(200.0));

      final invoice = order.convertToPosInvoice(storeProfile);
      expect(invoice.grandTotal, equals(200.0));
      expect(invoice.partyName, equals('Cash Customer'));

      final customer = PartyAccount(
        id: 'cust_aakash',
        name: 'Aakash Verma',
        phone: '9876543210',
        openingBalance: 200.0,
      );

      final waReminder = WhatsAppReminderBuilder.buildReminderText(
        customer: customer,
        storeProfile: storeProfile,
      );
      expect(waReminder.contains('₹200.00'), isTrue);
      expect(waReminder.contains('ezokirana@icici'), isTrue);
    });
  });

  group('E2E Test 6: 10-Language Vernacular Runtime Localization', () {
    test('Switches UI language reactively without restarting app', () {
      final controller = LocaleController();
      controller.setLanguage(RegionalLanguage.en);
      expect(controller.tr('posBilling'), equals('POS Billing'));

      controller.setLanguage(RegionalLanguage.hi);
      expect(controller.tr('posBilling'), equals('बिलिंग और पीओएस'));

      controller.setLanguage(RegionalLanguage.bn);
      expect(controller.tr('posBilling'), equals('বিলিং এবং পিওএস'));

      controller.setLanguage(RegionalLanguage.gu);
      expect(controller.tr('posBilling'), equals('બિલિંગ અને પીઓએસ'));

      controller.setLanguage(RegionalLanguage.ta);
      expect(controller.tr('posBilling'), equals('பில்லிங் மற்றும் பிஓஎஸ்'));
    });
  });

  group('E2E Test 7: Modern Kirana Dual-Entry Flow, Parked Queues & Short-Codes', () {
    test('Verifies numeric short-codes, held sales queue serialization and line price updates', () {
      const looseRice = ProductItem(
        id: 'p_rice_loose',
        name: 'Loose Basmati Rice 1kg',
        skuCode: 'SKU-RICE-L',
        shortCode: '2',
        barcode: '8901030383793',
        mrp: 110.0,
        sellingPrice: 95.0,
        currentStock: 100.0,
      );

      const looseSugar = ProductItem(
        id: 'p_sugar_loose',
        name: 'Loose Pure Sugar 1kg',
        skuCode: 'SKU-SUGAR-L',
        shortCode: '1',
        barcode: '8901030383795',
        mrp: 55.0,
        sellingPrice: 50.0,
        currentStock: 80.0,
      );

      // Verify short codes
      expect(looseRice.shortCode, equals('2'));
      expect(looseSugar.shortCode, equals('1'));

      // Build cart lines
      final line1 = EzoGstTaxEngine.buildLineItem(
        product: looseRice,
        quantity: 2.0,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      final line2 = EzoGstTaxEngine.buildLineItem(
        product: looseSugar,
        quantity: 1.0,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      // Park sale into queue
      final held = HeldSale(
        id: 'held_001',
        heldAt: DateTime.now(),
        customer: const PartyAccount(id: 'c1', name: 'Ramesh Sharma'),
        cartLines: [line1, line2],
        grandTotal: line1.totalAmount + line2.totalAmount,
        notes: 'Parked Bill #1',
      );

      expect(held.totalItemsCount, equals(2));
      expect(held.totalQuantity, equals(3.0));
      expect(held.grandTotal, equals(240.0));

      // Test JSON round-trip of HeldSale
      final json = held.toJson();
      final revived = HeldSale.fromJson(json);
      expect(revived.id, equals('held_001'));
      expect(revived.customer?.name, equals('Ramesh Sharma'));
      expect(revived.cartLines.length, equals(2));
      expect(revived.grandTotal, equals(240.0));

      // Test inline price override
      final discountedLine = EzoGstTaxEngine.buildLineItem(
        product: looseRice,
        quantity: 2.0,
        overrideUnitPrice: 90.0, // Discounted from 95 to 90
        isGstInvoice: true,
        isInterStateSupply: false,
      );
      expect(discountedLine.unitSellingPrice, equals(90.0));
      expect(discountedLine.totalAmount, equals(180.0));
      expect(discountedLine.itemSavings, equals(40.0)); // (110 * 2) - 180 = 40 savings
    });
  });
}
