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

  // Initialize SharedPreferences first for instant synchronous session reads
  final prefs = await SharedPreferences.getInstance();
  SessionManager.init(prefs);

  // Initialize embedded offline local database with dual persistence (SharedPreferences + Disk File)
  String? storageDir;
  if (!kIsWeb) {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      storageDir = appDocDir.path;
    } catch (_) {}
  }

  final initialJson = prefs.getString('ezo_local_db_json');

  final localDb = LocalDatabase(
    storageDirectory: storageDir,
    initialJsonData: initialJson,
    onPersist: (json) async {
      await prefs.setString('ezo_local_db_json', json);
    },
  );
  await localDb.initialize();

  final repository = EzoOfflineRepository(db: localDb);

  // Pre-resolve active merchant session BEFORE running the app widget tree
  BusinessProfile? initialProfile;
  StaffMember? initialStaff;

  final isLoggedIn = SessionManager.isLoggedIn();
  final savedStoreId = SessionManager.getActiveStoreId();
  final savedStaffId = SessionManager.getActiveStaffId();
  final savedPhone = SessionManager.getActivePhone();

  if (savedStoreId != null) {
    initialProfile = repository.getProfile(savedStoreId);
  }
  initialProfile ??= repository.getAllProfiles().firstOrNull;

  if (savedStaffId != null) {
    initialStaff = repository.getAllStaff().where((s) => s.id == savedStaffId).firstOrNull;
  }
  if (initialStaff == null && savedPhone != null) {
    initialStaff = repository.getAllStaff().where((s) => s.phone == savedPhone).firstOrNull;
  }
  initialStaff ??= repository.getAllStaff().firstOrNull;

  // Fallback: restore active user object directly from SessionManager SharedPreferences
  if (initialProfile == null) {
    initialProfile = SessionManager.getActiveProfile();
    if (initialProfile != null) {
      await repository.saveProfile(initialProfile);
    }
  }
  if (initialStaff == null) {
    initialStaff = SessionManager.getActiveStaff();
    if (initialStaff != null) {
      await repository.saveStaff(initialStaff);
    }
  }

  // If user never logged in and repository has no profiles, nullify
  if (!isLoggedIn && repository.getAllProfiles().isEmpty && SessionManager.getActiveProfile() == null) {
    initialProfile = null;
    initialStaff = null;
  }

  runApp(BharatHisabMerchantApp(
    repository: repository,
    initialProfile: initialProfile,
    initialStaff: initialStaff,
  ));
}

class BharatHisabMerchantApp extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile? initialProfile;
  final StaffMember? initialStaff;

  const BharatHisabMerchantApp({
    super.key,
    required this.repository,
    this.initialProfile,
    this.initialStaff,
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
    _authenticatedProfile = widget.initialProfile;
    _authenticatedStaff = widget.initialStaff;
    if (_authenticatedProfile == null || _authenticatedStaff == null) {
      _checkExistingSession();
    }
  }

  void _checkExistingSession() {
    final isLoggedIn = SessionManager.isLoggedIn();
    final savedStoreId = SessionManager.getActiveStoreId();
    final savedStaffId = SessionManager.getActiveStaffId();
    final savedPhone = SessionManager.getActivePhone();

    final allProfiles = widget.repository.getAllProfiles();
    final allStaff = widget.repository.getAllStaff();

    BusinessProfile? profile;
    StaffMember? staff;

    if (savedStoreId != null) {
      profile = widget.repository.getProfile(savedStoreId);
    }
    profile ??= allProfiles.firstOrNull ?? SessionManager.getActiveProfile();

    if (savedStaffId != null) {
      staff = allStaff.where((s) => s.id == savedStaffId).firstOrNull;
    }
    if (staff == null && savedPhone != null) {
      staff = allStaff.where((s) => s.phone == savedPhone).firstOrNull;
    }
    staff ??= allStaff.firstOrNull ?? SessionManager.getActiveStaff();

    if ((isLoggedIn || allProfiles.isNotEmpty) && profile != null && staff != null) {
      setState(() {
        _authenticatedProfile = profile;
        _authenticatedStaff = staff;
      });
    }
  }

  void _onAuthenticated(BusinessProfile profile, StaffMember staff) async {
    await SessionManager.saveSession(
      phone: staff.phone,
      storeId: profile.id,
      staffId: staff.id,
      profile: profile,
      staff: staff,
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ezo_local_db_json');
    if (mounted) {
      setState(() {
        _authenticatedProfile = null;
        _authenticatedStaff = null;
      });
    }
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
