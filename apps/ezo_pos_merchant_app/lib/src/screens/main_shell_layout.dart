import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/google_fonts.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_l10n_vernacular/ezo_l10n_vernacular.dart';
import '../controllers/pos_billing_controller.dart';
import '../theme/ezo_theme.dart';
import 'pos_billing_screen.dart';
import 'inventory_screen.dart';
import 'khata_screen.dart';
import 'online_dukan_dhanda_screen.dart';
import 'reports_hub_screen.dart';
import 'settings_license_screen.dart';

class MainShellLayout extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile initialProfile;
  final StaffMember initialStaff;
  final VoidCallback? onLogout;
  final Future<void> Function()? onResetAll;

  const MainShellLayout({
    super.key,
    required this.repository,
    required this.initialProfile,
    required this.initialStaff,
    this.onLogout,
    this.onResetAll,
  });

  @override
  State<MainShellLayout> createState() => _MainShellLayoutState();
}

class _MainShellLayoutState extends State<MainShellLayout> {
  int _selectedNavIndex = 0;
  late BusinessProfile _activeProfile;
  late PosBillingController _posController;
  final LocaleController _localeController = LocaleController();

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.initialProfile;
    _posController = PosBillingController(
      repository: widget.repository,
      initialProfile: _activeProfile,
      initialStaff: widget.initialStaff,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RegionalLanguage>(
      stream: _localeController.onLanguageChanged,
      initialData: _localeController.currentLanguage,
      builder: (context, _) {
        final isWideScreen = MediaQuery.of(context).size.width >= 800;
        final pendingSyncCount = widget.repository.getPendingSync().length;

        final screens = [
          PosBillingScreen(controller: _posController),
          InventoryScreen(repository: widget.repository, storeProfile: _activeProfile),
          KhataScreen(
            repository: widget.repository,
            storeProfile: _activeProfile,
            cashier: widget.initialStaff,
          ),
          OnlineDukanDhandaScreen(repository: widget.repository, storeProfile: _activeProfile),
          ReportsHubScreen(
            repository: widget.repository,
            storeProfile: _activeProfile,
            cashier: widget.initialStaff,
          ),
          SettingsLicenseScreen(
            repository: widget.repository,
            storeProfile: _activeProfile,
            onProfileUpdated: (updated) {
              setState(() => _activeProfile = updated);
            },
            onLogout: widget.onLogout,
            onResetAll: widget.onResetAll,
          ),
        ];

        return Scaffold(
          backgroundColor: EzoColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: const BoxDecoration(
                color: EzoColors.surface,
                border: Border(
                  bottom: BorderSide(color: EzoColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // Store Brand Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: EzoColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: EzoColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.store,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Store Title & Status
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeProfile.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: EzoColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: EzoColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _activeProfile.isGstRegistered ? 'GST Registered' : 'Non-GST Store',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: EzoColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Language Switcher Pill
                      InkWell(
                        onTap: () => _showLanguageSwitcherModal(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: EzoColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EzoColors.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.languages, size: 14, color: EzoColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _localeController.currentLanguage.name.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sync Status Icon
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Offline Outbox: $pendingSyncCount items queued for cloud backup.')),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: EzoColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EzoColors.border, width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(LucideIcons.cloud, size: 16, color: EzoColors.textSecondary),
                              if (pendingSyncCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: EzoColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Cashier Pill & Lock Menu
                      InkWell(
                        onTap: () => _showCashierMenu(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: EzoColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EzoColors.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.userCheck, size: 13, color: EzoColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                widget.initialStaff.fullName.split(' ').first,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.lock, size: 11, color: EzoColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Settings Gear
                      InkWell(
                        onTap: () => setState(() => _selectedNavIndex = 5),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: EzoColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EzoColors.border, width: 1),
                          ),
                          child: const Icon(LucideIcons.settings, size: 16, color: EzoColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: isWideScreen
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedNavIndex,
                      onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(icon: const Icon(LucideIcons.receipt), label: Text(_localeController.tr('posBilling'))),
                        NavigationRailDestination(icon: const Icon(LucideIcons.boxes), label: Text(_localeController.tr('inventory'))),
                        NavigationRailDestination(icon: const Icon(LucideIcons.bookUser), label: Text(_localeController.tr('khataUdhaar'))),
                        NavigationRailDestination(icon: const Icon(LucideIcons.store), label: Text(_localeController.tr('onlineDukan'))),
                        NavigationRailDestination(icon: const Icon(LucideIcons.barChart3), label: Text(_localeController.tr('reports'))),
                        NavigationRailDestination(icon: const Icon(LucideIcons.settings), label: Text(_localeController.tr('settings'))),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: screens[_selectedNavIndex]),
                  ],
                )
              : screens[_selectedNavIndex],
          bottomNavigationBar: isWideScreen
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    color: EzoColors.surface,
                    border: Border(
                      top: BorderSide(color: EzoColors.border, width: 1),
                    ),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedNavIndex > 4 ? 4 : _selectedNavIndex,
                    onTap: (idx) => setState(() => _selectedNavIndex = idx),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: EzoColors.surface,
                    selectedItemColor: EzoColors.primary,
                    unselectedItemColor: EzoColors.textMuted,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                    elevation: 0,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.shoppingBag, size: 20),
                        activeIcon: Icon(LucideIcons.shoppingBag, size: 20),
                        label: 'Billing',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.boxes, size: 20),
                        activeIcon: Icon(LucideIcons.boxes, size: 20),
                        label: 'Inventory',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.bookUser, size: 20),
                        activeIcon: Icon(LucideIcons.bookUser, size: 20),
                        label: 'Khata',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.sparkles, size: 20),
                        activeIcon: Icon(LucideIcons.sparkles, size: 20),
                        label: 'Dhanda AI',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(LucideIcons.barChart3, size: 20),
                        activeIcon: Icon(LucideIcons.barChart3, size: 20),
                        label: 'Reports',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showLanguageSwitcherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EzoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Regional Language / भाषा चुनें',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'App updates instantly across all billing and receipt screens',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: RegionalLanguage.values.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final lang = RegionalLanguage.values[idx];
                    final isSelected = _localeController.currentLanguage == lang;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      title: Text(
                        _localeController.getLanguageDisplayName(lang),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? EzoColors.primary : EzoColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lang.name.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                      ),
                      trailing: isSelected ? const Icon(LucideIcons.check, color: EzoColors.primary, size: 18) : null,
                      onTap: () {
                        _localeController.setLanguage(lang);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCashierMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EzoColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.user, color: EzoColors.primary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialStaff.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: EzoColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Role: ${widget.initialStaff.role.name.toUpperCase()} • ${_activeProfile.storeName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: EzoColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(LucideIcons.lock, color: EzoColors.primary),
                  title: Text(
                    'Lock Register & Switch Cashier',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Secures your billing counter and requires PIN to unlock',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onLogout?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.refreshCw, color: EzoColors.error),
                  title: Text(
                    'Reset App & Wipe All Data',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: EzoColors.error),
                  ),
                  subtitle: Text(
                    'Clears local database to test fresh signup and onboarding',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmResetStore(context);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmResetStore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: EzoColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Reset Store Data?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'This will permanently delete the current business profile, products, customers, and invoice ledger from this device so you can start completely fresh or sign up a new store.\n\nAre you sure you want to proceed?',
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
            child: const Text('Yes, Wipe & Reset'),
          ),
        ],
      ),
    );
  }
}
