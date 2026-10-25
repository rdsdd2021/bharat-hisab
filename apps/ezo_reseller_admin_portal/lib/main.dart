import 'package:flutter/material.dart';
import 'src/reseller_dashboard_screen.dart';
import 'src/superadmin_auth_screen.dart';
import 'src/theme/ezo_admin_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EzoResellerAdminApp());
}

class EzoResellerAdminApp extends StatefulWidget {
  const EzoResellerAdminApp({super.key});

  @override
  State<EzoResellerAdminApp> createState() => _EzoResellerAdminAppState();
}

class _EzoResellerAdminAppState extends State<EzoResellerAdminApp> {
  bool _isAuthenticated = false;

  void _onLogin() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BharatHisab Superadmin & Reseller Control Tower',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      home: _isAuthenticated
          ? ResellerDashboardScreen(onLogout: _onLogout)
          : SuperadminAuthScreen(onAuthenticated: _onLogin),
    );
  }
}
