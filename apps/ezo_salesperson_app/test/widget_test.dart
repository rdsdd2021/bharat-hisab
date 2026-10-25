import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_salesperson_app/main.dart';

void main() {
  testWidgets('Salesperson App smoke test', (WidgetTester tester) async {
    final db = LocalDatabase();
    await db.initialize();
    final repo = EzoOfflineRepository(db: db);

    const profile = BusinessProfile(
      id: 'test_store',
      storeName: 'Test Store',
      legalEntityName: 'Test Legal',
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

    final staff = StaffMember(
      id: 'test_staff',
      storeProfileId: profile.id,
      fullName: 'Test Staff',
      phone: '9876543210',
      pinCode: '1234',
      role: StaffRole.fieldSalesperson,
      canEditPrices: false,
      canDeleteBills: false,
      canViewProfitReports: false,
      canCollectUdhaar: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(EzoSalespersonApp(
      repository: repo,
      storeProfile: profile,
      staff: staff,
    ));

    expect(find.byType(EzoSalespersonApp), findsOneWidget);
  });
}
