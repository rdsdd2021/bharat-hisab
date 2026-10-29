import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_pos_merchant_app/main.dart';
import 'package:ezo_pos_merchant_app/src/screens/main_shell_layout.dart';
import 'package:ezo_pos_merchant_app/src/screens/merchant_auth_screen.dart';
import 'package:ezo_pos_merchant_app/src/services/session_manager.dart';
import 'package:ezo_pos_merchant_app/src/services/hardware_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    SessionManager.init(prefs);
  });

  group('SessionManager & Persistent Auth Tests', () {
    test('Session starts empty with no active login', () async {
      final loggedIn = await SessionManager.isLoggedIn();
      final phone = await SessionManager.getActivePhone();
      final storeId = await SessionManager.getActiveStoreId();

      expect(loggedIn, isFalse);
      expect(phone, isNull);
      expect(storeId, isNull);
    });

    test('Saving session persists active merchant across cold boots', () async {
      await SessionManager.saveSession(
        phone: '9876543210',
        storeId: 'store_12345',
        staffId: 'staff_999',
        token: 'mock_jwt_token_abc',
      );

      final loggedIn = await SessionManager.isLoggedIn();
      final phone = await SessionManager.getActivePhone();
      final storeId = await SessionManager.getActiveStoreId();
      final staffId = await SessionManager.getActiveStaffId();
      final token = await SessionManager.getAuthToken();

      expect(loggedIn, isTrue);
      expect(phone, equals('9876543210'));
      expect(storeId, equals('store_12345'));
      expect(staffId, equals('staff_999'));
      expect(token, equals('mock_jwt_token_abc'));
    });

    test('Clearing session resets login flag and tokens on logout', () async {
      await SessionManager.saveSession(
        phone: '9876543210',
        storeId: 'store_12345',
        staffId: 'staff_999',
        token: 'token',
      );

      expect(await SessionManager.isLoggedIn(), isTrue);

      await SessionManager.clearSession();

      expect(await SessionManager.isLoggedIn(), isFalse);
      expect(await SessionManager.getActivePhone(), isNull);
      expect(await SessionManager.getActiveStoreId(), isNull);
      expect(await SessionManager.getActiveStaffId(), isNull);
      expect(await SessionManager.getAuthToken(), isNull);
    });

    test('LocalDatabase restores from raw JSON data cleanly', () async {
      final profile = BusinessProfile(
        id: 'store_test_persist',
        storeName: 'Shivaji Super Market',
        legalEntityName: 'Shivaji Super Market Pvt Ltd',
        gstin: '27AABCS1234H1Z0',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'MG Road, Pune',
        phone: '9822011223',
        email: 'shivaji@gmail.com',
        upiId: 'shivaji@okaxis',
        bankName: 'HDFC Bank',
        accountNumber: '5010023456789',
        ifscCode: 'HDFC0000123',
        defaultPrintFormat: PrintFormat.bada80mm,
        industryVertical: IndustryVertical.kiranaGrocery,
        branding: const WhiteLabelBranding(
          brandAppName: 'BharatHisab',
          resellerCompanyName: 'Bharat Commercial Tech Ltd',
          supportWhatsApp: '9822011223',
          primaryColorHex: '#1E88E5',
          accentColorHex: '#4F46E5',
          receiptFooterTagline: 'Dhanyawad! Visit again.',
        ),
      );

      final staff = StaffMember(
        id: 'staff_test_persist',
        storeProfileId: profile.id,
        fullName: 'Shivaji Rao',
        phone: '9822011223',
        pinCode: '1234',
        role: StaffRole.ownerAdmin,
        canEditPrices: true,
        canDeleteBills: true,
        canViewProfitReports: true,
        canCollectUdhaar: true,
        createdAt: DateTime.now(),
      );

      // Create in-memory db and save profile + staff
      String? savedJson;
      final db = LocalDatabase(
        onPersist: (json) async {
          savedJson = json;
        },
      );
      await db.initialize();
      await db.saveBusinessProfile(profile);
      await db.saveStaffMember(staff);

      expect(savedJson, isNotNull);
      expect(savedJson, contains('Shivaji Super Market'));
      expect(savedJson, contains('Shivaji Rao'));

      // Simulate app restart by initializing a new LocalDatabase from restored JSON
      final restoredDb = LocalDatabase(
        initialJsonData: savedJson,
      );
      await restoredDb.initialize();

      expect(restoredDb.getAllBusinessProfiles().length, equals(1));
      expect(restoredDb.getBusinessProfile('store_test_persist')?.storeName, equals('Shivaji Super Market'));
      expect(restoredDb.getAllStaffMembers().length, equals(1));
      expect(restoredDb.getStaffMember('staff_test_persist')?.fullName, equals('Shivaji Rao'));
    });

    testWidgets('BharatHisabMerchantApp boots directly into MainShellLayout on cold start when session exists', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = LocalDatabase();
      await db.initialize();
      final repo = EzoOfflineRepository(db: db);

      final profile = BusinessProfile(
        id: 'store_boot',
        storeName: 'Pune Fresh Mart',
        legalEntityName: 'Pune Fresh Mart Ltd',
        gstin: '',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'MG Road, Pune',
        phone: '9876543210',
        email: 'pune@fresh.com',
        upiId: 'pune@upi',
        bankName: 'SBI',
        accountNumber: '1234',
        ifscCode: 'SBIN0001',
        defaultPrintFormat: PrintFormat.chota58mm,
        industryVertical: IndustryVertical.kiranaGrocery,
        branding: const WhiteLabelBranding(
          brandAppName: 'BharatHisab',
          resellerCompanyName: 'Bharat',
          supportWhatsApp: '9876543210',
          primaryColorHex: '#1E88E5',
          accentColorHex: '#4F46E5',
          receiptFooterTagline: 'Thanks',
        ),
      );

      final staff = StaffMember(
        id: 'staff_boot',
        storeProfileId: profile.id,
        fullName: 'Ramesh Patel',
        phone: '9876543210',
        pinCode: '1234',
        role: StaffRole.ownerAdmin,
        canEditPrices: true,
        canDeleteBills: true,
        canViewProfitReports: true,
        canCollectUdhaar: true,
        createdAt: DateTime.now(),
      );

      await repo.saveProfile(profile);
      await repo.saveStaff(staff);

      await tester.pumpWidget(
        BharatHisabMerchantApp(
          repository: repo,
          initialProfile: profile,
          initialStaff: staff,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainShellLayout), findsOneWidget);
      expect(find.byType(MerchantAuthScreen), findsNothing);
    });

    test('SessionManager restores active profile and staff from physical disk file when SharedPreferences is blank', () async {
      final tempDir = Directory.systemTemp.createTempSync('session_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final prefs = await SharedPreferences.getInstance();
      SessionManager.init(prefs, storageDirectory: tempDir.path);

      final profile = BusinessProfile(
        id: 'store_disk_fallback',
        storeName: 'Disk Mirror Grocery',
        legalEntityName: 'Disk Mirror Ltd',
        gstin: '',
        stateCode: '27',
        stateName: 'Maharashtra',
        address: 'MG Road, Pune',
        phone: '9811223344',
        email: 'disk@mirror.com',
        upiId: 'disk@upi',
        bankName: 'SBI',
        accountNumber: '1111',
        ifscCode: 'SBIN0001',
        defaultPrintFormat: PrintFormat.chota58mm,
        industryVertical: IndustryVertical.kiranaGrocery,
        branding: const WhiteLabelBranding(
          brandAppName: 'BharatHisab',
          resellerCompanyName: 'Bharat',
          supportWhatsApp: '9811223344',
          primaryColorHex: '#1E88E5',
          accentColorHex: '#4F46E5',
          receiptFooterTagline: 'Thanks',
        ),
      );

      final staff = StaffMember(
        id: 'staff_disk_fallback',
        storeProfileId: profile.id,
        fullName: 'Aakash Sharma',
        phone: '9811223344',
        pinCode: '1234',
        role: StaffRole.ownerAdmin,
        canEditPrices: true,
        canDeleteBills: true,
        canViewProfitReports: true,
        canCollectUdhaar: true,
        createdAt: DateTime.now(),
      );

      // Save session with disk mirroring
      await SessionManager.saveSession(
        phone: '9811223344',
        storeId: profile.id,
        staffId: staff.id,
        profile: profile,
        staff: staff,
      );

      final diskFile = File('${tempDir.path}/bh_session.json');
      expect(diskFile.existsSync(), isTrue);

      // Simulate SharedPreferences being cleared (e.g. Android cache flush)
      SharedPreferences.setMockInitialValues({});
      final cleanPrefs = await SharedPreferences.getInstance();

      // Initialize with clean prefs, but point to existing disk directory
      SessionManager.init(cleanPrefs, storageDirectory: tempDir.path);

      expect(SessionManager.isLoggedIn(), isTrue);
      expect(SessionManager.getActivePhone(), equals('9811223344'));
      expect(SessionManager.getActiveStoreId(), equals('store_disk_fallback'));
      expect(SessionManager.getActiveStaffId(), equals('staff_disk_fallback'));
      expect(SessionManager.getActiveProfile()?.storeName, equals('Disk Mirror Grocery'));
      expect(SessionManager.getActiveStaff()?.fullName, equals('Aakash Sharma'));

      // Test clean logout deletes disk file
      await SessionManager.clearSession();
      expect(diskFile.existsSync(), isFalse);
      expect(SessionManager.isLoggedIn(), isFalse);
    });

    testWidgets('BharatHisabMerchantApp boots into MerchantAuthScreen when not logged in', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = LocalDatabase();
      await db.initialize();
      final repo = EzoOfflineRepository(db: db);

      await tester.pumpWidget(
        BharatHisabMerchantApp(
          repository: repo,
          initialProfile: null,
          initialStaff: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MerchantAuthScreen), findsOneWidget);
      expect(find.byType(MainShellLayout), findsNothing);
    });
  });

  group('HardwarePermissionService Tests', () {
    test('checkPermissions returns safe fallback on test platform', () async {
      final status = await HardwarePermissionService.checkPermissions();
      expect(status['allGranted'], isTrue);
    });

    test('requestAllHardwarePermissions succeeds on non-Android environment', () async {
      final granted = await HardwarePermissionService.requestAllHardwarePermissions();
      expect(granted, isTrue);
    });

    test('ensureBluetoothPermission succeeds on non-Android environment', () async {
      final granted = await HardwarePermissionService.ensureBluetoothPermission();
      expect(granted, isTrue);
    });

    test('ensureCameraPermission succeeds on non-Android environment', () async {
      final granted = await HardwarePermissionService.ensureCameraPermission();
      expect(granted, isTrue);
    });
  });
}
