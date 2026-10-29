import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import 'src/services/android_bluetooth_printer_driver.dart';
import 'src/services/android_weighing_scale_driver.dart';
import 'src/services/session_manager.dart';
import 'src/services/hardware_permission_service.dart';
import 'src/screens/merchant_auth_screen.dart';
import 'src/screens/main_shell_layout.dart';
import 'src/theme/ezo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure backend API endpoint based on device environment
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    BackendApiService.configureForDevice(isPhysicalPhone: true);
    ThermalPrinterConnectionManager().registerTransportDriver(AndroidBluetoothPrinterDriver());
    WeighingScaleManager().registerTransportDriver(AndroidWeighingScaleDriver());
    // Proactively request Android hardware permissions on app launch
    HardwarePermissionService.requestAllHardwarePermissions();
  } else {
    BackendApiService.configureForDevice();
  }

  // Initialize embedded offline local database with persistent storage
  String? storageDir;
  String? webInitialJson;
  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      storageDir = appDocDir.path;
    } catch (_) {}
  } else {
    webInitialJson = prefs.getString('ezo_local_db_json');
  }

  final localDb = LocalDatabase(
    storageDirectory: storageDir,
    initialJsonData: webInitialJson,
    onPersist: kIsWeb
        ? (json) async {
            await prefs.setString('ezo_local_db_json', json);
          }
        : null,
  );
  await localDb.initialize();

  final repository = EzoOfflineRepository(db: localDb);

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
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    // Synchronous immediate check if repository already has profiles in memory
    final profiles = widget.repository.getAllProfiles();
    final staff = widget.repository.getAllStaff();
    if (profiles.isNotEmpty && staff.isNotEmpty) {
      _authenticatedProfile = profiles.first;
      _authenticatedStaff = staff.first;
      _isLoadingSession = false;
    }
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      final savedStoreId = await SessionManager.getActiveStoreId();
      final savedStaffId = await SessionManager.getActiveStaffId();
      final savedPhone = await SessionManager.getActivePhone();

      final allProfiles = widget.repository.getAllProfiles();
      final allStaff = widget.repository.getAllStaff();

      BusinessProfile? profile;
      StaffMember? staff;

      if (savedStoreId != null) {
        profile = widget.repository.getProfile(savedStoreId);
      }
      profile ??= allProfiles.firstOrNull;

      if (savedStaffId != null) {
        staff = allStaff.where((s) => s.id == savedStaffId).firstOrNull;
      }
      if (staff == null && savedPhone != null) {
        staff = allStaff.where((s) => s.phone == savedPhone).firstOrNull;
      }
      staff ??= allStaff.firstOrNull;

      if ((isLoggedIn || allProfiles.isNotEmpty) && profile != null && staff != null) {
        _authenticatedProfile = profile;
        _authenticatedStaff = staff;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingSession = false;
      });
    }
  }

  void _onAuthenticated(BusinessProfile profile, StaffMember staff) async {
    await SessionManager.saveSession(
      phone: staff.phone,
      storeId: profile.id,
      staffId: staff.id,
    );
    if (mounted) {
      setState(() {
        _authenticatedProfile = profile;
        _authenticatedStaff = staff;
      });
    }
  }

  Future<void> _onLogout() async {
    await SessionManager.clearSession();
    if (mounted) {
      setState(() {
        _authenticatedStaff = null;
        _authenticatedProfile = null;
      });
    }
  }

  Future<void> _onResetAll() async {
    await SessionManager.clearSession();
    await widget.repository.clearAll();
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ezo_local_db_json');
    }
    if (mounted) {
      setState(() {
        _authenticatedProfile = null;
        _authenticatedStaff = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession && _authenticatedProfile == null) {
      return MaterialApp(
        title: 'BharatHisab (भारतहिसाब)',
        debugShowCheckedModeBanner: false,
        theme: EzoTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFFF8FAFC),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
