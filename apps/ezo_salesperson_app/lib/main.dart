import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'src/salesperson_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = LocalDatabase();
  await db.initialize();
  final repo = EzoOfflineRepository(db: db);

  final profile = repo.getAllProfiles().isNotEmpty
      ? repo.getAllProfiles().first
      : const BusinessProfile(
          id: 'store_default',
          storeName: 'EZO Retail Store',
          legalEntityName: 'EZO Retail',
          gstin: '27AABCT1234F1Z5',
          stateCode: '27',
          stateName: 'Maharashtra',
          address: 'Main Market',
          phone: '9876543210',
          email: 'sales@ezo.com',
          upiId: 'ezostore@upi',
          bankName: 'Bank',
          accountNumber: '1',
          ifscCode: 'IFSC001',
        );

  final staff = repo.getAllStaff().isNotEmpty
      ? repo.getAllStaff().first
      : StaffMember(
          id: 'staff_field_1',
          storeProfileId: profile.id,
          fullName: 'Anil Kumar (Sales Rep)',
          phone: '9822003344',
          pinCode: '1234',
          role: StaffRole.fieldSalesperson,
          canEditPrices: false,
          canDeleteBills: false,
          canViewProfitReports: false,
          canCollectUdhaar: true,
          createdAt: DateTime.now(),
        );

  runApp(EzoSalespersonApp(
    repository: repo,
    storeProfile: profile,
    staff: staff,
  ));
}

class EzoSalespersonApp extends StatelessWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final StaffMember staff;

  const EzoSalespersonApp({
    super.key,
    required this.repository,
    required this.storeProfile,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EZO Sales & Field Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: SalespersonHomeScreen(
        repository: repository,
        storeProfile: storeProfile,
        staff: staff,
      ),
    );
  }
}
