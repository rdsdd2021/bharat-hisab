import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';

void main() {
  group('EzoInventoryService Stock Lifecycle', () {
    test('Deducts stock on sale, restores on return, and increments on purchase', () async {
      final db = LocalDatabase();
      final repo = EzoOfflineRepository(db: db);
      final inventoryService = EzoInventoryService(repository: repo);

      const item = ProductItem(
        id: 'p_maggi',
        name: 'Maggi Noodles 280g',
        skuCode: 'MAGGI-01',
        mrp: 60.0,
        sellingPrice: 55.0,
        currentStock: 50.0,
        lowStockThreshold: 10.0,
      );
      await repo.upsertProduct(item);

      // Sale of 10 units
      final saleInvoice = InvoiceDocument(
        id: 'inv_s',
        invoiceNumber: 'INV-S',
        invoiceDate: DateTime.now(),
        storeProfileId: 's1',
        storeStateCode: '27',
        lineItems: const [
          InvoiceLineItem(
            productId: 'p_maggi',
            itemName: 'Maggi Noodles 280g',
            quantity: 10,
            mrp: 60.0,
            unitSellingPrice: 55.0,
            taxableAmount: 523.8,
            gstPercent: 5.0,
            totalAmount: 550.0,
          ),
        ],
        grandTotal: 550.0,
        amountReceived: 550.0,
        createdAt: DateTime.now(),
      );

      await inventoryService.deductStockForSales(saleInvoice);
      expect(repo.getProduct('p_maggi')?.currentStock, equals(40.0));
      expect(repo.getProduct('p_maggi')?.totalUnitsSold, equals(10.0));

      // Return of 2 units
      final returnInvoice = saleInvoice.copyWith(
        id: 'inv_ret',
        lineItems: const [
          InvoiceLineItem(
            productId: 'p_maggi',
            itemName: 'Maggi Noodles 280g',
            quantity: 2,
            mrp: 60.0,
            unitSellingPrice: 55.0,
            taxableAmount: 104.76,
            gstPercent: 5.0,
            totalAmount: 110.0,
          ),
        ],
      );
      await inventoryService.restoreStockForReturn(returnInvoice);
      expect(repo.getProduct('p_maggi')?.currentStock, equals(42.0));
      expect(repo.getProduct('p_maggi')?.totalUnitsSold, equals(8.0));

      // Purchase of 20 units
      final purchaseInvoice = saleInvoice.copyWith(
        id: 'inv_purch',
        lineItems: const [
          InvoiceLineItem(
            productId: 'p_maggi',
            itemName: 'Maggi Noodles 280g',
            quantity: 20,
            mrp: 60.0,
            unitSellingPrice: 48.0,
            taxableAmount: 960.0,
            gstPercent: 5.0,
            totalAmount: 960.0,
          ),
        ],
      );
      await inventoryService.incrementStockForPurchase(purchaseInvoice);
      expect(repo.getProduct('p_maggi')?.currentStock, equals(62.0));
    });
  });

  group('BulkInventoryEditor Tests', () {
    test('Inline edits multiple SKUs and commits in a single batch', () async {
      final db = LocalDatabase();
      final repo = EzoOfflineRepository(db: db);
      final editor = BulkInventoryEditor();

      final p1 = const ProductItem(
        id: 'p1',
        name: 'Item A',
        skuCode: 'SKU-A',
        category: 'Grocery',
        mrp: 100.0,
        sellingPrice: 90.0,
      );
      final p2 = const ProductItem(
        id: 'p2',
        name: 'Item B',
        skuCode: 'SKU-B',
        category: 'Grocery',
        mrp: 200.0,
        sellingPrice: 180.0,
      );
      await repo.upsertProduct(p1);
      await repo.upsertProduct(p2);

      editor.loadProducts([p1, p2]);

      // Apply 10% markup to all Grocery items
      editor.applyMarkupPercentage(percentage: 10.0, categoryFilter: 'Grocery');

      expect(editor.drafts[0].sellingPrice, equals(99.0));
      expect(editor.drafts[1].sellingPrice, equals(198.0));

      final committed = await editor.commitBulkEdit(repo);
      expect(committed, equals(2));

      expect(repo.getProduct('p1')?.sellingPrice, equals(99.0));
      expect(repo.getProduct('p2')?.sellingPrice, equals(198.0));
    });
  });

  group('Barcode Sticker Designer Tests', () {
    test('Generates valid GS1 EAN-13 barcode with check digit and discount sticker SVG', () {
      final ean = BarcodeStickerDesigner.generateUniqueEan13(
        countryPrefix: '890',
        storeCode: '1234',
        itemSequence: 56,
      );

      expect(ean.length, equals(13));
      expect(ean.startsWith('890123400056'), isTrue);

      const product = ProductItem(
        id: 'p_sticker',
        name: 'Cotton Shirt XL',
        skuCode: 'SHIRT-XL',
        barcode: '8901234000567',
        mrp: 1299.0,
        sellingPrice: 899.0,
      );

      final svg = BarcodeStickerDesigner.renderStickerSvg(
        product: product,
        storeName: 'Raymond Retail',
      );

      expect(svg.contains('Raymond Retail'), isTrue);
      expect(svg.contains('MRP ₹1299'), isTrue);
      expect(svg.contains('Offer ₹899'), isTrue);
      expect(svg.contains('SAVE 31%'), isTrue);
    });
  });

  group('POS Upsell Recommender Tests', () {
    test('Recommends complementary high-margin items from cart lines', () {
      const upItem = ProductItem(
        id: 'p_sauce',
        name: 'Tomato Sauce 500g',
        skuCode: 'SAUCE-01',
        category: 'Snacks',
        mrp: 120.0,
        sellingPrice: 100.0,
        currentStock: 10.0,
      );

      const cartItem = ProductItem(
        id: 'p_pasta',
        name: 'Italian Pasta 500g',
        skuCode: 'PASTA-01',
        category: 'Snacks',
        mrp: 150.0,
        sellingPrice: 130.0,
        upsellProductIds: ['p_sauce'],
      );

      final suggestions = UpsellRecommender.getUpsellSuggestions(
        cartLines: const [
          InvoiceLineItem(
            productId: 'p_pasta',
            itemName: 'Italian Pasta 500g',
            quantity: 1,
            mrp: 150.0,
            unitSellingPrice: 130.0,
            taxableAmount: 130.0,
            gstPercent: 0.0,
            totalAmount: 130.0,
          ),
        ],
        catalog: [cartItem, upItem],
      );

      expect(suggestions.length, equals(1));
      expect(suggestions.first.id, equals('p_sauce'));
    });
  });

  group('BarcodeScannerListener Tests', () {
    test('Accumulates characters and dispatches scanned barcode on newline', () {
      String? scannedBarcode;
      final listener = BarcodeScannerListener(
        onBarcodeScanned: (code) => scannedBarcode = code,
      );

      '8901234567890\n'.split('').forEach(listener.onKeyEvent);
      expect(scannedBarcode, equals('8901234567890'));
    });
  });
}
