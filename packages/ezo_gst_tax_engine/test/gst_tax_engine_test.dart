import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';

void main() {
  group('EzoGstTaxEngine - Line Item Calculations', () {
    test('Calculates Tax-Inclusive GST correctly with Intra-State CGST/SGST split', () {
      const product = ProductItem(
        id: 'p_inc',
        name: 'Packaged Tea 500g',
        skuCode: 'TEA-01',
        hsnSacCode: '0902',
        mrp: 105.0,
        sellingPrice: 105.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
      );

      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: 2.0,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      // Gross = 210. Taxable = 210 / 1.05 = 200. Total GST = 10. CGST = 5, SGST = 5
      expect(line.taxableAmount, equals(200.0));
      expect(line.cgstAmount, equals(5.0));
      expect(line.sgstAmount, equals(5.0));
      expect(line.igstAmount, equals(0.0));
      expect(line.totalAmount, equals(210.0));
    });

    test('Calculates Tax-Exclusive GST correctly with Inter-State 100% IGST', () {
      const product = ProductItem(
        id: 'p_exc',
        name: 'LED Monitor',
        skuCode: 'MON-01',
        hsnSacCode: '8528',
        mrp: 12000.0,
        sellingPrice: 10000.0,
        gstPercent: 18.0,
        isTaxInclusive: false,
      );

      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: 1.0,
        isGstInvoice: true,
        isInterStateSupply: true,
      );

      // Gross line = 10000. Taxable = 10000. IGST = 1800. Total = 11800
      expect(line.taxableAmount, equals(10000.0));
      expect(line.igstAmount, equals(1800.0));
      expect(line.cgstAmount, equals(0.0));
      expect(line.sgstAmount, equals(0.0));
      expect(line.totalAmount, equals(11800.0));
    });

    test('Handles Non-GST Bill of Supply by zeroing all taxes', () {
      const product = ProductItem(
        id: 'p_wheat',
        name: 'Fresh Wheat Atta 10kg',
        skuCode: 'ATTA-01',
        mrp: 400.0,
        sellingPrice: 380.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
      );

      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: 1.0,
        isGstInvoice: false, // Non-GST Bill
      );

      expect(line.taxableAmount, equals(380.0));
      expect(line.cgstAmount, equals(0.0));
      expect(line.sgstAmount, equals(0.0));
      expect(line.igstAmount, equals(0.0));
      expect(line.totalAmount, equals(380.0));
    });
  });

  group('EzoGstTaxEngine - Invoice Document Assembly', () {
    test('Calculates nearest rupee round off and customer savings', () {
      const store = BusinessProfile(
        id: 's1',
        storeName: 'Bharat Supermarket',
        legalEntityName: 'Bharat Retail LLP',
        gstin: '27AABCE1234F1Z5',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'MG Road, Pune',
        phone: '9876543210',
        email: 'info@bharatsupermarket.com',
        upiId: 'bharatretail@upi',
        bankName: 'HDFC Bank',
        accountNumber: '50200012345678',
        ifscCode: 'HDFC0001234',
      );

      const product = ProductItem(
        id: 'p1',
        name: 'Almonds 500g',
        skuCode: 'ALM-01',
        hsnSacCode: '0802',
        mrp: 600.0,
        sellingPrice: 500.0,
        gstPercent: 12.0,
        isTaxInclusive: true,
      );

      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: 1.0,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      final invoice = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_round_1',
        invoiceNumber: 'INV-1001',
        invoiceDate: DateTime.now(),
        storeProfile: store,
        lineItems: [line],
        billLevelDiscount: 10.35, // causes fractional total
      );

      // Raw total = 500 - 10.35 = 489.65 -> Rounds to 490.00, roundOff = +0.35
      expect(invoice.grandTotal, equals(490.0));
      expect(invoice.roundOffAdjustment, closeTo(0.35, 0.01));
      // Savings = (600 - 500) item saving + 10.35 bill discount = 110.35
      expect(invoice.customerSavings, closeTo(110.35, 0.01));
    });
  });

  group('EzoReportEngine - Reports & Aggregators', () {
    test('Generates HSN Summary and GSTR-3B ITC summary', () {
      const store = BusinessProfile(
        id: 's1',
        storeName: 'Bharat Electronics',
        legalEntityName: 'Bharat Tech',
        gstin: '27AAAAA1234A1Z5',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'Mumbai',
        phone: '9999999999',
        email: 'bharat@test.com',
        upiId: 'bharat@upi',
        bankName: 'ICICI',
        accountNumber: '1111',
        ifscCode: 'ICIC0001',
      );

      const product1 = ProductItem(
        id: 'p1',
        name: 'USB Cable',
        skuCode: 'USB-01',
        hsnSacCode: '8544',
        mrp: 300.0,
        sellingPrice: 200.0,
        purchasePrice: 120.0,
        gstPercent: 18.0,
        isTaxInclusive: false,
      );

      final line1 = EzoGstTaxEngine.buildLineItem(
        product: product1,
        quantity: 5.0,
        isGstInvoice: true,
        isInterStateSupply: false,
      );

      final saleInv = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_s1',
        invoiceNumber: 'S-001',
        invoiceDate: DateTime.now(),
        storeProfile: store,
        lineItems: [line1],
      );

      final hsnReport = EzoReportEngine.generateGstr1HsnSummary(
        [saleInv],
        {'p1': product1},
      );

      expect(hsnReport.length, equals(1));
      expect(hsnReport.first.hsnSacCode, equals('8544'));
      expect(hsnReport.first.totalQuantity, equals(5.0));
      expect(hsnReport.first.taxableValue, equals(1000.0));
      expect(hsnReport.first.centralTaxAmount, equals(90.0));
      expect(hsnReport.first.stateTaxAmount, equals(90.0));

      final gstr3b = EzoReportEngine.generateGstr3bSummary(
        salesInvoices: [saleInv],
        purchaseInvoices: [],
      );

      expect(gstr3b.outwardTaxableSupplies, equals(1000.0));
      expect(gstr3b.cgstPayable, equals(90.0));
      expect(gstr3b.sgstPayable, equals(90.0));
      expect(gstr3b.totalNetTaxPayable, equals(180.0));
    });

    test('Generates P&L statement and CSV export', () {
      final now = DateTime.now();
      const product = ProductItem(
        id: 'p1',
        name: 'Headphones',
        skuCode: 'HP-01',
        mrp: 2000.0,
        sellingPrice: 1500.0,
        purchasePrice: 1000.0,
      );

      const store = BusinessProfile(
        id: 's1',
        storeName: 'Audio Hub',
        legalEntityName: 'Audio Hub',
        gstin: '27BBBBB1234B1Z5',
        stateCode: '27',
        stateName: 'MH',
        address: 'Pune',
        phone: '123',
        email: 'a@b.com',
        upiId: 'a@upi',
        bankName: 'SBI',
        accountNumber: '1',
        ifscCode: 'SBIN0001',
      );

      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: 2.0,
        isGstInvoice: false,
      );

      final invoice = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_pnl',
        invoiceNumber: 'INV-PNL',
        invoiceDate: now,
        storeProfile: store,
        lineItems: [line],
      );

      final pnl = EzoReportEngine.generateProfitAndLoss(
        sales: [invoice],
        productsMap: {'p1': product},
        totalExpenses: 200.0,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Revenue = 3000, COGS = 2000, Gross Profit = 1000, Expenses = 200, Net Profit = 800
      expect(pnl.grossRevenue, equals(3000.0));
      expect(pnl.costOfGoodsSold, equals(2000.0));
      expect(pnl.grossProfit, equals(1000.0));
      expect(pnl.netProfit, equals(800.0));

      final csv = EzoReportEngine.exportToCsv(
        headers: ['Metric', 'Amount'],
        rows: [
          ['Revenue', pnl.grossRevenue],
          ['COGS', pnl.costOfGoodsSold],
          ['Net Profit', pnl.netProfit],
        ],
      );
      expect(csv.contains('"Revenue","3000.0"'), isTrue);
    });
  });
}
