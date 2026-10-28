import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_pos_merchant_app/src/controllers/pos_billing_controller.dart';
import 'package:ezo_pos_merchant_app/src/widgets/barcode_scanner_modal.dart';
import 'package:ezo_pos_merchant_app/src/widgets/product_image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late EzoOfflineRepository repo;

  const profile = BusinessProfile(
    id: 'store_test',
    storeName: 'Test Kirana Store',
    legalEntityName: 'Test Kirana Pvt Ltd',
    gstin: '27AABCT1234F1Z5',
    stateCode: '27',
    stateName: 'Maharashtra',
    address: 'Market Yard, Pune',
    phone: '9876543210',
    email: 'contact@bharatkirana.in',
    upiId: 'bharatkirana@upi',
    bankName: 'State Bank of India',
    accountNumber: '309812739182',
    ifscCode: 'SBIN0001234',
    industryVertical: IndustryVertical.kiranaGrocery,
  );

  final staff = StaffMember(
    id: 'staff_1',
    storeProfileId: 'store_test',
    fullName: 'Ramesh Cashier',
    phone: '9876543210',
    pinCode: '1234',
    role: StaffRole.ownerAdmin,
    canEditPrices: true,
    canDeleteBills: true,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() async {
    db = LocalDatabase();
    await db.initialize();
    repo = EzoOfflineRepository(db: db);
    await repo.saveProfile(profile);
    await repo.saveStaff(staff);
  });

  group('Udhaar Mode Reset & Default-to-Cash Auditing', () {
    test('Udhaar order completion resets subsequent sale to Cash', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      final product = const ProductItem(
        id: 'p1',
        name: 'Basmati Rice 1kg',
        skuCode: 'RICE01',
        barcode: '8901234567890',
        mrp: 120.0,
        sellingPrice: 110.0,
        category: 'Groceries',
      );
      await repo.upsertProduct(product);

      final customer = const PartyAccount(
        id: 'c1',
        name: 'Sharma Ji',
        phone: '9820011223',
        partyType: PartyType.customer,
      );
      await repo.saveParty(customer);

      // Add item and switch to Udhaar
      controller.addProductToCart(product);
      controller.setCustomer(customer);
      controller.setSettlementMode(SettlementMode.creditUdhaar);

      expect(controller.settlementMode, SettlementMode.creditUdhaar);

      // Commit invoice (Order placed on Udhaar)
      final invoice = await controller.commitInvoice();
      expect(invoice.settlementMode, SettlementMode.creditUdhaar);
      expect(invoice.partyName, 'Sharma Ji');

      // Crucial Fix Check: Controller MUST default to Cash for next sale
      expect(controller.cartLines.isEmpty, true);
      expect(controller.settlementMode, SettlementMode.cash);

      // Reordering an item must default to Cash
      controller.addProductToCart(product);
      expect(controller.settlementMode, SettlementMode.cash);
      expect(controller.selectedCustomer, null);
    });

    test('Backing out or clearing cart resets settlement mode from Udhaar to Cash', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      final product = const ProductItem(
        id: 'p2',
        name: 'Sunflower Oil 1L',
        skuCode: 'OIL01',
        mrp: 150.0,
        sellingPrice: 140.0,
      );
      await repo.upsertProduct(product);

      controller.addProductToCart(product);
      controller.setSettlementMode(SettlementMode.creditUdhaar);
      expect(controller.settlementMode, SettlementMode.creditUdhaar);

      // User backs out / cancels order
      controller.clearCart();

      // Crucial Fix Check: Controller must reset to Cash
      expect(controller.settlementMode, SettlementMode.cash);
      expect(controller.cartLines.isEmpty, true);
    });

    test('Removing all cart lines resets settlement mode to Cash', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      final product = const ProductItem(
        id: 'p3',
        name: 'Sugar 1kg',
        skuCode: 'SUG01',
        mrp: 50.0,
        sellingPrice: 45.0,
      );
      await repo.upsertProduct(product);

      controller.addProductToCart(product);
      controller.setSettlementMode(SettlementMode.creditUdhaar);
      expect(controller.settlementMode, SettlementMode.creditUdhaar);

      // Remove single line item
      controller.removeCartLine(0);
      expect(controller.cartLines.isEmpty, true);
      expect(controller.settlementMode, SettlementMode.cash);
    });

    test('Resuming a parked sale defaults to Cash', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      final product = const ProductItem(
        id: 'p4',
        name: 'Tea Leaves 500g',
        skuCode: 'TEA01',
        mrp: 200.0,
        sellingPrice: 190.0,
      );
      await repo.upsertProduct(product);

      controller.addProductToCart(product);
      controller.setSettlementMode(SettlementMode.creditUdhaar);
      controller.holdCurrentSale(notes: 'Queue 1');

      expect(controller.settlementMode, SettlementMode.cash);
      expect(controller.heldSales.length, 1);

      final heldId = controller.heldSales.first.id;
      controller.resumeHeldSale(heldId);

      expect(controller.cartLines.length, 1);
      expect(controller.settlementMode, SettlementMode.cash);
    });
  });

  group('Product Image Picker & Barcode Scanner Widget Auditing', () {
    testWidgets('ProductImagePicker displays placeholder and opens preset selection', (tester) async {
      String selectedImage = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) => ProductImagePicker(
                currentImageUrl: selectedImage,
                onImageChanged: (val) {
                  setState(() => selectedImage = val);
                },
              ),
            ),
          ),
        ),
      );

      // Verify initial empty state
      expect(find.textContaining('Upload / Capture Product Photo'), findsOneWidget);

      // Tap to open image picker modal
      await tester.tap(find.textContaining('Upload / Capture Product Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Attach Product Image'), findsOneWidget);
      expect(find.text('Capture with Camera'), findsOneWidget);
      expect(find.textContaining('Atta / Flour'), findsOneWidget);

      // Tap Atta preset
      await tester.tap(find.textContaining('Atta / Flour'));
      await tester.pumpAndSettle();

      // Image URL should now be populated and preview card shown
      expect(selectedImage.isNotEmpty, true);
      expect(find.text('Photo Attached'), findsOneWidget);
    });

    testWidgets('BarcodeScannerModal captures scanned code and triggers callback', (tester) async {
      String scannedCode = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeScannerModal(
              onBarcodeScanned: (code) {
                scannedCode = code;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scan Product Barcode'), findsOneWidget);
      expect(find.text('Apply Code'), findsOneWidget);

      // Tap "Apply Code" to trigger scan detection
      await tester.tap(find.text('Apply Code'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(scannedCode.isNotEmpty, true);
      expect(scannedCode.startsWith('890'), true);
    });
  });
}
