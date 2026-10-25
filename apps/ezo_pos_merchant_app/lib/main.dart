import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'src/demo/demo_data_seeder.dart';
import 'src/screens/main_shell_layout.dart';
import 'src/theme/ezo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize embedded offline local database
  final localDb = LocalDatabase();
  await localDb.initialize();

  final repository = EzoOfflineRepository(db: localDb);

  // If local store is empty, seed demo retail & kirana data
  if (repository.getAllProfiles().isEmpty) {
    await DemoDataSeeder.seedDemoStore(repository);
  }

  final profile = repository.getAllProfiles().first;
  final staff = repository.getAllStaff().first;

  runApp(EzoMerchantPosApp(
    repository: repository,
    profile: profile,
    staff: staff,
  ));
}

class EzoMerchantPosApp extends StatelessWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile profile;
  final StaffMember staff;

  const EzoMerchantPosApp({
    super.key,
    required this.repository,
    required this.profile,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: profile.branding.brandAppName,
      debugShowCheckedModeBanner: false,
      theme: EzoTheme.lightTheme,
      home: MainShellLayout(
        repository: repository,
        initialProfile: profile,
        initialStaff: staff,
      ),
    );
  }
}
