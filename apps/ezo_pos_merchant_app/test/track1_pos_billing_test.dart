import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_pos_merchant_app/src/controllers/pos_billing_controller.dart';
import 'package:ezo_pos_merchant_app/src/screens/pos_billing_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/receipt_preview_modal.dart';
import 'package:ezo_pos_merchant_app/src/screens/merchant_auth_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/industry_onboarding_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late EzoOfflineRepository repo;

  const profile = BusinessProfile(
    id: 'store_track1',
    storeName: 'Bharat Kirana & General Store',
    legalEntityName: 'Bharat Retail LLP',
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
    branding: WhiteLabelBranding(
      brandAppName: 'BharatHisab',
      resellerCompanyName: 'Bharat Tech',
      supportWhatsApp: '9876543210',
      primaryColorHex: '#4338CA',
      accentColorHex: '#4F46E5',
      receiptFooterTagline: 'Thank you for shopping!',
    ),
  );

  final staff = StaffMember(
    id: 'staff_01',
    storeProfileId: 'store_track1',
    fullName: 'Ramesh Patel',
    phone: '9876543210',
    pinCode: '1234',
    role: StaffRole.ownerAdmin,
    canEditPrices: true,
    canDeleteBills: true,
    createdAt: DateTime(2026, 1, 1),
  );

  const sampleSugar = ProductItem(
    id: 'prod_sugar',
    name: 'Madhur Sugar 1kg',
    skuCode: 'SKU-SUGAR-1',
    barcode: '8901030383795',
    shortCode: '1',
    category: 'Staples',
    mrp: 50.0,
    sellingPrice: 45.0,
    gstPercent: 5.0,
    isTaxInclusive: true,
    currentStock: 100.0,
  );

  const sampleRice = ProductItem(
    id: 'prod_rice',
    name: 'Basmati Rice 1kg',
    skuCode: 'SKU-RICE-1',
    barcode: '8901030383793',
    shortCode: '2',
    category: 'Staples',
    mrp: 120.0,
    sellingPrice: 100.0,
    gstPercent: 5.0,
    isTaxInclusive: true,
    currentStock: 80.0,
  );

  const sampleAtta = ProductItem(
    id: 'prod_atta',
    name: 'Aashirvaad Atta 5kg',
    skuCode: 'SKU-ATTA-5',
    barcode: '8901030383792',
    shortCode: '3',
    category: 'Flour',
    mrp: 280.0,
    sellingPrice: 260.0,
    gstPercent: 0.0,
    isTaxInclusive: true,
    currentStock: 50.0,
  );

  setUp(() async {
    db = LocalDatabase();
    await db.initialize();
    repo = EzoOfflineRepository(db: db);
    await repo.saveProfile(profile);
    await repo.saveStaff(staff);
    await repo.upsertProduct(sampleSugar);
    await repo.upsertProduct(sampleRice);
    await repo.upsertProduct(sampleAtta);
  });

  group('Track 1: PosBillingController Logic Audit', () {
    test('Cart additions, line quantity stepper and removal', () {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      expect(controller.cartLines.isEmpty, true);

      // Add Sugar
      controller.addProductToCart(sampleSugar);
      expect(controller.cartLines.length, 1);
      expect(controller.cartLines.first.quantity, 1.0);
      expect(controller.taxableSubtotal, greaterThan(0));

      // Increase Qty
      controller.updateCartLineQty(0, 3.0);
      expect(controller.cartLines.first.quantity, 3.0);

      // Add Rice
      controller.addProductToCart(sampleRice, qty: 2.0);
      expect(controller.cartLines.length, 2);

      // Remove Sugar
      controller.removeCartLine(0);
      expect(controller.cartLines.length, 1);
      expect(controller.cartLines.first.productId, sampleRice.id);

      // Clear All Cart
      controller.clearCart();
      expect(controller.cartLines.isEmpty, true);
    });

    test('Inline price override and line discount', () {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      controller.addProductToCart(sampleRice); // 1kg @ ₹100
      expect(controller.cartLines.first.unitSellingPrice, 100.0);
      expect(controller.grandTotal, 100.0);

      // Override Price to ₹95
      controller.updateCartLinePrice(0, 95.0);
      expect(controller.cartLines.first.unitSellingPrice, 95.0);
      expect(controller.grandTotal, 95.0);

      // Override Line Discount of ₹10
      controller.updateCartLineDiscount(0, 10.0);
      expect(controller.cartLines.first.lineDiscountAmount, 10.0);
      expect(controller.grandTotal, 85.0);

      // Simultaneous Price & Discount override
      controller.updateCartLinePriceAndDiscount(0, 90.0, 5.0);
      expect(controller.cartLines.first.unitSellingPrice, 90.0);
      expect(controller.cartLines.first.lineDiscountAmount, 5.0);
      expect(controller.grandTotal, 85.0);
    });

    test('Short-code, Barcode, and SKU product lookup', () {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      // Lookup by 1-digit Kirana short-code
      final byCode1 = controller.findProductByCode('1');
      expect(byCode1?.id, sampleSugar.id);

      final byCode3 = controller.findProductByCode('3');
      expect(byCode3?.id, sampleAtta.id);

      // Lookup by exact barcode
      final byBarcode = controller.findProductByCode('8901030383793');
      expect(byBarcode?.id, sampleRice.id);

      // Lookup by SKU
      final bySku = controller.findProductByCode('SKU-SUGAR-1');
      expect(bySku?.id, sampleSugar.id);

      // Quick add by code
      final success = controller.addProductByCode('1', qty: 2.0);
      expect(success, true);
      expect(controller.cartLines.length, 1);
      expect(controller.cartLines.first.quantity, 2.0);
    });

    test('Parked Bills Queue: Hold Sale, Resume Sale, and Delete Held Sale', () {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      controller.addProductToCart(sampleSugar);
      controller.addProductToCart(sampleRice);
      expect(controller.cartLines.length, 2);
      expect(controller.heldSales.isEmpty, true);

      // Hold Sale
      final heldSuccess = controller.holdCurrentSale(notes: 'Customer gone to fetch cash');
      expect(heldSuccess, true);
      expect(controller.heldSales.length, 1);
      expect(controller.cartLines.isEmpty, true); // Active cart cleared

      final heldId = controller.heldSales.first.id;
      expect(controller.heldSales.first.notes, 'Customer gone to fetch cash');

      // Add other items to active cart
      controller.addProductToCart(sampleAtta);
      expect(controller.cartLines.length, 1);

      // Resume Held Sale
      final resumeSuccess = controller.resumeHeldSale(heldId);
      expect(resumeSuccess, true);
      expect(controller.heldSales.isEmpty, true);
      expect(controller.cartLines.length, 2); // Restored original 2 items
      expect(controller.cartLines.first.productId, sampleSugar.id);

      // Park again and test delete
      controller.holdCurrentSale(notes: 'Discarded token');
      expect(controller.heldSales.length, 1);
      final newHeldId = controller.heldSales.first.id;
      controller.deleteHeldSale(newHeldId);
      expect(controller.heldSales.isEmpty, true);
    });

    test('Customer selection, Settlement mode toggle, and Invoice Commit', () async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      const customer = PartyAccount(
        id: 'cust_01',
        name: 'Suresh Raina',
        phone: '9123456789',
        stateCode: '07', // Delhi (Inter-state supply)
        partyType: PartyType.customer,
      );

      controller.addProductToCart(sampleRice); // Has 5% GST
      expect(controller.totalCgst, greaterThan(0));
      expect(controller.totalIgst, 0.0);

      // Switch to inter-state customer
      controller.setCustomer(customer);
      expect(controller.selectedCustomer?.name, 'Suresh Raina');
      // Should now apply 100% IGST instead of CGST/SGST split
      expect(controller.totalIgst, greaterThan(0));
      expect(controller.totalCgst, 0.0);

      // Settlement mode toggle
      expect(controller.settlementMode, SettlementMode.cash);
      controller.setSettlementMode(SettlementMode.upiQr);
      expect(controller.settlementMode, SettlementMode.upiQr);

      controller.setSettlementMode(SettlementMode.creditUdhaar);
      expect(controller.settlementMode, SettlementMode.creditUdhaar);
      expect(controller.balanceUdhaarDue, controller.grandTotal);

      // Commit invoice
      final invoice = await controller.commitInvoice();
      expect(invoice.partyName, 'Suresh Raina');
      expect(invoice.settlementMode, SettlementMode.creditUdhaar);
      expect(controller.cartLines.isEmpty, true); // Cart cleared on commit
    });
  });

  group('Track 1: Screen UI Buttons & Modal Auditing', () {
    testWidgets('PosBillingScreen renders catalog, search, and action chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PosBillingScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.text('GST Tax Invoice'), findsOneWidget);
      expect(find.text('+ Customer'), findsOneWidget);
      expect(find.text('+ Add SKU'), findsOneWidget);
      expect(find.text('Held (0)'), findsOneWidget);
      expect(find.text('Numpad'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);

      // Search input field
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Kirana Numpad Modal: Tests all digits (1-9, 0, 00), Clear, Enter, multipliers, and short-codes', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PosBillingScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Numpad button to open Kirana Numpad modal
      await tester.ensureVisible(find.text('Numpad'));
      await tester.tap(find.text('Numpad'));
      await tester.pumpAndSettle();

      expect(find.text('Kirana Numpad (त्वरित शॉर्ट-कोड)'), findsOneWidget);

      // Test Multiplier Chips
      expect(find.text('½'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('5x'), findsOneWidget);

      // Select 2x multiplier
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();

      // Test all numeric keypad digits: 1-9, 0, 00, CLEAR
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('5'), findsWidgets);
      expect(find.text('6'), findsWidgets);
      expect(find.text('7'), findsWidgets);
      expect(find.text('8'), findsWidgets);
      expect(find.text('9'), findsWidgets);
      expect(find.text('0'), findsWidgets);
      expect(find.text('00'), findsOneWidget); // Required 00 button!
      expect(find.text('CLEAR'), findsOneWidget);

      // Tap digit '1' (Sugar short-code)
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      expect(find.text('Madhur Sugar 1kg'), findsWidgets);

      // Tap 00
      await tester.tap(find.text('00'));
      await tester.pumpAndSettle();

      // Tap CLEAR
      await tester.tap(find.text('CLEAR'));
      await tester.pumpAndSettle();

      // Tap short-code quick staple chip: '2: Rice'
      await tester.ensureVisible(find.text('2: Rice'));
      await tester.tap(find.text('2: Rice'));
      await tester.pumpAndSettle();
      expect(find.text('Basmati Rice 1kg'), findsWidgets);

      // Tap dedicated ADD / ENTER button
      final addEnterBtn = find.textContaining('ADD Basmati Rice 1kg');
      await tester.ensureVisible(addEnterBtn);
      await tester.tap(addEnterBtn);
      await tester.pumpAndSettle();

      // Verify item was added with 2x multiplier
      expect(controller.cartLines.length, 1);
      expect(controller.cartLines.first.quantity, 2.0);
    });

    testWidgets('Camera Barcode Scanning Modal: Flash, Camera Flip, Test Barcode Chips, Reticle Tap', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PosBillingScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Scan button in search bar
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Phone Barcode Scanner'), findsOneWidget);
      expect(find.text('Rear Main Camera (Auto-Focus)'), findsOneWidget);

      // Test camera flip button
      await tester.tap(find.byTooltip('Switch Camera'));
      await tester.pumpAndSettle();
      expect(find.text('Front Camera (HD)'), findsOneWidget);

      // Test flash/torch toggle
      await tester.tap(find.byTooltip('Flashlight'));
      await tester.pumpAndSettle();

      // Test tapping interactive optical viewfinder reticle
      await tester.tap(find.text('Tap Box to Capture Optical Scan'));
      await tester.pumpAndSettle();
      expect(controller.cartLines.length, 1);

      // Test in-stock test barcode chips (e.g. Tata Salt, Fortune Oil)
      await tester.tap(find.text('Aashirvaad Atta'));
      await tester.pumpAndSettle();
      expect(controller.cartLines.length, 2);
    });

    testWidgets('Parked Bills Queue Modal: Badges, Resume & Delete Actions', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      controller.addProductToCart(sampleSugar);
      controller.holdCurrentSale(notes: 'Queue Token #1');

      await tester.pumpWidget(
        MaterialApp(
          home: PosBillingScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Badge should show 1 held bill
      expect(find.text('Held (1)'), findsOneWidget);

      // Tap badge to open queue modal
      await tester.tap(find.text('Held (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Parked / Held Bills Queue (1)'), findsOneWidget);
      expect(find.text('Queue Token #1'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // Sale restored to active cart
      expect(controller.cartLines.length, 1);
      expect(controller.heldSales.isEmpty, true);
    });

    testWidgets('ReceiptPreviewModal: 58mm/80mm Format Tabs, UPI QR Dialog, WhatsApp Share', (tester) async {
      final controller = PosBillingController(
        repository: repo,
        initialProfile: profile,
        initialStaff: staff,
      );

      controller.addProductToCart(sampleSugar);
      final invoice = controller.buildCurrentInvoice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptPreviewModal(
              invoice: invoice,
              storeProfile: profile,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify format tabs
      expect(find.text('58mm Chota'), findsOneWidget);
      expect(find.text('80mm Bada'), findsOneWidget);
      expect(find.text('A4 Modern PDF'), findsOneWidget);
      expect(find.text('A4 Tally Grid'), findsOneWidget);

      // Switch to 80mm Bada
      await tester.tap(find.text('80mm Bada'));
      await tester.pumpAndSettle();

      // Verify action buttons
      expect(find.text('Print Slip'), findsOneWidget);
      expect(find.text('UPI QR'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Trigger UPI QR modal
      await tester.tap(find.text('UPI QR'));
      await tester.pumpAndSettle();

      expect(find.text('Instant UPI Dynamic QR'), findsOneWidget);
      expect(find.text('Copy UPI Link'), findsOneWidget);
      expect(find.text('Confirm Received'), findsOneWidget);

      // Confirm received
      await tester.tap(find.text('Confirm Received'));
      await tester.pumpAndSettle();

      // Test WhatsApp share button
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
    });

    testWidgets('MerchantAuthScreen: Sign in vs Sign up tabs, Clean slate toggle, Validation', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      BusinessProfile? authenticatedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantAuthScreen(
            repository: repo,
            onAuthenticated: (p, s) {
              authenticatedProfile = p;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab switcher
      expect(find.text('Create Business Account'), findsOneWidget);
      expect(find.text('Sign In with PIN'), findsOneWidget);

      // Switch to Sign Up tab
      await tester.tap(find.text('Create Business Account'));
      await tester.pumpAndSettle();

      // Clean slate checkbox
      expect(find.text('Start with Clean Empty Catalog (0 dummy items)'), findsOneWidget);
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Test "Already have a business account? Sign In with PIN" button
      final signInLink = find.text('Already have a business account? Sign In with PIN');
      expect(signInLink, findsOneWidget);
      await tester.ensureVisible(signInLink);
      await tester.tap(signInLink);
      await tester.pumpAndSettle();

      // Test Sign In with existing credentials
      final phoneField = find.widgetWithText(TextField, 'Enter your 10-digit mobile number');
      final pinField = find.widgetWithText(TextField, '••••');

      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(pinField, '1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In & Open Counter 🔓'));
      await tester.pumpAndSettle();

      expect(authenticatedProfile != null, true);
      expect(authenticatedProfile?.storeName, profile.storeName);
    });

    testWidgets('IndustryOnboardingWizardScreen: Next/Back, Vertical Selection, Review & Launch', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IndustryOnboardingWizardScreen(
            repository: repo,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4 • Select Industry Vertical'), findsOneWidget);

      // Select Restaurant & Cafe Vertical
      await tester.tap(find.text('Restaurant, Cafe & QSR'));
      await tester.pumpAndSettle();

      // Continue to Step 2
      await tester.tap(find.text('Continue Next →'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4 • Store Profile & Tax Setup'), findsOneWidget);

      // Test Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 4 • Select Industry Vertical'), findsOneWidget);

      // Proceed forward to Step 3
      await tester.tap(find.text('Continue Next →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Next →'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4 • Hardware & Receipt Format'), findsOneWidget);

      // Proceed to Step 4 (Review)
      await tester.tap(find.text('Continue Next →'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4 • Review & Instant Launch'), findsOneWidget);
      expect(find.text('Ready to Launch Your Store!'), findsOneWidget);

      // Launch Store
      await tester.tap(find.text('🚀 Launch Store & Seed Catalog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(completed, true);
    });
  });
}
