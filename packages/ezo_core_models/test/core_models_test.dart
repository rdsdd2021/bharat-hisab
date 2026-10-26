import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';

void main() {
  group('ProductItem Model Tests', () {
    test('Calculates discountOnMrp and discountPercent accurately', () {
      const item = ProductItem(
        id: 'p1',
        name: 'Basmati Rice 5kg',
        skuCode: 'RICE-01',
        mrp: 500.0,
        sellingPrice: 400.0,
        purchasePrice: 320.0,
        currentStock: 10.0,
        lowStockThreshold: 3.0,
      );

      expect(item.discountOnMrp, equals(100.0));
      expect(item.discountPercent, equals(20.0));
      expect(item.isLowStock, isFalse);
      expect(item.isOutOfStock, isFalse);
      expect(item.stockAssetValueAtCost, equals(3200.0));
      expect(item.stockRetailValue, equals(4000.0));
    });

    test('Identifies low stock and out of stock conditions', () {
      const lowStockItem = ProductItem(
        id: 'p2',
        name: 'Milk 1L',
        skuCode: 'MILK-01',
        mrp: 60.0,
        sellingPrice: 60.0,
        currentStock: 2.0,
        lowStockThreshold: 5.0,
      );
      expect(lowStockItem.isLowStock, isTrue);
      expect(lowStockItem.isOutOfStock, isFalse);

      const oosItem = ProductItem(
        id: 'p3',
        name: 'Ghee 1L',
        skuCode: 'GHEE-01',
        mrp: 650.0,
        sellingPrice: 650.0,
        currentStock: 0.0,
        lowStockThreshold: 5.0,
      );
      expect(oosItem.isLowStock, isFalse);
      expect(oosItem.isOutOfStock, isTrue);
    });
  });

  group('InvoiceDocument Model Tests', () {
    test('Computes balanceUdhaarDue and customerSavings correctly', () {
      final now = DateTime.now();
      const lineItem1 = InvoiceLineItem(
        productId: 'p1',
        itemName: 'Basmati Rice 5kg',
        quantity: 2,
        mrp: 500.0,
        unitSellingPrice: 400.0,
        taxableAmount: 761.90,
        gstPercent: 5.0,
        cgstAmount: 19.05,
        sgstAmount: 19.05,
        totalAmount: 800.0,
      );

      final invoice = InvoiceDocument(
        id: 'inv_101',
        invoiceNumber: 'INV-2026-0001',
        invoiceDate: now,
        storeProfileId: 'store_1',
        storeStateCode: '27',
        partyStateCode: '27',
        lineItems: [lineItem1],
        taxableSubtotal: 761.90,
        totalCgst: 19.05,
        totalSgst: 19.05,
        billDiscountAmount: 50.0,
        grandTotal: 750.0,
        amountReceived: 500.0,
        settlementMode: SettlementMode.creditUdhaar,
        createdAt: now,
      );

      expect(invoice.isInterStateSupply, isFalse);
      // Customer regular total = 500*2 = 1000. Paid total = 800. Line saving = 200. Plus bill discount 50 = 250.
      expect(invoice.customerSavings, equals(250.0));
      // Grand total = 750, Received = 500. Udhaar due = 250.
      expect(invoice.balanceUdhaarDue, equals(250.0));
    });

    test('Detects inter-state supply for IGST', () {
      final now = DateTime.now();
      final invoice = InvoiceDocument(
        id: 'inv_102',
        invoiceNumber: 'INV-2026-0002',
        invoiceDate: now,
        storeProfileId: 'store_1',
        storeStateCode: '27', // Maharashtra
        partyStateCode: '07', // Delhi
        grandTotal: 1000.0,
        amountReceived: 1000.0,
        createdAt: now,
      );
      expect(invoice.isInterStateSupply, isTrue);
    });
  });

  group('Khata & Party Account Tests', () {
    test('Computes customer Khata net balance properly', () {
      final now = DateTime.now();
      final entry1 = KhataLedgerEntry(
        id: 'k1',
        partyId: 'cust_1',
        entryDate: now.subtract(const Duration(days: 2)),
        debitYouGave: 1200.0,
        creditYouGot: 0.0,
        createdAt: now,
      );
      final entry2 = KhataLedgerEntry(
        id: 'k2',
        partyId: 'cust_1',
        entryDate: now.subtract(const Duration(days: 1)),
        debitYouGave: 0.0,
        creditYouGot: 500.0,
        createdAt: now,
      );

      final party = PartyAccount(
        id: 'cust_1',
        name: 'Rahul Sharma',
        partyType: PartyType.customer,
        openingBalance: 100.0,
        creditLimit: 1000.0,
        ledgerEntries: [entry1, entry2],
      );

      // Opening balance 100 + 1200 debit - 500 credit = 800 net due
      expect(party.netBalance, equals(800.0));
      expect(party.isOverCreditLimit, isFalse);
    });
  });

  group('MerchantLicenseKey Tests', () {
    test('Validates lifetime enterprise and expiration logic', () {
      final lifetime = MerchantLicenseKey(
        key: 'BH-LIFE-9999',
        merchantId: 'm1',
        storeName: 'Kirana King',
        tier: SubscriptionTier.lifetimeEnterprise,
        issuedAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(lifetime.isValid, isTrue);
      expect(lifetime.daysRemaining, greaterThan(1000));

      final expired = MerchantLicenseKey(
        key: 'BH-EXP-1111',
        merchantId: 'm2',
        storeName: 'Old Store',
        tier: SubscriptionTier.oneYearStandard,
        issuedAt: DateTime.now().subtract(const Duration(days: 400)),
        expiresAt: DateTime.now().subtract(const Duration(days: 35)),
      );
      expect(expired.isValid, isFalse);
      expect(expired.daysRemaining, equals(0));
    });
  });

  group('Offline Storage & Outbox Sync Tests', () {
    test('Persists product, executes invoice stock deduction and sync queueing', () async {
      final db = LocalDatabase();
      await db.initialize();
      final repo = EzoOfflineRepository(db: db);

      const product = ProductItem(
        id: 'p_stock_test',
        name: 'Sugar 1kg',
        skuCode: 'SUGAR-01',
        mrp: 50.0,
        sellingPrice: 45.0,
        currentStock: 20.0,
        lowStockThreshold: 5.0,
      );
      await repo.upsertProduct(product);

      final saved = repo.getProduct('p_stock_test');
      expect(saved?.currentStock, equals(20.0));

      // Record invoice selling 5 units on Udhaar
      final now = DateTime.now();
      const line = InvoiceLineItem(
        productId: 'p_stock_test',
        itemName: 'Sugar 1kg',
        quantity: 5,
        mrp: 50.0,
        unitSellingPrice: 45.0,
        taxableAmount: 214.28,
        gstPercent: 5.0,
        cgstAmount: 5.36,
        sgstAmount: 5.36,
        totalAmount: 225.0,
      );

      final invoice = InvoiceDocument(
        id: 'inv_stock_1',
        invoiceNumber: 'INV-001',
        invoiceDate: now,
        storeProfileId: 's1',
        storeStateCode: '27',
        partyId: 'cust_amit',
        partyStateCode: '27',
        lineItems: [line],
        grandTotal: 225.0,
        amountReceived: 100.0, // Remaining 125 Udhaar
        settlementMode: SettlementMode.creditUdhaar,
        createdAt: now,
      );

      await repo.commitSalesInvoice(invoice);

      // Verify stock was reduced from 20 to 15
      final productAfterSale = repo.getProduct('p_stock_test');
      expect(productAfterSale?.currentStock, equals(15.0));
      expect(productAfterSale?.totalUnitsSold, equals(5.0));

      // Verify outbox sync entries exist
      final pendingSync = repo.getPendingSync();
      expect(pendingSync.isNotEmpty, isTrue);

      // Verify Udhaar entry was auto-posted to Khata for party
      final entries = db.getKhataEntriesForParty('cust_amit');
      expect(entries.length, equals(1));
      expect(entries.first.debitYouGave, equals(125.0));
    });
  });
}
