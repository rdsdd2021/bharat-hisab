import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_pos_merchant_app/src/controllers/pos_billing_controller.dart';
import 'package:ezo_pos_merchant_app/src/screens/pos_billing_screen.dart';
import 'package:ezo_pos_merchant_app/src/screens/merchant_auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late EzoOfflineRepository repo;
  late BusinessProfile profile;
  late StaffMember staff;

  setUp(() async {
    db = LocalDatabase();
    await db.initialize();
    await db.clearAll();
    repo = EzoOfflineRepository(db: db);

    profile = const BusinessProfile(
      id: 'store_test_01',
      storeName: 'Bharat Kirana & Supermarket',
      legalEntityName: 'Bharat Retail Pvt Ltd',
      gstin: '27AABCE1234F1Z5',
      stateCode: '27',
      stateName: 'Maharashtra',
      address: 'Shop 10, Market Road, Pune',
      phone: '9876543210',
      email: 'owner@bharatkirana.com',
      upiId: '9876543210@upi',
      industryVertical: IndustryVertical.kiranaGrocery,
    );
    await repo.saveProfile(profile);

    staff = StaffMember.owner(
      id: 'staff_01',
      storeProfileId: profile.id,
      fullName: 'Vikram Joshi (Owner)',
      phone: '9876543210',
      pinCode: '1234',
    );
    await repo.saveStaff(staff);
  });

  tearDown(() async {
    await db.clearAll();
  });

  group('Industry Vertical Mode & Adaptation Tests', () {
    testWidgets('MerchantAuthScreen displays all 5 visual Industry Vertical cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MerchantAuthScreen(
            repository: repo,
            onAuthenticated: (_, __) {},
            initialTab: 0, // Sign Up
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Business Account'));

      await tester.pumpAndSettle();

      // Verify all 5 vertical titles are visible in cards
      expect(find.text('Kirana, Supermarket & Grocery'), findsOneWidget);
      expect(find.text('Restaurant, Cafe & QSR'), findsOneWidget);
      expect(find.text('Pharmacy & Healthcare'), findsOneWidget);
      expect(find.text('Garments & Apparel'), findsOneWidget);
      expect(find.text('Electronics & Mobiles'), findsOneWidget);

      // Verify feature badges
      expect(find.text('Retail FMCG'), findsOneWidget);
      expect(find.text('Hospitality'), findsOneWidget);
      expect(find.text('Healthcare'), findsOneWidget);
      expect(find.text('Fashion & Retail'), findsOneWidget);
      expect(find.text('Consumer Tech'), findsOneWidget);

      // Tap Restaurant card
      await tester.tap(find.text('Restaurant, Cafe & QSR'));
      await tester.pumpAndSettle();
    });

    testWidgets('PosBillingScreen adapts toolbar and controls for each Industry Vertical', (tester) async {
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

      // 1. Initial Kirana Mode
      expect(find.text('Kirana & Grocery'), findsOneWidget);
      expect(find.text('Weighing Scale Ready:'), findsOneWidget);

      // 2. Switch to Restaurant Mode with sample catalog
      await controller.switchIndustryVertical(IndustryVertical.restaurantCafe, loadSampleData: true);
      await tester.pumpAndSettle();

      expect(find.text('Restaurant / Cafe'), findsOneWidget);
      expect(find.text('Table / Room:'), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.text('Table 2'), findsOneWidget);

      // Verify sample restaurant food item is present
      expect(find.text('Paneer Butter Masala'), findsOneWidget);

      // Tap to add item to cart
      await tester.tap(find.text('Paneer Butter Masala'));
      await tester.pumpAndSettle();

      // Verify KOT button is present
      expect(find.text('🍳 Send / Print KOT (Table 1)'), findsOneWidget);

      // 3. Switch to Pharmacy Mode
      await controller.switchIndustryVertical(IndustryVertical.pharmacyHealth, loadSampleData: true);
      await tester.pumpAndSettle();

      expect(find.text('Pharmacy & Health'), findsOneWidget);
      expect(find.text('Rx Pharma Mode:'), findsOneWidget);
      expect(find.text('Batch & 90-Day Expiry Guard Active'), findsOneWidget);

      // 4. Switch to Garments Mode
      await controller.switchIndustryVertical(IndustryVertical.garmentsApparel, loadSampleData: true);
      await tester.pumpAndSettle();

      expect(find.text('Garments & Apparel'), findsOneWidget);
      expect(find.text('Size:'), findsOneWidget);
      expect(find.text('Color:'), findsOneWidget);
      expect(find.text('38x25mm Tag'), findsOneWidget);

      // 5. Switch to Electronics Mode
      await controller.switchIndustryVertical(IndustryVertical.electronicsMobiles, loadSampleData: true);
      await tester.pumpAndSettle();

      expect(find.text('Electronics & Mobile'), findsOneWidget);
      expect(find.text('Serial / 15-Digit IMEI:'), findsOneWidget);
      expect(find.text('1-Yr Warranty Cert Auto-Printed'), findsOneWidget);
    });
  });
}
