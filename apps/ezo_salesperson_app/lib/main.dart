import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'src/salesperson_auth_screen.dart';
import 'src/salesperson_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = LocalDatabase();
  await db.initialize();
  final repo = EzoOfflineRepository(db: db);

  runApp(EzoSalespersonApp(repository: repo));
}

class EzoSalespersonApp extends StatefulWidget {
  final EzoOfflineRepository repository;

  const EzoSalespersonApp({
    super.key,
    required this.repository,
  });

  @override
  State<EzoSalespersonApp> createState() => _EzoSalespersonAppState();
}

class _EzoSalespersonAppState extends State<EzoSalespersonApp> {
  BusinessProfile? _activeProfile;
  StaffMember? _activeStaff;

  @override
  void initState() {
    super.initState();
    final profiles = widget.repository.getAllProfiles();
    final staffList = widget.repository.getAllStaff();
    if (profiles.isNotEmpty && staffList.isNotEmpty) {
      _activeProfile = profiles.first;
      _activeStaff = staffList.first;
    }
  }

  void _onAuthenticated(BusinessProfile profile, StaffMember staff) {
    setState(() {
      _activeProfile = profile;
      _activeStaff = staff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BharatHisab Field Sales & Udhaar Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: _activeProfile != null && _activeStaff != null
          ? SalespersonHomeScreen(
              repository: widget.repository,
              storeProfile: _activeProfile!,
              staff: _activeStaff!,
            )
          : SalespersonAuthScreen(
              repository: widget.repository,
              onAuthenticated: _onAuthenticated,
            ),
    );
  }
}
