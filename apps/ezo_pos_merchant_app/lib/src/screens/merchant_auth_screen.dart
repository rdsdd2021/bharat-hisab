import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/google_fonts.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import '../demo/demo_data_seeder.dart';
import '../theme/ezo_theme.dart';

class MerchantAuthScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final void Function(BusinessProfile profile, StaffMember staff) onAuthenticated;
  final int initialTab;

  const MerchantAuthScreen({
    super.key,
    required this.repository,
    required this.onAuthenticated,
    this.initialTab = 0,
  });

  @override
  State<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _MerchantAuthScreenState extends State<MerchantAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Sign Up Controllers
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  IndustryVertical _selectedVertical = IndustryVertical.kiranaGrocery;
  String _selectedState = '27 - Maharashtra';
  bool _startEmptyStore = true; // Default to clean empty real store!
  bool _isGstEnabled = true;

  // Sign In Controllers
  final _loginPhoneCtrl = TextEditingController();
  final _loginPinCtrl = TextEditingController();
  String _errorMessage = '';

  final List<String> _indianStates = const [
    '01 - Jammu & Kashmir',
    '02 - Himachal Pradesh',
    '03 - Punjab',
    '06 - Haryana',
    '07 - Delhi',
    '08 - Rajasthan',
    '09 - Uttar Pradesh',
    '10 - Bihar',
    '19 - West Bengal',
    '23 - Madhya Pradesh',
    '24 - Gujarat',
    '27 - Maharashtra',
    '29 - Karnataka',
    '32 - Kerala',
    '33 - Tamil Nadu',
    '36 - Telangana',
    '37 - Andhra Pradesh',
  ];

  @override
  void initState() {
    super.initState();
    final hasExistingStores = widget.repository.getAllProfiles().isNotEmpty;
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 1 || hasExistingStores ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _storeNameCtrl.dispose();
    _pinCtrl.dispose();
    _loginPhoneCtrl.dispose();
    _loginPinCtrl.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final ownerName = _ownerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final storeName = _storeNameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (ownerName.isEmpty || phone.isEmpty || storeName.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all registration fields.');
      return;
    }

    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    if (pin.length < 4) {
      setState(() => _errorMessage = 'Please set a 4-digit security PIN for cashier unlock.');
      return;
    }

    setState(() => _errorMessage = '');

    final stateParts = _selectedState.split(' - ');
    final stateCode = stateParts[0];
    final stateName = stateParts.length > 1 ? stateParts[1] : 'Maharashtra';

    final profileId = 'store_${DateTime.now().millisecondsSinceEpoch}';
    final staffId = 'staff_${DateTime.now().millisecondsSinceEpoch}';

    final profile = BusinessProfile(
      id: profileId,
      storeName: storeName,
      legalEntityName: '$storeName Retail Ltd',
      gstin: _isGstEnabled ? '${stateCode}ABCDE1234F1Z5' : '',
      stateCode: stateCode,
      stateName: stateName,
      address: 'Main Commercial Market, $stateName',
      phone: phone,
      email: 'owner@${storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com',
      upiId: '$phone@upi',
      bankName: 'State Bank of India',
      accountNumber: '309812739182',
      ifscCode: 'SBIN0001234',
      defaultPrintFormat: _selectedVertical == IndustryVertical.restaurantCafe
          ? PrintFormat.bada80mm
          : PrintFormat.chota58mm,
      branding: WhiteLabelBranding(
        brandAppName: 'BharatHisab',
        resellerCompanyName: 'Bharat Commercial Tech Ltd',
        supportWhatsApp: phone,
        primaryColorHex: '#4338CA',
        accentColorHex: '#4F46E5',
        receiptFooterTagline: 'Thank you for shopping with us! Visit again.',
      ),
    );

    final staff = StaffMember(
      id: staffId,
      storeProfileId: profileId,
      fullName: ownerName,
      phone: phone,
      pinCode: pin,
      role: StaffRole.ownerAdmin,
      canEditPrices: true,
      canDeleteBills: true,
      canViewProfitReports: true,
      canCollectUdhaar: true,
      createdAt: DateTime.now(),
    );

    final license = MerchantLicenseKey(
      key: 'BHARAT-STD-${DateTime.now().millisecondsSinceEpoch}',
      merchantId: profileId,
      storeName: storeName,
      tier: SubscriptionTier.oneYearStandard,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      maxAllowedStores: 3,
      maxStaffSeats: 5,
      isDhandaAiEnabled: true,
      isOnlineDukanEnabled: true,
    );

    // Save profile, owner staff, and license
    await widget.repository.saveProfile(profile);
    await widget.repository.saveStaff(staff);
    await widget.repository.activateLicense(license);

    // If merchant explicitly requested sample items, seed them; otherwise start 100% clean!
    if (!_startEmptyStore) {
      await DemoDataSeeder.seedVerticalStore(
        repo: widget.repository,
        vertical: _selectedVertical,
        storeName: storeName,
        phone: phone,
      );
    }

    widget.onAuthenticated(profile, staff);
  }

  void _handleSignIn() {
    final phone = _loginPhoneCtrl.text.trim();
    final pin = _loginPinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter both phone number and 4-digit PIN.');
      return;
    }

    final allStaff = widget.repository.getAllStaff();
    final staff = allStaff.where((s) => s.phone == phone && s.pinCode == pin).firstOrNull;

    if (staff == null) {
      setState(() => _errorMessage = 'Invalid phone number or PIN. Check your credentials or create a new account.');
      return;
    }

    final profile = widget.repository.getProfile(staff.storeProfileId) ??
        widget.repository.getAllProfiles().firstOrNull;

    if (profile == null) {
      setState(() => _errorMessage = 'No store profile found. Please create a business account.');
      return;
    }

    widget.onAuthenticated(profile, staff);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand Banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.store, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'BharatHisab (भारतहिसाब)',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete Indian POS Billing, GST Accounting & Khata',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFC7D2FE),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sub-Tabs Header
                TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFF4338CA),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF4338CA),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Create Business Account'),
                    Tab(text: 'Sign In with PIN'),
                  ],
                ),

                // Error Banner
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tab Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (context, _) {
                      return _tabCtrl.index == 0 ? _buildSignUpForm() : _buildSignInForm();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _storeNameCtrl,
          label: 'Business / Shop Name *',
          hint: 'e.g., Apna Super Bazaar or Royal Cafe',
          icon: LucideIcons.store,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _ownerNameCtrl,
                label: 'Owner / Manager Name *',
                hint: 'e.g., Ramesh Sharma',
                icon: LucideIcons.user,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                controller: _phoneCtrl,
                label: 'Mobile Number *',
                hint: '10-digit phone',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _pinCtrl,
                label: '4-Digit Security PIN *',
                hint: 'For cashier lock',
                icon: LucideIcons.lock,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State (for GST) *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedState,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 14),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        items: _indianStates.map((st) {
                          return DropdownMenuItem(value: st, child: Text(st));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedState = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Industry Vertical Selector
        Text(
          'Industry Vertical / Store Type *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<IndustryVertical>(
              value: _selectedVertical,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 14),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(
                  value: IndustryVertical.kiranaGrocery,
                  child: Text('🛒 Kirana, Supermarket & Grocery (Weighing Scale + FMCG)'),
                ),
                DropdownMenuItem(
                  value: IndustryVertical.restaurantCafe,
                  child: Text('🍽️ Restaurant, Cafe & QSR (Table Orders & Kitchen KOT)'),
                ),
                DropdownMenuItem(
                  value: IndustryVertical.pharmacyHealth,
                  child: Text('💊 Pharmacy & Healthcare (Batch Numbers & Expiry Dates)'),
                ),
                DropdownMenuItem(
                  value: IndustryVertical.garmentsApparel,
                  child: Text('👕 Garments & Apparel (Size/Color Matrix + Barcode Tags)'),
                ),
                DropdownMenuItem(
                  value: IndustryVertical.electronicsMobiles,
                  child: Text('📱 Electronics & Mobiles (Serial/IMEI & Warranty Tracking)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedVertical = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Clean Slate vs Pre-loaded Sample Items Option
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _startEmptyStore,
                activeColor: const Color(0xFF4338CA),
                onChanged: (val) {
                  setState(() => _startEmptyStore = val ?? true);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start with Clean Empty Catalog (0 dummy items)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Uncheck only if you want sample demo items pre-populated for testing.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submit Button
        ElevatedButton(
          onPressed: _handleSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4338CA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: Text(
            'Create Business Account & Launch Store 🚀',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _loginPhoneCtrl,
          label: 'Registered Mobile Number',
          hint: 'Enter your 10-digit mobile number',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _loginPinCtrl,
          label: '4-Digit Security PIN',
          hint: '••••',
          icon: LucideIcons.lock,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4338CA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: Text(
            'Sign In & Open Counter 🔓',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              _tabCtrl.animateTo(0);
            },
            child: Text(
              "Don't have an account? Register a new store",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4338CA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLength: maxLength,
            inputFormatters: keyboardType == TextInputType.number || keyboardType == TextInputType.phone
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
              prefixIcon: Icon(icon, size: 16, color: const Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
