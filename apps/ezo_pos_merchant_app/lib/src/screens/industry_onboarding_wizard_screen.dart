import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/ezo_theme.dart';
import '../theme/google_fonts.dart';
import '../demo/demo_data_seeder.dart';
import 'main_shell_layout.dart';

class IndustryOnboardingWizardScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final bool isReconfiguration;
  final VoidCallback? onComplete;

  const IndustryOnboardingWizardScreen({
    super.key,
    required this.repository,
    this.isReconfiguration = false,
    this.onComplete,
  });

  @override
  State<IndustryOnboardingWizardScreen> createState() => _IndustryOnboardingWizardScreenState();
}

class _IndustryOnboardingWizardScreenState extends State<IndustryOnboardingWizardScreen> {
  int _currentStep = 0;
  bool _isSeeding = false;

  // Step 1: Selected Vertical
  IndustryVertical _selectedVertical = IndustryVertical.kiranaGrocery;

  // Step 2: Store & Tax Profile
  late TextEditingController _storeNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _gstinCtrl;
  bool _isGstRegistered = true;
  String _selectedStateCode = '27';
  String _selectedStateName = 'Maharashtra';
  RegionalLanguage _selectedLanguage = RegionalLanguage.en;

  // Step 3: Hardware & Printing
  PrintFormat _selectedPrintFormat = PrintFormat.chota58mm;
  bool _enableAutoKot = false;
  bool _printUpiQrOnBill = true;

  final List<Map<String, String>> _indianStates = const [
    {'code': '27', 'name': 'Maharashtra'},
    {'code': '07', 'name': 'Delhi'},
    {'code': '29', 'name': 'Karnataka'},
    {'code': '24', 'name': 'Gujarat'},
    {'code': '33', 'name': 'Tamil Nadu'},
    {'code': '19', 'name': 'West Bengal'},
    {'code': '09', 'name': 'Uttar Pradesh'},
    {'code': '06', 'name': 'Haryana'},
    {'code': '36', 'name': 'Telangana'},
    {'code': '32', 'name': 'Kerala'},
    {'code': '03', 'name': 'Punjab'},
    {'code': '08', 'name': 'Rajasthan'},
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.repository.getAllProfiles().isNotEmpty
        ? widget.repository.getAllProfiles().first
        : null;

    _storeNameCtrl = TextEditingController(text: existing?.storeName ?? 'Bharat Mega Mart & Cafe');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '9876543210');
    _gstinCtrl = TextEditingController(text: existing?.gstin ?? '27AABCE1234F1Z5');
    _isGstRegistered = existing?.isGstEnabled ?? true;
    _selectedStateCode = existing?.stateCode ?? '27';
    _selectedStateName = existing?.stateName ?? 'Maharashtra';
    _selectedPrintFormat = existing?.defaultPrintFormat ?? PrintFormat.chota58mm;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  void _onVerticalChanged(IndustryVertical vertical) {
    setState(() {
      _selectedVertical = vertical;
      final info = IndustryVerticalInfo.getAllVerticals().firstWhere((v) => v.vertical == vertical);
      _selectedPrintFormat = info.recommendedPrintFormat;
      _enableAutoKot = vertical == IndustryVertical.restaurantCafe;

      // Update default placeholder store name if user hasn't heavily modified it
      if (_storeNameCtrl.text.isEmpty ||
          _storeNameCtrl.text == 'Bharat Mega Mart & Cafe' ||
          _storeNameCtrl.text.startsWith('The Spice') ||
          _storeNameCtrl.text.startsWith('Sanjivani') ||
          _storeNameCtrl.text.startsWith('FabStyle') ||
          _storeNameCtrl.text.startsWith('TechZone')) {
        switch (vertical) {
          case IndustryVertical.restaurantCafe:
            _storeNameCtrl.text = 'The Spice Bistro & Cafe';
            break;
          case IndustryVertical.pharmacyHealth:
            _storeNameCtrl.text = 'Sanjivani Medicos & Wellness';
            break;
          case IndustryVertical.garmentsApparel:
            _storeNameCtrl.text = 'FabStyle Boutique & Garments';
            break;
          case IndustryVertical.electronicsMobiles:
            _storeNameCtrl.text = 'TechZone Mobiles & Electronics';
            break;
          case IndustryVertical.kiranaGrocery:
            _storeNameCtrl.text = 'Bharat Super Kirana & Mart';
            break;
        }
      }
    });
  }

