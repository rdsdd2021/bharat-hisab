import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_salesperson_app/src/salesperson_auth_screen.dart';
import 'package:ezo_salesperson_app/src/salesperson_home_screen.dart';

void main() {
  testWidgets('SalespersonAuthScreen renders and authenticates agent', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = LocalDatabase();
    await db.initialize();
    final repo = EzoOfflineRepository(db: db);

    bool authenticated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SalespersonAuthScreen(
          repository: repo,
          onAuthenticated: (profile, staff) {
            authenticated = true;
          },
        ),
      ),
    );

    expect(find.text('Sales Representative Sign In'), findsOneWidget);
    expect(find.text('Start Field Session'), findsOneWidget);

    await tester.ensureVisible(find.text('Start Field Session'));
    await tester.tap(find.text('Start Field Session'));
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
  });

  testWidgets('SalespersonHomeScreen renders catalog, quantity counters, customer selector, and sync button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = LocalDatabase();
    await db.initialize();
    final repo = EzoOfflineRepository(db: db);

    const profile = BusinessProfile(
      id: 'test_store',
      storeName: 'Pune Mega Mart & Cafe',
      legalEntityName: 'Pune Mega Mart LLP',
      gstin: '27AABCT1234F1Z5',
      stateCode: '27',
      stateName: 'Maharashtra',
      address: 'Test Address',
      phone: '9876543210',
      email: 'test@test.com',
      upiId: 'test@upi',
      bankName: 'Test Bank',
      accountNumber: '1234567890',
      ifscCode: 'TEST0001',
    );
    await repo.saveProfile(profile);

    final staff = StaffMember(
      id: 'test_staff',
      storeProfileId: profile.id,
      fullName: 'Rohan Sharma',
      phone: '9876543210',
      pinCode: '1234',
      role: StaffRole.fieldSalesperson,
      canEditPrices: false,
      canDeleteBills: false,
      canViewProfitReports: false,
      canCollectUdhaar: true,
      createdAt: DateTime.now(),
    );
    await repo.saveStaff(staff);

    await tester.pumpWidget(
      MaterialApp(
        home: SalespersonHomeScreen(
          repository: repo,
          storeProfile: profile,
          staff: staff,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify top sync button
    expect(find.text('Sync to HQ'), findsOneWidget);

    // Verify customer selector bar
    expect(find.text('Walk-in Cash Customer'), findsOneWidget);
    expect(find.text('Select Customer'), findsOneWidget);

    // Verify catalog categories & Add button
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Add'), findsWidgets);

    // Add first product to cart -> changes to quantity counter
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();

    expect(find.text('Review & Checkout'), findsOneWidget);
  });
}
