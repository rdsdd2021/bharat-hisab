import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'src/services/android_bluetooth_printer_driver.dart';
import 'src/screens/merchant_auth_screen.dart';
import 'src/screens/main_shell_layout.dart';
import 'src/theme/ezo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure backend API endpoint based on device environment
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    BackendApiService.configureForDevice(isPhysicalPhone: true);
    ThermalPrinterConnectionManager().registerTransportDriver(AndroidBluetoothPrinterDriver());
  } else {
    BackendApiService.configureForDevice();
  }

  // Initialize embedded offline local database
  final localDb = LocalDatabase();
  await localDb.initialize();

  final repository = EzoOfflineRepository(db: localDb);

  // NOTE: Zero forced pre-seeding! The merchant signs up and configures their real business!
  runApp(BharatHisabMerchantApp(repository: repository));
}

class BharatHisabMerchantApp extends StatefulWidget {
  final EzoOfflineRepository repository;

  const BharatHisabMerchantApp({
    super.key,
    required this.repository,
  });

  @override
  State<BharatHisabMerchantApp> createState() => _BharatHisabMerchantAppState();
}

class _BharatHisabMerchantAppState extends State<BharatHisabMerchantApp> {
  BusinessProfile? _authenticatedProfile;
  StaffMember? _authenticatedStaff;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    final profiles = widget.repository.getAllProfiles();
    final staff = widget.repository.getAllStaff();
    if (profiles.isNotEmpty && staff.isNotEmpty) {
      _authenticatedProfile = profiles.first;
      _authenticatedStaff = staff.first;
    }
  }

  void _onAuthenticated(BusinessProfile profile, StaffMember staff) {
    setState(() {
      _authenticatedProfile = profile;
      _authenticatedStaff = staff;
    });
  }

  void _onLogout() {
    setState(() {
      _authenticatedStaff = null;
    });
  }

  Future<void> _onResetAll() async {
    await widget.repository.clearAll();
    setState(() {
      _authenticatedProfile = null;
      _authenticatedStaff = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BharatHisab (भारतहिसाब)',
      debugShowCheckedModeBanner: false,
      theme: EzoTheme.lightTheme,
      home: _authenticatedProfile != null && _authenticatedStaff != null
          ? MainShellLayout(
              repository: widget.repository,
              initialProfile: _authenticatedProfile!,
              initialStaff: _authenticatedStaff!,
              onLogout: _onLogout,
              onResetAll: _onResetAll,
            )
          : MerchantAuthScreen(
              repository: widget.repository,
              onAuthenticated: _onAuthenticated,
              initialTab: widget.repository.getAllProfiles().isEmpty ? 0 : 1,
            ),
    );
  }
}