  Future<void> _completeWizardAndLaunch() async {
    setState(() => _isSeeding = true);

    await DemoDataSeeder.seedVerticalStore(
      repo: widget.repository,
      vertical: _selectedVertical,
      storeName: _storeNameCtrl.text.trim(),
      gstin: _isGstRegistered ? _gstinCtrl.text.trim() : '',
      phone: _phoneCtrl.text.trim(),
      stateCode: _selectedStateCode,
      stateName: _selectedStateName,
      printFormat: _selectedPrintFormat,
      language: _selectedLanguage,
    );

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      final freshProfile = widget.repository.getAllProfiles().first;
      final freshStaff = widget.repository.getAllStaff().first;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShellLayout(
            repository: widget.repository,
            initialProfile: freshProfile,
            initialStaff: freshStaff,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EzoColors.background,
      appBar: AppBar(
        backgroundColor: EzoColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: EzoColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.store, color: EzoColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isReconfiguration ? 'Switch Business Module' : 'Store Setup Wizard',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: EzoColors.textPrimary,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 4 • ${_getStepTitle(_currentStep)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: EzoColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.isReconfiguration)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20, color: EzoColors.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: EzoColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(EzoColors.primary),
              minHeight: 3,
            ),

            // Step Content
            Expanded(
              child: _isSeeding
                  ? _buildSeedingLoadingState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: _buildCurrentStepContent(),
                    ),
            ),

            // Bottom Navigation Footer
            if (!_isSeeding) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Industry Vertical';
      case 1:
        return 'Store Profile & Tax Setup';
      case 2:
        return 'Hardware & Receipt Format';
      case 3:
        return 'Review & Instant Launch';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1IndustrySelection();
      case 1:
        return _buildStep2StoreTaxProfile();
      case 2:
        return _buildStep3HardwarePrinting();
      case 3:
        return _buildStep4ReviewConfirm();
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------
  // STEP 1: INDUSTRY VERTICAL SELECTION
  // -------------------------------------------------------------
  Widget _buildStep1IndustrySelection() {
    final verticals = IndustryVerticalInfo.getAllVerticals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of business do you run?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EzoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your industry module to pre-configure categories, sample catalog, tax rates, and receipt formats automatically.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: EzoColors.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),

        // Vertical Cards List
        ...verticals.map((info) {
          final isSelected = info.vertical == _selectedVertical;

          IconData verticalIcon;
          Color accentColor;
          switch (info.vertical) {
            case IndustryVertical.restaurantCafe:
              verticalIcon = LucideIcons.utensilsCrossed;
              accentColor = const Color(0xFFEA580C);
              break;
            case IndustryVertical.pharmacyHealth:
              verticalIcon = LucideIcons.pill;
              accentColor = const Color(0xFF059669);
              break;
            case IndustryVertical.garmentsApparel:
              verticalIcon = LucideIcons.shirt;
              accentColor = const Color(0xFF7C3AED);
              break;
            case IndustryVertical.electronicsMobiles:
              verticalIcon = LucideIcons.smartphone;
              accentColor = const Color(0xFF0284C7);
              break;
            case IndustryVertical.kiranaGrocery:
              verticalIcon = LucideIcons.shoppingBasket;
              accentColor = EzoColors.primary;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _onVerticalChanged(info.vertical),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withValues(alpha: 0.04) : EzoColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : EzoColors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Tile
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(verticalIcon, color: accentColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  info.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: EzoColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  info.categoryBadge,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.vernacularTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: EzoColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            info.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: EzoColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Bullet pills
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: info.keyFeatures.map((feat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: EzoColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: EzoColors.border, width: 0.8),
                                ),
                                child: Text(
                                  '• $feat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: EzoColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Radio Check
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? accentColor : EzoColors.border,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: STORE & TAX PROFILE
  // -------------------------------------------------------------
  Widget _buildStep2StoreTaxProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Details & Tax Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EzoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your store identity, operating state, and statutory tax parameters.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Store Name Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Identity',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _storeNameCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Store / Restaurant Trade Name',
                  prefixIcon: const Icon(LucideIcons.store, size: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Primary Business Phone / WhatsApp',
                  prefixIcon: const Icon(LucideIcons.phone, size: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // State Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStateCode,
                decoration: InputDecoration(
                  labelText: 'Operating State (For CGST/SGST vs IGST Split)',
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _indianStates.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['code']!,
                    child: Text('${s['name']} (State Code: ${s['code']})', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (code) {
                  if (code != null) {
                    final found = _indianStates.firstWhere((s) => s['code'] == code);
                    setState(() {
                      _selectedStateCode = code;
                      _selectedStateName = found['name']!;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // GST Registration Mode
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GST & Taxation Mode',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              const SizedBox(height: 10),

              // Mode 1: Regular GST Tax Invoice
              Material(
                type: MaterialType.transparency,
                child: RadioListTile<bool>(
                  value: true,
                  // ignore: deprecated_member_use
                  groupValue: _isGstRegistered,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: EzoColors.primary,
                  title: Text('GST Registered (Regular Tax Invoices)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('Full GSTR-1, GSTR-3B compliance, CGST+SGST/IGST tax extraction', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => _isGstRegistered = val ?? true),
                ),
              ),

              if (_isGstRegistered) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _gstinCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                  decoration: InputDecoration(
                    labelText: '15-Digit GSTIN Number',
                    hintText: 'e.g. 27AABCE1234F1Z5',
                    prefixIcon: const Icon(LucideIcons.fileText, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],

              const Divider(height: 20),

              // Mode 2: Composition / Non-GST
              Material(
                type: MaterialType.transparency,
                child: RadioListTile<bool>(
                  value: false,
                  // ignore: deprecated_member_use
                  groupValue: _isGstRegistered,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: EzoColors.primary,
                  title: Text('Non-GST / Composition Store (Bill of Supply)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('Issues Bills of Supply without charging statutory taxes', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                  // ignore: deprecated_member_use
                  onChanged: (val) => setState(() => _isGstRegistered = val ?? false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Default Regional Language
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vernacular Receipt & Billing Language',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RegionalLanguage>(
                initialValue: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Default Language',
                  prefixIcon: const Icon(LucideIcons.languages, size: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: RegionalLanguage.en, child: Text('English (Default)')),
                  DropdownMenuItem(value: RegionalLanguage.hi, child: Text('हिंदी (Hindi)')),
                  DropdownMenuItem(value: RegionalLanguage.mr, child: Text('मराठी (Marathi)')),
                  DropdownMenuItem(value: RegionalLanguage.gu, child: Text('ગુજરાતી (Gujarati)')),
                  DropdownMenuItem(value: RegionalLanguage.bn, child: Text('বাংলা (Bengali)')),
                  DropdownMenuItem(value: RegionalLanguage.te, child: Text('తెలుగు (Telugu)')),
                  DropdownMenuItem(value: RegionalLanguage.ta, child: Text('தமிழ் (Tamil)')),
                  DropdownMenuItem(value: RegionalLanguage.kn, child: Text('ಕನ್ನಡ (Kannada)')),
                  DropdownMenuItem(value: RegionalLanguage.pa, child: Text('ਪੰਜਾਬੀ (Punjabi)')),
                ],
                onChanged: (lang) {
                  if (lang != null) setState(() => _selectedLanguage = lang);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 3: HARDWARE & PRINTING
  // -------------------------------------------------------------
  Widget _buildStep3HardwarePrinting() {
    final formatOptions = [
      {
        'format': PrintFormat.chota58mm,
        'title': 'Chota Billing Machine (58mm Thermal)',
        'subtitle': '2-inch roll, 32 characters/line. Pocket Bluetooth & handheld POS.',
        'badge': 'Fast FMCG',
        'icon': LucideIcons.printer,
      },
      {
        'format': PrintFormat.bada80mm,
        'title': 'Bada Billing Machine (80mm Thermal)',
        'subtitle': '3-inch roll, 48 characters/line. Counter desktop Bluetooth & USB printer.',
        'badge': 'Recommended for Restaurants',
        'icon': LucideIcons.printerCheck,
      },
      {
        'format': PrintFormat.a4Modern,
        'title': 'A4 Full-Page GST Tax Invoice',
        'subtitle': 'Standard laser/inkjet printer with statutory B2B table and terms.',
        'badge': 'Corporate & Electronics',
        'icon': LucideIcons.fileText,
      },
      {
        'format': PrintFormat.a5,
        'title': 'A5 Half-Page Landscape Invoice',
        'subtitle': 'Compact wholesale & distribution slip for pharmacy and logistics.',
        'badge': 'Pharma Wholesale',
        'icon': LucideIcons.receipt,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hardware & Printing Preferences',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EzoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your primary receipt format and automated ticket dispatch rules.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
        ),
        const SizedBox(height: 16),

        ...formatOptions.map((opt) {
          final fmt = opt['format'] as PrintFormat;
          final isSelected = fmt == _selectedPrintFormat;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedPrintFormat = fmt),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? EzoColors.primaryLight.withValues(alpha: 0.3) : EzoColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? EzoColors.primary : EzoColors.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(opt['icon'] as IconData, color: isSelected ? EzoColors.primary : EzoColors.textSecondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: EzoColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: EzoColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(opt['badge'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w600, color: EzoColors.textSecondary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(opt['subtitle'] as String, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ignore: deprecated_member_use
                    Radio<PrintFormat>(
                      value: fmt,
                      // ignore: deprecated_member_use
                      groupValue: _selectedPrintFormat,
                      activeColor: EzoColors.primary,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPrintFormat = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 14),

        // Specialized Module Toggles
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _enableAutoKot,
                  activeThumbColor: EzoColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Kitchen Order Ticket (KOT) Dispatch', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text('Instantly print table-wise KOT slips to the kitchen on bill placement', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                  onChanged: (val) => setState(() => _enableAutoKot = val),
                ),
              ),
              const Divider(height: 12),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _printUpiQrOnBill,
                  activeThumbColor: EzoColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Dynamic NPCI UPI QR on Receipt', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text('Print UPI QR code embedded with exact bill amount for instant customer scanning', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                  onChanged: (val) => setState(() => _printUpiQrOnBill = val),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 4: REVIEW & CONFIRMATION
  // -------------------------------------------------------------
  Widget _buildStep4ReviewConfirm() {
    final info = IndustryVerticalInfo.getAllVerticals().firstWhere((v) => v.vertical == _selectedVertical);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to Launch Your Store!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EzoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review your store configuration. Tapping launch will initialize your catalog and sample data.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Hero Review Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.sparkles, color: Color(0xFFFBBF24), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storeNameCtrl.text.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${info.title} • ${info.categoryBadge}',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),

              _buildReviewRow('Selected Vertical', info.title),
              _buildReviewRow('Taxation Mode', _isGstRegistered ? 'GST Tax Invoice (${_gstinCtrl.text})' : 'Non-GST Bill of Supply'),
              _buildReviewRow('State Code', '$_selectedStateName (Code: $_selectedStateCode)'),
              _buildReviewRow('Receipt Machine', _selectedPrintFormat.name.toUpperCase()),
              _buildReviewRow('Sample SKUs to Seed', '${info.sampleCatalog.length} Pre-configured Items'),
              _buildReviewRow('KOT Printing', _enableAutoKot ? 'Enabled (Auto Dispatch)' : 'Disabled'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sample Catalog Preview Pill Strip
        Text(
          'Sample Pre-configured Catalog Items:',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Column(
            children: info.sampleCatalog.map((prod) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          prod.name[0],
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11, color: EzoColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prod.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: EzoColors.textPrimary),
                      ),
                    ),
                    Text(
                      '₹${prod.sellingPrice.toInt()}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: EzoColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8))),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSeedingLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: EzoColors.primary),
          const SizedBox(height: 16),
          Text(
            'Initializing Store Database...',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Seeding vertical catalog, tax structures, and sample parties',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // -------------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: EzoColors.surface,
        border: Border(top: BorderSide(color: EzoColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: EzoColors.border),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: EzoColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _completeWizardAndLaunch();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EzoColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 3 ? '🚀 Launch Store & Seed Catalog' : 'Continue Next →',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
