import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import '../theme/ezo_theme.dart';
import 'industry_onboarding_wizard_screen.dart';

class SettingsLicenseScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final Function(BusinessProfile) onProfileUpdated;
  final VoidCallback? onLogout;
  final Future<void> Function()? onResetAll;

  const SettingsLicenseScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
    required this.onProfileUpdated,
    this.onLogout,
    this.onResetAll,
  });

  @override
  State<SettingsLicenseScreen> createState() => _SettingsLicenseScreenState();
}

class _SettingsLicenseScreenState extends State<SettingsLicenseScreen> {
  late TextEditingController _storeNameCtrl;
  late TextEditingController _legalNameCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _upiCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _taglineCtrl;
  final TextEditingController _licenseKeyCtrl = TextEditingController();

  List<DiscoveredPrinterDevice> _scannedPrinters = [];
  bool _isScanning = false;
  PrintFormat _selectedRollWidth = PrintFormat.chota58mm;

  @override
  void initState() {
    super.initState();
    final p = widget.storeProfile;
    _storeNameCtrl = TextEditingController(text: p.storeName);
    _legalNameCtrl = TextEditingController(text: p.legalEntityName);
    _gstinCtrl = TextEditingController(text: p.gstin);
    _phoneCtrl = TextEditingController(text: p.phone);
    _upiCtrl = TextEditingController(text: p.upiId);
    _addressCtrl = TextEditingController(text: p.address);
    _taglineCtrl = TextEditingController(text: p.branding.receiptFooterTagline);
    _selectedRollWidth = p.defaultPrintFormat;
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _legalNameCtrl.dispose();
    _gstinCtrl.dispose();
    _phoneCtrl.dispose();
    _upiCtrl.dispose();
    _addressCtrl.dispose();
    _taglineCtrl.dispose();
    _licenseKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final license = widget.repository.getActiveLicense();
    final staffList = widget.repository.getAllStaff();

    return Scaffold(
      backgroundColor: EzoColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commercial License Activation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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
                      const Icon(LucideIcons.shieldCheck, color: Color(0xFFFBBF24), size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'License: ${license?.tier.name.toUpperCase() ?? 'FREE TRIAL'}',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            license != null && license.isValid
                                ? 'Active • ${license.daysRemaining} days remaining'
                                : 'License Expired or Inactive',
                            style: GoogleFonts.plusJakartaSans(
                              color: license != null && license.isValid ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _licenseKeyCtrl,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Enter Commercial License Activation Key...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBBF24),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _handleActivateLicense,
                        child: Text('Activate', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Store Profile & White-Label Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Store Profile & White-Label Branding',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.sparkles, size: 13, color: EzoColors.primary),
                  label: const Text('Change Industry Module'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EzoColors.primary,
                    side: const BorderSide(color: EzoColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IndustryOnboardingWizardScreen(
                          repository: widget.repository,
                          isReconfiguration: true,
                          onComplete: () {
                            Navigator.pop(context);
                            final updated = widget.repository.getAllProfiles().first;
                            widget.onProfileUpdated(updated);
                            setState(() {
                              final p = updated;
                              _storeNameCtrl.text = p.storeName;
                              _legalNameCtrl.text = p.legalEntityName;
                              _gstinCtrl.text = p.gstin;
                              _phoneCtrl.text = p.phone;
                              _upiCtrl.text = p.upiId;
                              _addressCtrl.text = p.address;
                              _taglineCtrl.text = p.branding.receiptFooterTagline;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EzoColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EzoColors.border, width: 1),
              ),
              child: Column(
                children: [
                  TextField(controller: _storeNameCtrl, decoration: const InputDecoration(labelText: 'Display Store Name *')),
                  const SizedBox(height: 8),
                  TextField(controller: _legalNameCtrl, decoration: const InputDecoration(labelText: 'Legal Entity Name')),
                  const SizedBox(height: 8),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Business Phone / WhatsApp *')),
                  const SizedBox(height: 8),
                  TextField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (15 Digits)')),
                  const SizedBox(height: 8),
                  TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Store Address / Street / City / Pincode')),
                  const SizedBox(height: 8),
                  TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI VPA ID (For Instant Customer Payments)')),
                  const SizedBox(height: 8),
                  TextField(controller: _taglineCtrl, decoration: const InputDecoration(labelText: 'Receipt Footer Tagline')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.save, size: 14),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _handleSaveProfile,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Thermal Printer Hardware Manager
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Thermal Printer Hardware',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.printer, size: 13),
                      label: const Text('Test Print Slip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _handleTestPrintSlip,
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      icon: _isScanning
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.refreshCw, size: 13),
                      label: const Text('Scan Devices'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.surfaceSecondary,
                        foregroundColor: EzoColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: EzoColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isScanning ? null : _handleScanPrinters,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Roll Width & Printer Config Card
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
                    'Thermal Paper Roll Width:',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: EzoColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('58mm (Chota Roll - 32 cols)'),
                        selected: _selectedRollWidth == PrintFormat.chota58mm,
                        selectedColor: EzoColors.primary,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedRollWidth == PrintFormat.chota58mm ? Colors.white : EzoColors.textSecondary,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedRollWidth = PrintFormat.chota58mm);
                            _updateDefaultRollWidth(PrintFormat.chota58mm);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('80mm (Bada Roll - 48 cols)'),
                        selected: _selectedRollWidth == PrintFormat.bada80mm,
                        selectedColor: EzoColors.primary,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _selectedRollWidth == PrintFormat.bada80mm ? Colors.white : EzoColors.textSecondary,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedRollWidth = PrintFormat.bada80mm);
                            _updateDefaultRollWidth(PrintFormat.bada80mm);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Discovered Printers List
                  Text(
                    'Discovered & Paired ESC/POS Devices:',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: EzoColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  _scannedPrinters.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No hardware scanned yet. Tap "Scan Devices" to detect Bluetooth, USB, and Virtual POS drivers.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                          ),
                        )
                      : Column(
                          children: _scannedPrinters.map((p) {
                            final isConnected = ThermalPrinterConnectionManager().activeDevice?.id == p.id;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                p.connectionType == PrinterConnectionType.bluetoothSpp ? LucideIcons.bluetooth : LucideIcons.cable,
                                color: isConnected ? EzoColors.success : EzoColors.primary,
                              ),
                              title: Row(
                                children: [
                                  Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                                  if (isConnected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: EzoColors.successBg, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('CONNECTED', style: TextStyle(color: EzoColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text('Port/Address: ${p.address}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConnected ? EzoColors.error : EzoColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () async {
                                  if (isConnected) {
                                    await ThermalPrinterConnectionManager().disconnectPrinter();
                                    setState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Disconnected ${p.name}')),
                                      );
                                    }
                                  } else {
                                    await ThermalPrinterConnectionManager().connectPrinter(p);
                                    setState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Connected to ${p.name}!'), backgroundColor: EzoColors.success),
                                      );
                                    }
                                  }
                                },
                                child: Text(isConnected ? 'Disconnect' : 'Connect'),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Staff Seats & RBAC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Staff Seats (${staffList.length}/${license?.maxStaffSeats ?? 2})',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                ),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.userPlus, size: 13),
                  label: const Text('Add Staff'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EzoColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _showAddStaffDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: EzoColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EzoColors.border, width: 1),
              ),
              child: Column(
                children: staffList.map((s) {
                  Color roleColor = EzoColors.primary;
                  if (s.role == StaffRole.ownerAdmin) roleColor = const Color(0xFF7C3AED);
                  if (s.role == StaffRole.storeManager) roleColor = const Color(0xFF2563EB);
                  if (s.role == StaffRole.fieldSalesperson) roleColor = const Color(0xFF059669);

                  return InkWell(
                    onTap: () => _showEditStaffDialog(context, s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: roleColor, fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      s.fullName,
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: EzoColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        s.role.name.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: roleColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Phone: ${s.phone} • PIN: ${s.pinCode.isNotEmpty ? '••••' : 'None'}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    if (s.canEditPrices) _buildPermBadge('Edit Price', LucideIcons.tag),
                                    if (s.canGiveDiscounts) _buildPermBadge('Give Discounts', LucideIcons.percent),
                                    if (s.canDeleteBills) _buildPermBadge('Delete Bills', LucideIcons.trash2),
                                    if (s.canViewProfitReports) _buildPermBadge('View Profit', LucideIcons.trendingUp),
                                    if (s.canCollectUdhaar) _buildPermBadge('Collect Udhaar', LucideIcons.wallet),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.pencil, size: 16, color: EzoColors.primary),
                            tooltip: 'Edit Staff Permissions',
                            onPressed: () => _showEditStaffDialog(context, s),
                          ),
                          Switch(
                            value: s.isActive,
                            activeThumbColor: EzoColors.primary,
                            onChanged: (val) async {
                              await widget.repository.saveStaff(s.copyWith(isActive: val));
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Session, Backup & Clean Slate Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EzoColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EzoColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.database, color: EzoColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data Backup & Store Maintenance',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: EzoColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Export local database backup snapshot, lock POS counter for shift handovers, or reset the local register slate.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.download, size: 15),
                          label: const Text('Export Backup (JSON)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: EzoColors.primary),
                            foregroundColor: EzoColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _handleExportBackup,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.lock, size: 15),
                          label: const Text('Lock Counter / Logout'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF4B5563)),
                            foregroundColor: const Color(0xFF4B5563),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => widget.onLogout?.call(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.refreshCw, size: 15),
                      label: const Text('Reset Clean Slate / Wipe Store'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: EzoColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _confirmResetDialog(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _handleSaveProfile() async {
    final updated = widget.storeProfile.copyWith(
      storeName: _storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : widget.storeProfile.storeName,
      legalEntityName: _legalNameCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : widget.storeProfile.phone,
      address: _addressCtrl.text.trim(),
      upiId: _upiCtrl.text.trim(),
      defaultPrintFormat: _selectedRollWidth,
      branding: widget.storeProfile.branding.copyWith(
        receiptFooterTagline: _taglineCtrl.text.trim(),
      ),
    );
    await widget.repository.saveProfile(updated);
    widget.onProfileUpdated(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store Profile updated successfully!'), backgroundColor: EzoColors.success),
      );
    }
  }

  void _updateDefaultRollWidth(PrintFormat format) async {
    final updated = widget.storeProfile.copyWith(defaultPrintFormat: format);
    await widget.repository.saveProfile(updated);
    widget.onProfileUpdated(updated);
  }

  void _handleActivateLicense() async {
    final key = _licenseKeyCtrl.text.trim();
    if (key.isEmpty) return;

    final license = MerchantLicenseKey(
      key: key,
      merchantId: widget.storeProfile.id,
      storeName: widget.storeProfile.storeName,
      tier: SubscriptionTier.lifetimeEnterprise,
      issuedAt: DateTime.now(),
      maxAllowedStores: 10,
      maxStaffSeats: 15,
    );
    await widget.repository.activateLicense(license);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commercial Lifetime Enterprise License activated!'), backgroundColor: EzoColors.success),
      );
    }
  }

  void _handleScanPrinters() async {
    setState(() => _isScanning = true);
    final printers = await ThermalPrinterConnectionManager().scanForPrinters();
    setState(() {
      _scannedPrinters = printers;
      _isScanning = false;
    });
  }

  void _handleTestPrintSlip() async {
    final rollWidth = _selectedRollWidth == PrintFormat.bada80mm
        ? ThermalRollWidth.bada80mm
        : ThermalRollWidth.chota58mm;

    final bytes = EscPosThermalEngine.buildTestSlipByteStream(
      storeProfile: widget.storeProfile,
      rollWidth: rollWidth,
    );

    await ThermalPrinterConnectionManager().printBytes(bytes);

    if (mounted) {
      final active = ThermalPrinterConnectionManager().activeDevice?.name ?? 'Virtual Thermal Driver';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🖨️ Test Print Slip dispatched successfully to $active!'),
          backgroundColor: EzoColors.success,
        ),
      );
    }
  }

  void _handleExportBackup() {
    final products = widget.repository.getAllProducts();
    final parties = widget.repository.getAllParties();
    final invoices = widget.repository.getAllInvoices();
    final staff = widget.repository.getAllStaff();

    final backupPayload = {
      'store': widget.storeProfile.toJson(),
      'exportTimestamp': DateTime.now().toIso8601String(),
      'totalProducts': products.length,
      'products': products.map((p) => p.toJson()).toList(),
      'totalParties': parties.length,
      'parties': parties.map((p) => p.toJson()).toList(),
      'totalInvoices': invoices.length,
      'invoices': invoices.map((i) => i.toJson()).toList(),
      'staff': staff.map((s) => s.toJson()).toList(),
    };

    final jsonStr = jsonEncode(backupPayload);
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Full Store Data Backup (${jsonStr.length} bytes) copied to clipboard!'),
        backgroundColor: EzoColors.success,
      ),
    );
  }

  Widget _buildPermBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: EzoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EzoColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: EzoColors.textMuted),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: EzoColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    StaffRole role = StaffRole.counterCashier;
    bool canEditPrices = false;
    bool canGiveDiscounts = true;
    bool canDeleteBills = false;
    bool canViewProfit = false;
    bool canCollectUdhaar = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Add New Staff Seat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Full Name *')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone *')),
                const SizedBox(height: 8),
                TextField(controller: pinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quick PIN (4 digits) *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<StaffRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Assigned Role'),
                  items: StaffRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                  onChanged: (r) {
                    if (r != null) {
                      setDialogState(() {
                        role = r;
                        if (r == StaffRole.ownerAdmin) {
                          canEditPrices = true;
                          canGiveDiscounts = true;
                          canDeleteBills = true;
                          canViewProfit = true;
                          canCollectUdhaar = true;
                        } else if (r == StaffRole.storeManager) {
                          canEditPrices = true;
                          canGiveDiscounts = true;
                          canDeleteBills = false;
                          canViewProfit = true;
                          canCollectUdhaar = true;
                        } else {
                          canEditPrices = false;
                          canGiveDiscounts = true;
                          canDeleteBills = false;
                          canViewProfit = false;
                          canCollectUdhaar = true;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text('Staff Permission Controls:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textPrimary)),
                const SizedBox(height: 6),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Edit / Override Unit Selling Prices', style: TextStyle(fontSize: 12)),
                  value: canEditPrices,
                  onChanged: (v) => setDialogState(() => canEditPrices = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Give Line-Item & Bill Discounts', style: TextStyle(fontSize: 12)),
                  value: canGiveDiscounts,
                  onChanged: (v) => setDialogState(() => canGiveDiscounts = v ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Delete / Void Completed Invoices', style: TextStyle(fontSize: 12)),
                  value: canDeleteBills,
                  onChanged: (v) => setDialogState(() => canDeleteBills = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can View Profit Margins & Cost Reports', style: TextStyle(fontSize: 12)),
                  value: canViewProfit,
                  onChanged: (v) => setDialogState(() => canViewProfit = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Collect Khata Udhaar & Issue Receipts', style: TextStyle(fontSize: 12)),
                  value: canCollectUdhaar,
                  onChanged: (v) => setDialogState(() => canCollectUdhaar = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EzoColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final pin = pinCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a staff name')));
                  return;
                }

                final staff = StaffMember(
                  id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                  storeProfileId: widget.storeProfile.id,
                  fullName: name,
                  phone: phone,
                  pinCode: pin.isNotEmpty ? pin : '1234',
                  role: role,
                  canEditPrices: canEditPrices,
                  canGiveDiscounts: canGiveDiscounts,
                  canDeleteBills: canDeleteBills,
                  canViewProfitReports: canViewProfit,
                  canCollectUdhaar: canCollectUdhaar,
                  createdAt: DateTime.now(),
                );
                await widget.repository.saveStaff(staff);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added staff seat for $name!'), backgroundColor: EzoColors.success),
                  );
                }
              },
              child: const Text('Add Staff Seat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, StaffMember staff) {
    final nameCtrl = TextEditingController(text: staff.fullName);
    final phoneCtrl = TextEditingController(text: staff.phone);
    final pinCtrl = TextEditingController(text: staff.pinCode);
    StaffRole role = staff.role;
    bool canEditPrices = staff.canEditPrices;
    bool canGiveDiscounts = staff.canGiveDiscounts;
    bool canDeleteBills = staff.canDeleteBills;
    bool canViewProfit = staff.canViewProfitReports;
    bool canCollectUdhaar = staff.canCollectUdhaar;
    bool isActive = staff.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: EzoColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Edit Staff: ${staff.fullName}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Full Name *')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone *')),
                const SizedBox(height: 8),
                TextField(controller: pinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quick PIN (4 digits) *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<StaffRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Assigned Role'),
                  items: StaffRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                  onChanged: (r) {
                    if (r != null) setDialogState(() => role = r);
                  },
                ),
                const SizedBox(height: 14),
                Text('Custom Access & Permission Toggles:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textPrimary)),
                const SizedBox(height: 6),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Edit / Override Unit Selling Prices', style: TextStyle(fontSize: 12)),
                  value: canEditPrices,
                  onChanged: (v) => setDialogState(() => canEditPrices = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Give Line-Item & Bill Discounts', style: TextStyle(fontSize: 12)),
                  value: canGiveDiscounts,
                  onChanged: (v) => setDialogState(() => canGiveDiscounts = v ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Delete / Void Completed Invoices', style: TextStyle(fontSize: 12)),
                  value: canDeleteBills,
                  onChanged: (v) => setDialogState(() => canDeleteBills = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can View Profit Margins & Cost Reports', style: TextStyle(fontSize: 12)),
                  value: canViewProfit,
                  onChanged: (v) => setDialogState(() => canViewProfit = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can Collect Khata Udhaar & Issue Receipts', style: TextStyle(fontSize: 12)),
                  value: canCollectUdhaar,
                  onChanged: (v) => setDialogState(() => canCollectUdhaar = v ?? true),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Active / Shift Allowed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  value: isActive,
                  activeThumbColor: EzoColors.primary,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(LucideIcons.trash2, size: 14, color: EzoColors.error),
                    label: const Text('Remove Staff Member', style: TextStyle(color: EzoColors.error, fontSize: 12)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await widget.repository.deleteStaff(staff.id);
                      setState(() {});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed ${staff.fullName} from staff list.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EzoColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final updated = staff.copyWith(
                  fullName: nameCtrl.text.isNotEmpty ? nameCtrl.text.trim() : staff.fullName,
                  phone: phoneCtrl.text.trim(),
                  pinCode: pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : staff.pinCode,
                  role: role,
                  canEditPrices: canEditPrices,
                  canGiveDiscounts: canGiveDiscounts,
                  canDeleteBills: canDeleteBills,
                  canViewProfitReports: canViewProfit,
                  canCollectUdhaar: canCollectUdhaar,
                  isActive: isActive,
                );
                await widget.repository.saveStaff(updated);
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated permissions for ${updated.fullName}!'), backgroundColor: EzoColors.success),
                  );
                }
              },
              child: const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: EzoColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Wipe & Reset Store Slate?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'This will completely clear your local store profile, all product inventory, and customer ledgers from this device.\n\nYou will be redirected to the BharatHisab setup/signup screen to start clean or configure a new business.\n\nProceed?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EzoColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.onResetAll?.call();
            },
            child: const Text('Yes, Erase & Reset'),
          ),
        ],
      ),
    );
  }
}
