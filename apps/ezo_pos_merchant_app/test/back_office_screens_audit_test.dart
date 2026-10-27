import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_pos_merchant_app/src/screens/inventory_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/khata_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/reports_hub_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/settings_license_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/online_dukan_dhanda_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late EzoOfflineRepository repo;
  late BusinessProfile store;
  late StaffMember owner;

  setUp(() async {
    db = LocalDatabase();
    await db.initialize();
    repo = EzoOfflineRepository(db: db);

    store = const BusinessProfile(
      id: 'store_audit_01',
      storeName: 'Shree Ganesh Supermarket',
      legalEntityName: 'Shree Ganesh Retail Pvt Ltd',
      gstin: '27AABCU9603R1ZM',
      stateCode: '27',
      stateName: 'Maharashtra',
      address: 'Shop 12, Main Market, Mumbai 400001',
      phone: '9876543210',
      email: 'ganesh@supermarket.in',
      upiId: 'shreeganesh@upi',
      defaultPrintFormat: PrintFormat.chota58mm,
    );
    await repo.saveProfile(store);

    owner = StaffMember.owner(
      id: 'staff_owner',
      storeProfileId: store.id,
      fullName: 'Ganesh Shinde',
      phone: '9876543210',
      pinCode: '1122',
    );
    await repo.saveStaff(owner);

    // Seed 2 products
    const p1 = ProductItem(
      id: 'p_atta',
      name: 'Aashirvaad Shudh Chakki Atta 5kg',
      regionalName: 'आशीर्वाद आटा',
      skuCode: 'SKU-ATTA-5KG',
      barcode: '8901030001234',
      category: 'Groceries',
      unit: ItemUnit.pcs,
      mrp: 275.0,
      sellingPrice: 245.0,
      wholesalePrice: 230.0,
      purchasePrice: 215.0,
      currentStock: 40.0,
      lowStockThreshold: 10.0,
      gstPercent: 5.0,
      showOnOnlineDukan: true,
    );

    const p2 = ProductItem(
      id: 'p_oil',
      name: 'Fortune Sunlite Refined Oil 1L',
      regionalName: 'फॉर्च्यून तेल',
      skuCode: 'SKU-OIL-1L',
      barcode: '8901030005678',
      category: 'Groceries',
      unit: ItemUnit.pcs,
      mrp: 140.0,
      sellingPrice: 125.0,
      wholesalePrice: 118.0,
      purchasePrice: 110.0,
      currentStock: 4.0, // Low stock alert!
      lowStockThreshold: 10.0,
      gstPercent: 5.0,
      showOnOnlineDukan: true,
    );

    await repo.upsertProduct(p1);
    await repo.upsertProduct(p2);

    // Seed 1 customer party
    const cust = PartyAccount(
      id: 'cust_01',
      name: 'Rajesh Sharma',
      phone: '9822012345',
      address: 'Flat 402, Sai Residency',
      partyType: PartyType.customer,
    );
    await repo.saveParty(cust);

    // Seed 1 invoice
    final line = InvoiceLineItem(
      productId: p1.id,
      itemName: p1.name,
      hsnSacCode: '1101',
      unit: ItemUnit.pcs,
      quantity: 2.0,
      mrp: 275.0,
      unitSellingPrice: 245.0,
      taxableAmount: 466.67,
      gstPercent: 5.0,
      cgstAmount: 11.67,
      sgstAmount: 11.67,
      igstAmount: 0.0,
      totalAmount: 490.0,
    );

    final inv = InvoiceDocument(
      id: 'inv_test_001',
      invoiceNumber: 'BILL-1001',
      invoiceDate: DateTime.now(),
      docType: InvoiceDocType.gstTaxInvoice,
      storeProfileId: store.id,
      storeStateCode: '27',
      partyId: cust.id,
      partyName: cust.name,
      partyPhone: cust.phone,
      cashierStaffId: owner.id,
      cashierStaffName: owner.fullName,
      lineItems: [line],
      taxableSubtotal: 466.67,
      totalCgst: 11.67,
      totalSgst: 11.67,
      totalIgst: 0.0,
      grandTotal: 490.0,
      settlementMode: SettlementMode.creditUdhaar,
      amountReceived: 0.0,
      createdAt: DateTime.now(),
    );

    await repo.commitSalesInvoice(inv);
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('Screen 1 Audit: InventoryScreen full functional flow', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(InventoryScreen(repository: repo, storeProfile: store)));
    await tester.pumpAndSettle();

    // 1. Verify KPI summary cards
    expect(find.text('Total SKUs'), findsOneWidget);
    expect(find.text('Cost Valuation'), findsOneWidget);
    expect(find.text('Retail Valuation'), findsOneWidget);
    expect(find.text('Low Stock Alerts'), findsOneWidget);

    // 2. Verify Tab Bar
    expect(find.text('Item Catalog'), findsOneWidget);
    expect(find.text('Bulk Edit Grid'), findsOneWidget);
    expect(find.text('Barcode Stickers'), findsOneWidget);

    // 3. Verify Search and Filter Chips
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Low Stock (1)'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);

    // 4. Test Add Product FAB opens full dialog
    final addFab = find.byType(FloatingActionButton);
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();

    expect(find.text('Add New Product SKU'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add SKU'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 5. Test Stock Adjustment Modal
    expect(find.text('38 PCS'), findsOneWidget); // 40 - 2 billed = 38
    await tester.tap(find.text('38 PCS'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Stock Adjustment:'), findsOneWidget);
    expect(find.text('Stock In (+ Jama)'), findsOneWidget);
    expect(find.text('Stock Out (- Nikasi)'), findsOneWidget);
    expect(find.text('Confirm Stock In (+ Add)'), findsOneWidget);

    // Confirm stock adjustment to verify full functional flow
    await tester.tap(find.text('Confirm Stock In (+ Add)'));
    await tester.pumpAndSettle();

    // Verify stock is updated in repository
    final updatedAtta = repo.getProduct('p_atta')!;
    expect(updatedAtta.currentStock, 48.0); // 38 + 10 = 48!
  });

  testWidgets('Screen 2 Audit: KhataScreen customer credit & payment recording', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(KhataScreen(repository: repo, storeProfile: store, cashier: owner)));
    await tester.pumpAndSettle();

    // 1. Verify Receivables KPI card
    expect(find.textContaining('Total You Will Get'), findsOneWidget);
    expect(find.text('Customers (1)'), findsOneWidget);
    expect(find.text('Suppliers (0)'), findsOneWidget);

    // 2. Verify Customer Listed with balance
    expect(find.text('Rajesh Sharma'), findsOneWidget);
    expect(find.text('₹490.00'), findsWidgets);

    // 3. Verify Action Buttons exist on customer card
    expect(find.text('+ Udhaar'), findsOneWidget);
    expect(find.text('- Jama'), findsOneWidget);

    // 4. Test "Give Credit (+ Udhaar)" Modal
    await tester.tap(find.text('+ Udhaar'));
    await tester.pumpAndSettle();

    expect(find.text('Give Credit (+ Udhaar)'), findsOneWidget);
    expect(find.text('Confirm Udhaar (+ Add)'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 5. Test "Got Pay (- Jama)" Modal
    await tester.tap(find.text('- Jama'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Record Payment (- Jama)'), findsOneWidget);
    expect(find.text('Save & Issue Receipt'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Screen 3 Audit: ReportsHubScreen daily sales, GST & Cash Drawer', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(ReportsHubScreen(repository: repo, storeProfile: store)));
    await tester.pumpAndSettle();

    // 1. Verify Sub-Tabs
    expect(find.text('Daily Sales (बिक्री)'), findsOneWidget);
    expect(find.text('GST Tax Report (3B)'), findsOneWidget);
    expect(find.text('HSN Summary'), findsOneWidget);
    expect(find.text('Profit & Loss'), findsOneWidget);
    expect(find.text('Day-End Cash Drawer'), findsOneWidget);

    // 2. Verify Sales Invoices listed
    expect(find.text('BILL-1001'), findsOneWidget);
    expect(find.text('₹490.00'), findsWidgets);

    // 3. Tap invoice to open thermal slip detail modal
    await tester.tap(find.text('BILL-1001'));
    await tester.pumpAndSettle();

    expect(find.text('TAX INVOICE / RETAIL RECEIPT'), findsOneWidget);
    expect(find.text('Reprint Thermal Slip'), findsOneWidget);
    expect(find.text('Copy Slip'), findsOneWidget);

    await tester.tap(find.text('Reprint Thermal Slip'), warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('Screen 4 Audit: SettingsLicenseScreen profile, staff permissions & test print', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(SettingsLicenseScreen(
      repository: repo,
      storeProfile: store,
      onProfileUpdated: (_) {},
    )));
    await tester.pumpAndSettle();

    // 1. Verify Store profile fields
    expect(find.text('Shree Ganesh Supermarket'), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);

    // 2. Verify Thermal Printer Hardware controls
    expect(find.text('Scan Devices'), findsOneWidget);
    expect(find.text('Test Print Slip'), findsOneWidget);
    expect(find.text('58mm (Chota Roll - 32 cols)'), findsOneWidget);
    expect(find.text('80mm (Bada Roll - 48 cols)'), findsOneWidget);

    // 3. Verify Staff Management & Add Staff modal
    await tester.ensureVisible(find.text('Add Staff'));
    await tester.pumpAndSettle();
    expect(find.text('Add Staff'), findsOneWidget);
    expect(find.text('Ganesh Shinde'), findsOneWidget);

    await tester.tap(find.text('Add Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Staff Seat'), findsOneWidget);
    expect(find.text('Can Give Line-Item & Bill Discounts'), findsOneWidget);
    expect(find.text('Can Edit / Override Unit Selling Prices'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 4. Verify Backup & Reset buttons
    await tester.ensureVisible(find.text('Export Backup (JSON)'));
    await tester.pumpAndSettle();
    expect(find.text('Export Backup (JSON)'), findsOneWidget);
    expect(find.text('Reset Clean Slate / Wipe Store'), findsOneWidget);
  });

  testWidgets('Screen 5 Audit: OnlineDukanDhandaScreen activation switch, link sharing & AI review reply', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(OnlineDukanDhandaScreen(repository: repo, storeProfile: store)));
    await tester.pumpAndSettle();

    // 1. Verify Storefront Live & Activation Switch
    expect(find.text('WhatsApp Online Dukan is LIVE!'), findsOneWidget);
    expect(find.text('Copy Store Link'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);

    // 2. Switch to Dhanda AI Tab
    await tester.tap(find.text('Dhanda AI GBP'));
    await tester.pumpAndSettle();

    expect(find.text('Run Dhanda AI Audit & Re-Evaluate GBP'), findsOneWidget);
    expect(find.text('Generate AI Review Reply'), findsOneWidget);

    // Tap generate AI review reply
    await tester.tap(find.text('Generate AI Review Reply'));
    await tester.pumpAndSettle();

    expect(find.text('Copy Reply'), findsOneWidget);

    // 3. Switch to NearSearch SEO Tab
    await tester.tap(find.text('NearSearch SEO'));
    await tester.pumpAndSettle();

    expect(find.text('Refresh Local SEO Tags'), findsOneWidget);
    expect(find.text('Copy JSON-LD Tags'), findsOneWidget);
  });
}
