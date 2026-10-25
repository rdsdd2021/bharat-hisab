import 'package:flutter/material.dart';
import 'src/reseller_dashboard_screen.dart';
import 'src/theme/ezo_admin_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EzoResellerAdminApp());
}

class EzoResellerAdminApp extends StatelessWidget {
  const EzoResellerAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EZO Reseller License & Superadmin Control Tower',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      home: const ResellerDashboardScreen(),
    );
  }
}
