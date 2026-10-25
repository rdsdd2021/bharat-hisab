import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme/ezo_admin_theme.dart';
import 'theme/google_fonts.dart';

class SuperadminAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SuperadminAuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<SuperadminAuthScreen> createState() => _SuperadminAuthScreenState();
}

class _SuperadminAuthScreenState extends State<SuperadminAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Sign In Form
  final _loginEmailCtrl = TextEditingController(text: 'admin@bharathisab.com');
  final _loginPinCtrl = TextEditingController(text: '889900');
  bool _obscurePin = true;

  // Sign Up / Master Registration Form
  final _nameCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regPinCtrl = TextEditingController();
  final _masterSecretCtrl = TextEditingController();

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  void _handleSignIn() {
    final email = _loginEmailCtrl.text.trim();
    final pin = _loginPinCtrl.text.trim();

    if (email.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter both Admin Email and Master PIN.');
      return;
    }

    if (pin.length < 4) {
      setState(() => _errorMessage = 'Master PIN must be at least 4 digits.');
      return;
    }

    // Authenticated
    widget.onAuthenticated();
  }

  void _handleSignUp() {
    final name = _nameCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pin = _regPinCtrl.text.trim();

    if (name.isEmpty || org.isEmpty || email.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required reseller registration fields.');
      return;
    }

    // Authenticated
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate superadmin theme
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: const Color(0xFF1E293B),
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Badge
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'BharatHisab Control Tower',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Superadmin, Multi-Tenant & Commercial License Portal',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab Selector
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        tabs: const [
                          Tab(text: 'Admin Sign In'),
                          Tab(text: 'Register Reseller'),
                        ],
                        onTap: (_) => setState(() => _errorMessage = null),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Alert if any
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Color(0xFFFCA5A5), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFFCA5A5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tab View
                    AnimatedBuilder(
                      animation: _tabCtrl,
                      builder: (context, _) {
                        return _tabCtrl.index == 0 ? _buildSignInTab() : _buildSignUpTab();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailCtrl,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Master Admin Email', LucideIcons.mail),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPinCtrl,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Master Security PIN', LucideIcons.keyRound).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 16,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(LucideIcons.logIn, size: 16),
          label: Text('Sign In to Control Tower', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
          onPressed: _handleSignIn,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Default Demo Access: admin@bharathisab.com • PIN: 889900',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameCtrl,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Master Reseller Full Name', LucideIcons.user),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _orgCtrl,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Agency / Company Name', LucideIcons.building2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Official Email Address', LucideIcons.mail),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Create 6-Digit Master PIN', LucideIcons.lock),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _masterSecretCtrl,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration('Reseller License Authorization Key', LucideIcons.shieldAlert),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(LucideIcons.badgeCheck, size: 16),
          label: Text('Register & Access Tower', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
          onPressed: _handleSignUp,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
