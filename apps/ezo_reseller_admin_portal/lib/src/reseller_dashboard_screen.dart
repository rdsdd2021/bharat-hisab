import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme/ezo_admin_theme.dart';
import 'theme/google_fonts.dart';

class ResellerDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ResellerDashboardScreen({
    super.key,
    this.onLogout,
  });

  @override
  State<ResellerDashboardScreen> createState() => _ResellerDashboardScreenState();
}

enum FleetTimeFilter { today, week, month, allTime }

class _ResellerDashboardScreenState extends State<ResellerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Fleet telemetry filter & search state
  FleetTimeFilter _selectedTimeFilter = FleetTimeFilter.today;
  String _fleetSearchQuery = '';
  String _fleetStatusFilter = 'all'; // 'all', 'online', 'offline'
  bool _isRefreshingFleet = false;

  // Active Multi-Tenant License Store
  final List<MerchantLicenseKey> _issuedLicenses = [
    MerchantLicenseKey(
      key: 'BH-PRO-2026-PUNE-8877',
      merchantId: 'm_pune_01',
      storeName: 'Pune Mega Mart & Cafe',
      tier: SubscriptionTier.threeYearPro,
      issuedAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2029, 1, 1),
      maxAllowedStores: 3,
      maxStaffSeats: 5,
      isDhandaAiEnabled: true,
      isOnlineDukanEnabled: true,
    ),
    MerchantLicenseKey(
      key: 'BH-LIFE-2026-MUMBAI-1122',
      merchantId: 'm_mum_02',
      storeName: 'Bombay Electronics Hub',
      tier: SubscriptionTier.lifetimeEnterprise,
      issuedAt: DateTime(2026, 3, 15),
      maxAllowedStores: 10,
      maxStaffSeats: 15,
      isDhandaAiEnabled: true,
      isOnlineDukanEnabled: true,
    ),
    MerchantLicenseKey(
      key: 'BH-PRO-2026-BLR-5544',
      merchantId: 'm_blr_03',
      storeName: 'The Spice Bistro & Cafe',
      tier: SubscriptionTier.threeYearPro,
      issuedAt: DateTime(2026, 2, 10),
      expiresAt: DateTime(2029, 2, 10),
      maxAllowedStores: 2,
      maxStaffSeats: 8,
      isDhandaAiEnabled: true,
      isOnlineDukanEnabled: true,
    ),
    MerchantLicenseKey(
      key: 'BH-STD-2026-DELHI-4433',
      merchantId: 'm_del_04',
      storeName: 'Sanjivani Medicos & Wellness',
      tier: SubscriptionTier.oneYearStandard,
      issuedAt: DateTime(2026, 2, 1),
      expiresAt: DateTime(2027, 2, 1),
      maxAllowedStores: 1,
      maxStaffSeats: 3,
      isDhandaAiEnabled: false,
      isOnlineDukanEnabled: true,
    ),
    MerchantLicenseKey(
      key: 'BH-STD-2026-HYD-9988',
      merchantId: 'm_hyd_05',
      storeName: 'FabStyle Boutique & Garments',
      tier: SubscriptionTier.oneYearStandard,
      issuedAt: DateTime(2026, 1, 15),
      expiresAt: DateTime(2027, 1, 15),
      maxAllowedStores: 2,
      maxStaffSeats: 4,
      isDhandaAiEnabled: true,
      isOnlineDukanEnabled: false,
    ),
  ];

  // Live Connected Store Fleet Telemetry (Centralized Cloud Analytics)
  final List<Map<String, dynamic>> _fleetStores = [
    {
      'name': 'Pune Mega Mart & Cafe',
      'city': 'Pune, Maharashtra',
      'vertical': 'Kirana & Retail',
      'verticalColor': const Color(0xFF2563EB),
      'todaySales': 42850.0,
      'todayInvoices': 68,
      'lastSync': 'Just now',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Sunil Verma',
      'device': 'Sunmi T2 Mini (Android 11)',
      'ipAddress': '192.168.1.104',
    },
    {
      'name': 'The Spice Bistro & Cafe',
      'city': 'Bengaluru, Karnataka',
      'vertical': 'Restaurant & Cafe',
      'verticalColor': const Color(0xFFEA580C),
      'todaySales': 68400.0,
      'todayInvoices': 94,
      'lastSync': '1 min ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Rohan Nair',
      'device': 'Windows POS Terminal',
      'ipAddress': '192.168.2.15',
    },
    {
      'name': 'Bombay Electronics Hub',
      'city': 'Mumbai, Maharashtra',
      'vertical': 'Consumer Tech',
      'verticalColor': const Color(0xFF0284C7),
      'todaySales': 112000.0,
      'todayInvoices': 28,
      'lastSync': '3 mins ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Amit Shah',
      'device': 'iPad Pro 11 (iOS 17)',
      'ipAddress': '192.168.1.88',
    },
    {
      'name': 'Sanjivani Medicos & Wellness',
      'city': 'Delhi NCR',
      'vertical': 'Healthcare & Pharma',
      'verticalColor': const Color(0xFF059669),
      'todaySales': 31200.0,
      'todayInvoices': 45,
      'lastSync': '5 mins ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Pooja Sharma',
      'device': 'Android Touch All-in-One',
      'ipAddress': '192.168.1.42',
    },
    {
      'name': 'FabStyle Boutique & Garments',
      'city': 'Hyderabad, Telangana',
      'vertical': 'Fashion & Apparel',
      'verticalColor': const Color(0xFF7C3AED),
      'todaySales': 24600.0,
      'todayInvoices': 19,
      'lastSync': '18 mins ago (Offline)',
      'isOnline': false,
      'queuedOutbox': 4,
      'cashierOnDuty': 'Anjali Reddy',
      'device': 'Samsung Galaxy Tab S9',
      'ipAddress': '192.168.3.11',
    },
  ];

  // White-Label Configuration & Form State
  WhiteLabelBranding _branding = const WhiteLabelBranding(
    brandAppName: 'RetailMaster POS Suite',
    resellerCompanyName: 'OmniTech Cloud Solutions LLP',
    supportWhatsApp: '919876500000',
    primaryColorHex: '#4338CA',
    accentColorHex: '#F59E0B',
    receiptFooterTagline: 'Thank you for shopping! Powered by RetailMaster Cloud POS',
  );

  late final TextEditingController _appNameCtrl;
  late final TextEditingController _resellerCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _primaryCtrl;
  late final TextEditingController _accentCtrl;
  late final TextEditingController _taglineCtrl;
  final TextEditingController _fleetSearchCtrl = TextEditingController();
  final TextEditingController _licenseSearchCtrl = TextEditingController();
  String _licenseTierFilter = 'all';

  // Preset Colors for White-Label Picker
  final List<String> _primaryPresets = [
    '#4338CA', // Indigo
    '#2563EB', // Royal Blue
    '#059669', // Emerald
    '#7C3AED', // Violet
    '#0891B2', // Cyan
    '#DC2626', // Crimson
  ];

  final List<String> _accentPresets = [
    '#F59E0B', // Amber
    '#EA580C', // Orange
    '#10B981', // Mint
    '#EC4899', // Pink
    '#8B5CF6', // Purple
    '#06B6D4', // Sky
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _appNameCtrl = TextEditingController(text: _branding.brandAppName);
    _resellerCtrl = TextEditingController(text: _branding.resellerCompanyName);
    _waCtrl = TextEditingController(text: _branding.supportWhatsApp);
    _primaryCtrl = TextEditingController(text: _branding.primaryColorHex);
    _accentCtrl = TextEditingController(text: _branding.accentColorHex);
    _taglineCtrl = TextEditingController(text: _branding.receiptFooterTagline);

    // Initial Live Cloud Fetch and Periodic Polling
    _fetchLiveFleet(silent: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _fetchLiveFleet(silent: true);
    });
  }

  Timer? _pollingTimer;
  final BackendApiService _apiService = BackendApiService();

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabCtrl.dispose();
    _appNameCtrl.dispose();
    _resellerCtrl.dispose();
    _waCtrl.dispose();
    _primaryCtrl.dispose();
    _accentCtrl.dispose();
    _taglineCtrl.dispose();
    _fleetSearchCtrl.dispose();
    _licenseSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveFleet({bool silent = false}) async {
    if (!silent) setState(() => _isRefreshingFleet = true);
    final data = await _apiService.getAdminMerchants(masterToken: '889900');
    if (!mounted) return;
    if (data != null && data['success'] == true) {
      final list = data['merchants'] as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        setState(() {
          _fleetStores.clear();
          for (final m in list) {
            _fleetStores.add({
              'id': m['id'],
              'name': m['storeName'] ?? 'Unknown Store',
              'city': '${m['stateName'] ?? 'India'} (State ${m['stateCode'] ?? '27'})',
              'vertical': m['vertical'] == 'restaurantCafe'
                  ? 'Restaurant & Cafe'
                  : m['vertical'] == 'pharmacyHealth'
                      ? 'Healthcare & Pharma'
                      : m['vertical'] == 'garmentsApparel'
                          ? 'Fashion & Apparel'
                          : m['vertical'] == 'electronicsMobile'
                              ? 'Consumer Tech'
                              : 'Kirana & Retail',
              'verticalColor': m['vertical'] == 'restaurantCafe'
                  ? const Color(0xFFEA580C)
                  : m['vertical'] == 'pharmacyHealth'
                      ? const Color(0xFF059669)
                      : m['vertical'] == 'garmentsApparel'
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF2563EB),
              'todaySales': (m['totalSales'] as num?)?.toDouble() ?? 0.0,
              'todayInvoices': (m['totalInvoices'] as num?)?.toInt() ?? 0,
              'lastSync': m['isOnline'] == true ? 'Just now' : 'Offline',
              'isOnline': m['isOnline'] == true,
              'queuedOutbox': 0,
              'cashierOnDuty': m['ownerName'] ?? 'Store Owner',
              'device': 'POS Terminal',
              'ipAddress': '127.0.0.1',
              'phone': m['phone'],
              'licenseKey': m['licenseKey'],
            });
          }
          _isRefreshingFleet = false;
        });
      }
    }
    if (!silent) {
      setState(() => _isRefreshingFleet = false);
    }
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  Color get _currentPrimaryColor => _parseHex(_branding.primaryColorHex, AdminColors.primary);
  Color get _currentAccentColor => _parseHex(_branding.accentColorHex, const Color(0xFFF59E0B));

  void _refreshFleetTelemetry() async {
    await _fetchLiveFleet(silent: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live fleet heartbeat and sync telemetry refreshed from cloud!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.sidebarBg,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _currentPrimaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _branding.brandAppName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SUPERADMIN CONSOLE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _currentAccentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_branding.resellerCompanyName} • Central Cloud Control Tower',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Fleet Health Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AdminColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Fleet: 4/5 Online • 99.8% Sync',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Issue Key CTA
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(LucideIcons.keyRound, size: 14),
            label: Text(
              'Issue Commercial Key',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            onPressed: () => _showIssueKeyDialog(context),
          ),
          const SizedBox(width: 8),

          // Sign Out Button
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Color(0xFF94A3B8), size: 18),
              tooltip: 'Sign Out Admin',
              onPressed: widget.onLogout,
            ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: _currentPrimaryColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(LucideIcons.activity, size: 16), text: 'Centralized Cloud Analytics & Fleet Telemetry'),
            Tab(icon: Icon(LucideIcons.key, size: 16), text: 'Tenant Licenses & Quota Manager'),
            Tab(icon: Icon(LucideIcons.palette, size: 16), text: 'White-Label Branding & Theme Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCentralizedAnalyticsTab(),
          _buildLicenseManagerTab(),
          _buildWhiteLabelTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: CENTRALIZED CLOUD ANALYTICS & FLEET TELEMETRY
  // =========================================================================
  Widget _buildCentralizedAnalyticsTab() {
    double multiplier = 1.0;
    String periodLabel = 'today';
    switch (_selectedTimeFilter) {
      case FleetTimeFilter.today:
        multiplier = 1.0;
        periodLabel = 'today';
        break;
      case FleetTimeFilter.week:
        multiplier = 6.4;
        periodLabel = 'this week';
        break;
      case FleetTimeFilter.month:
        multiplier = 27.8;
        periodLabel = 'this month';
        break;
      case FleetTimeFilter.allTime:
        multiplier = 142.5;
        periodLabel = 'all-time';
        break;
    }

    final totalFleetSales = _fleetStores.fold<double>(0.0, (sum, s) => sum + (s['todaySales'] as double)) * multiplier;
    final totalFleetInvoices = (_fleetStores.fold<int>(0, (sum, s) => sum + (s['todayInvoices'] as int)) * multiplier).toInt();
    final onlineStores = _fleetStores.where((s) => s['isOnline'] == true).length;

    // Filter fleet stores by search and status
    final filteredFleet = _fleetStores.where((s) {
      final name = (s['name'] as String).toLowerCase();
      final city = (s['city'] as String).toLowerCase();
      final cashier = (s['cashierOnDuty'] as String).toLowerCase();
      final vertical = (s['vertical'] as String).toLowerCase();
      final q = _fleetSearchQuery.toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || city.contains(q) || cashier.contains(q) || vertical.contains(q);

      if (!matchesQuery) return false;

      if (_fleetStatusFilter == 'online') {
        return s['isOnline'] == true;
      } else if (_fleetStatusFilter == 'offline') {
        return s['isOnline'] == false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar & Fleet Performance KPIs Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                'Live Aggregated Cloud Fleet Metrics',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        _buildFilterChip('Today', FleetTimeFilter.today),
                        _buildFilterChip('Last 7 Days', FleetTimeFilter.week),
                        _buildFilterChip('Last 30 Days', FleetTimeFilter.month),
                        _buildFilterChip('All Time', FleetTimeFilter.allTime),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: _isRefreshingFleet
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.refreshCw, size: 13),
                    label: const Text('Refresh Telemetry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _currentPrimaryColor,
                      side: const BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isRefreshingFleet ? null : _refreshFleetTelemetry,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fleet Performance KPIs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFleetKpi(
                  title: 'TOTAL FLEET SALES (${periodLabel.toUpperCase()})',
                  value: '₹${totalFleetSales.toStringAsFixed(0)}',
                  subtitle: '+18.4% vs prior period',
                  icon: LucideIcons.indianRupee,
                  iconColor: _currentPrimaryColor,
                  bgColor: AdminColors.primaryLight,
                ),
                const SizedBox(width: 14),
                _buildFleetKpi(
                  title: 'INVOICES PROCESSED',
                  value: '$totalFleetInvoices Bills',
                  subtitle: 'Across all active terminals',
                  icon: LucideIcons.receipt,
                  iconColor: AdminColors.info,
                  bgColor: AdminColors.infoBg,
                ),
                const SizedBox(width: 14),
                _buildFleetKpi(
                  title: 'ACTIVE CONNECTED STORES',
                  value: '$onlineStores / ${_fleetStores.length} Stores',
                  subtitle: '1 store running offline outbox',
                  icon: LucideIcons.store,
                  iconColor: AdminColors.success,
                  bgColor: AdminColors.successBg,
                ),
                const SizedBox(width: 14),
                _buildFleetKpi(
                  title: 'CLOUD OUTBOX HEALTH',
                  value: '99.8% Synced',
                  subtitle: 'Avg latency: 14ms',
                  icon: LucideIcons.cloudCheck,
                  iconColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fleet Telemetry Table Card
          Container(
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Store Fleet Telemetry & Sync Outbox',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time heartbeat, sales volume, and background sync queue monitoring',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AdminColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search Tenant Input
                      SizedBox(
                        width: 240,
                        height: 38,
                        child: TextField(
                          controller: _fleetSearchCtrl,
                          onChanged: (v) => setState(() => _fleetSearchQuery = v.trim()),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search tenant, city, cashier...',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AdminColors.textMuted),
                            prefixIcon: const Icon(LucideIcons.search, size: 14, color: AdminColors.textMuted),
                            suffixIcon: _fleetSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 14),
                                    onPressed: () {
                                      _fleetSearchCtrl.clear();
                                      setState(() => _fleetSearchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: AdminColors.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status Filter Dropdown
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fleetStatusFilter,
                            icon: const Icon(LucideIcons.chevronDown, size: 14),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textPrimary, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                              DropdownMenuItem(value: 'online', child: Text('Online Only')),
                              DropdownMenuItem(value: 'offline', child: Text('Offline Only')),
                            ],
                            onChanged: (v) => setState(() => _fleetStatusFilter = v ?? 'all'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Header & Rows
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 960,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          color: AdminColors.surfaceSecondary,
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: _tableHeader('STORE / BRANCH')),
                              Expanded(flex: 2, child: _tableHeader('INDUSTRY VERTICAL')),
                              Expanded(flex: 2, child: _tableHeader('PERIOD SALES')),
                              Expanded(flex: 2, child: _tableHeader('BILLS')),
                              Expanded(flex: 2, child: _tableHeader('HEARTBEAT / SYNC')),
                              Expanded(flex: 2, child: _tableHeader('CASHIER ON DUTY')),
                              Expanded(flex: 2, child: _tableHeader('REMOTE ACTIONS')),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        if (filteredFleet.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(LucideIcons.store, size: 36, color: AdminColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text('No tenant stores match your search or filter.', style: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted)),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredFleet.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final store = filteredFleet[idx];
                              final isOnline = store['isOnline'] as bool;
                              final vertColor = store['verticalColor'] as Color;
                              final salesVal = (store['todaySales'] as double) * multiplier;
                              final invoiceVal = ((store['todayInvoices'] as int) * multiplier).toInt();

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                child: Row(
                                  children: [
                                    // Store Name & City
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            store['name'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AdminColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            store['city'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AdminColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Industry Vertical Badge
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: vertColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: vertColor.withValues(alpha: 0.25)),
                                          ),
                                          child: Text(
                                            store['vertical'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: vertColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Sales
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${salesVal.toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                    ),

                                    // Invoices
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$invoiceVal Bills',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ),

                                    // Heartbeat & Sync Status
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isOnline ? AdminColors.success : AdminColors.warning,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isOnline ? 'Online' : 'Offline (${store['queuedOutbox']} queued)',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isOnline ? AdminColors.success : AdminColors.warning,
                                                  ),
                                                ),
                                                Text(
                                                  store['lastSync'] as String,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AdminColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Cashier on Duty
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.user, size: 13, color: AdminColors.textMuted),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              store['cashierOnDuty'] as String,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Remote Actions
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Tooltip(
                                            message: 'Trigger Remote Sync Ping',
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  store['lastSync'] = 'Just now';
                                                  store['isOnline'] = true;
                                                  store['queuedOutbox'] = 0;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Triggered remote sync ping for ${store['name']}! Device responded OK.')),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AdminColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(LucideIcons.arrowUpDown, size: 13, color: _currentPrimaryColor),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: 'View Tenant Fleet Details',
                                            child: InkWell(
                                              onTap: () => _showTenantDetailsModal(context, store),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AdminColors.surfaceSecondary,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(LucideIcons.eye, size: 13, color: AdminColors.textSecondary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FleetTimeFilter filter) {
    final isSelected = _selectedTimeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedTimeFilter = filter),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _currentPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFleetKpi({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border, width: 1),
      ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _tableHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AdminColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  // =========================================================================
  // VIEW TENANT FLEET DETAILS MODAL
  // =========================================================================
  void _showTenantDetailsModal(BuildContext context, Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isOnline = store['isOnline'] as bool;
          final queued = store['queuedOutbox'] as int;
          final vertColor = store['verticalColor'] as Color;

          return AlertDialog(
            backgroundColor: AdminColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: vertColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.store, color: vertColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] as String,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '${store['city']} • ${store['vertical']}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? AdminColors.successBg : AdminColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline ? AdminColors.success : AdminColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'Online' : 'Offline ($queued Queued)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOnline ? AdminColors.success : AdminColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Row
                    Row(
                      children: [
                        _buildModalMetricCard('Today Sales', '₹${(store['todaySales'] as double).toStringAsFixed(0)}', LucideIcons.indianRupee),
                        const SizedBox(width: 10),
                        _buildModalMetricCard('Bills Processed', '${store['todayInvoices']}', LucideIcons.receipt),
                        const SizedBox(width: 10),
                        _buildModalMetricCard('Outbox Sync', '$queued items', LucideIcons.cloudUpload),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Technical Details Table
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Cashier on Duty', store['cashierOnDuty'] as String),
                          const Divider(height: 12),
                          _buildDetailRow('POS Device Hardware', store['device'] as String? ?? 'Sunmi T2 Mini'),
                          const Divider(height: 12),
                          _buildDetailRow('Local Network IP', store['ipAddress'] as String? ?? '192.168.1.100'),
                          const Divider(height: 12),
                          _buildDetailRow('Last Telemetry Ping', store['lastSync'] as String),
                          const Divider(height: 12),
                          _buildDetailRow('Offline Resilience', 'Sub-50ms SQLite + Outbox Retry'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions in modal
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _currentPrimaryColor,
                        side: BorderSide(color: _currentPrimaryColor),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      icon: const Icon(LucideIcons.refreshCw, size: 14),
                      label: const Text('Force Cloud Resync & Clear Local Outbox'),
                      onPressed: () {
                        setState(() {
                          store['lastSync'] = 'Just now';
                          store['isOnline'] = true;
                          store['queuedOutbox'] = 0;
                        });
                        setModalState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Force resync signal transmitted to ${store['name']}!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModalMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AdminColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: _currentPrimaryColor),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AdminColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
      ],
    );
  }

  // =========================================================================
  // TAB 2: TENANT LICENSES & QUOTA MANAGER
  // =========================================================================
  Widget _buildLicenseManagerTab() {
    final lifetimeCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.lifetimeEnterprise).length;
    final proCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.threeYearPro).length;
    final stdCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.oneYearStandard).length;
    final trialCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.freeTrial).length;

    // Filter licenses
    final filteredLicenses = _issuedLicenses.where((lic) {
      final q = _licenseSearchCtrl.text.toLowerCase().trim();
      final matchesQuery = q.isEmpty || lic.storeName.toLowerCase().contains(q) || lic.key.toLowerCase().contains(q) || lic.merchantId.toLowerCase().contains(q);
      if (!matchesQuery) return false;

      if (_licenseTierFilter == 'lifetime') return lic.tier == SubscriptionTier.lifetimeEnterprise;
      if (_licenseTierFilter == 'pro') return lic.tier == SubscriptionTier.threeYearPro;
      if (_licenseTierFilter == 'std') return lic.tier == SubscriptionTier.oneYearStandard;
      if (_licenseTierFilter == 'trial') return lic.tier == SubscriptionTier.freeTrial;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildResellerKpiCard('Total Issued', '${_issuedLicenses.length}', LucideIcons.keyRound, _currentPrimaryColor),
                const SizedBox(width: 12),
                _buildResellerKpiCard('Lifetime Enterprise', '$lifetimeCount', LucideIcons.crown, const Color(0xFFD97706)),
                const SizedBox(width: 12),
                _buildResellerKpiCard('3-Year Pro Seats', '$proCount', LucideIcons.badgeCheck, AdminColors.success),
                const SizedBox(width: 12),
                _buildResellerKpiCard('1-Year Standard', '$stdCount', LucideIcons.timer, AdminColors.info),
                const SizedBox(width: 12),
                _buildResellerKpiCard('Free Trials', '$trialCount', LucideIcons.zap, const Color(0xFF8B5CF6)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // License Cards List
          Container(
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Merchant Commercial Licenses',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AdminColors.textPrimary),
                            ),
                            Text(
                              'Cryptographically generated keys enforce branch store limits and staff seat quotas locally',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      // Search License
                      SizedBox(
                        width: 220,
                        height: 38,
                        child: TextField(
                          controller: _licenseSearchCtrl,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search license key...',
                            prefixIcon: const Icon(LucideIcons.search, size: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tier Filter
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _licenseTierFilter,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Tiers')),
                              DropdownMenuItem(value: 'lifetime', child: Text('Lifetime')),
                              DropdownMenuItem(value: 'pro', child: Text('3-Yr Pro')),
                              DropdownMenuItem(value: 'std', child: Text('Standard')),
                              DropdownMenuItem(value: 'trial', child: Text('Trial')),
                            ],
                            onChanged: (v) => setState(() => _licenseTierFilter = v ?? 'all'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('Issue Commercial Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: () => _showIssueKeyDialog(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                if (filteredLicenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No license keys found.', style: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredLicenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final lic = filteredLicenses[idx];
                      final isLifetime = lic.tier == SubscriptionTier.lifetimeEnterprise;

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isLifetime ? const Color(0xFFFEF3C7) : AdminColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isLifetime ? LucideIcons.crown : LucideIcons.shieldCheck,
                                      color: isLifetime ? const Color(0xFFD97706) : _currentPrimaryColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          lic.storeName,
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5, color: AdminColors.textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLifetime ? const Color(0xFFFEF3C7) : AdminColors.primaryLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            lic.tier.name.toUpperCase(),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: isLifetime ? const Color(0xFFB45309) : _currentPrimaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Merchant ID: ${lic.merchantId}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Validity Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: lic.isValid ? AdminColors.successBg : AdminColors.errorBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lic.isValid ? (isLifetime ? 'LIFETIME ACCESS' : '${lic.daysRemaining} days remaining') : 'EXPIRED',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: lic.isValid ? AdminColors.success : AdminColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Key Box & Copy Action
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AdminColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminColors.border, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.key, size: 14, color: AdminColors.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      lic.key,
                                      style: GoogleFonts.jetbrainsMono(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: lic.key));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Copied key ${lic.key} to clipboard!')),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.copy, size: 13, color: _currentPrimaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy Key',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _currentPrimaryColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Quota Badges & Add-on Gates
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _quotaChip(LucideIcons.store, 'Max Stores: ${lic.maxAllowedStores}'),
                                _quotaChip(LucideIcons.users, 'Staff Seats: ${lic.maxStaffSeats}'),
                                _quotaChip(
                                  lic.isDhandaAiEnabled ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                                  'Dhanda AI: ${lic.isDhandaAiEnabled ? 'ON' : 'OFF'}',
                                  isEnabled: lic.isDhandaAiEnabled,
                                ),
                                _quotaChip(
                                  lic.isOnlineDukanEnabled ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                                  'Online Dukan: ${lic.isOnlineDukanEnabled ? 'ON' : 'OFF'}',
                                  isEnabled: lic.isOnlineDukanEnabled,
                                ),

                                // Working +1 Year Renewal Action
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      final currentExpires = lic.expiresAt ?? DateTime.now();
                                      final updatedLic = lic.copyWith(
                                        expiresAt: currentExpires.add(const Duration(days: 365)),
                                      );
                                      final origIndex = _issuedLicenses.indexWhere((l) => l.key == lic.key);
                                      if (origIndex != -1) {
                                        _issuedLicenses[origIndex] = updatedLic;
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Extended subscription by +1 Year for ${lic.storeName}!')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    side: const BorderSide(color: AdminColors.border),
                                  ),
                                  child: Text('+1 Year Renewal', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                                ),

                                // Working + Staff Seat Action
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      final updatedLic = lic.copyWith(
                                        maxStaffSeats: lic.maxStaffSeats + 1,
                                      );
                                      final origIndex = _issuedLicenses.indexWhere((l) => l.key == lic.key);
                                      if (origIndex != -1) {
                                        _issuedLicenses[origIndex] = updatedLic;
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added +1 Staff Seat quota for ${lic.storeName}! (Now: ${lic.maxStaffSeats + 1} seats)')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    side: const BorderSide(color: AdminColors.border),
                                  ),
                                  child: Text('+ Staff Seat', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResellerKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 195,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border, width: 1),
      ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AdminColors.textMuted)),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AdminColors.textPrimary)),
              ],
            ),
          ],
        ),
      );
  }

  Widget _quotaChip(IconData icon, String text, {bool isEnabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isEnabled ? _currentPrimaryColor : AdminColors.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEnabled ? AdminColors.textPrimary : AdminColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: WHITE-LABEL BRANDING & THEME CONFIGURATOR
  // =========================================================================
  Widget _buildWhiteLabelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Config Form
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global White-Label Rebranding Engine',
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Re-brand the entire suite with your agency brand assets, custom themes, and customer touchpoints.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _appNameCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'White-Label App Name (e.g. RetailMaster POS, VyaparPro)',
                      prefixIcon: const Icon(LucideIcons.appWindow, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _resellerCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Reseller / Franchisor Legal Company Name',
                      prefixIcon: const Icon(LucideIcons.building2, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _waCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Central Support WhatsApp Hotline (e.g. 919876500000)',
                      prefixIcon: const Icon(LucideIcons.messageCircle, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Color Picker & Swatches
                  Text(
                    'Primary Brand Color',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _primaryCtrl,
                          onChanged: (v) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Hex Code (e.g. #4338CA)',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _parseHex(_primaryCtrl.text, AdminColors.primary),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black12),
                              ),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Preset color buttons
                      ..._primaryPresets.map((hex) {
                        final c = _parseHex(hex, Colors.blue);
                        final isSelected = _primaryCtrl.text.toUpperCase() == hex.toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _primaryCtrl.text = hex;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: isSelected ? 2.5 : 0,
                                ),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Accent Color Picker & Swatches
                  Text(
                    'Accent / Highlight Color',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _accentCtrl,
                          onChanged: (v) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Hex Code (e.g. #F59E0B)',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _parseHex(_accentCtrl.text, const Color(0xFFF59E0B)),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black12),
                              ),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ..._accentPresets.map((hex) {
                        final c = _parseHex(hex, Colors.amber);
                        final isSelected = _accentCtrl.text.toUpperCase() == hex.toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _accentCtrl.text = hex;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: isSelected ? 2.5 : 0,
                                ),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _taglineCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Receipt Footer Tagline (Printed on slips & PDFs)',
                      prefixIcon: const Icon(LucideIcons.receipt, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.save, size: 16),
                      label: Text(
                        'Save & Apply Branding',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _branding = _branding.copyWith(
                            brandAppName: _appNameCtrl.text.trim(),
                            resellerCompanyName: _resellerCtrl.text.trim(),
                            supportWhatsApp: _waCtrl.text.trim(),
                            primaryColorHex: _primaryCtrl.text.trim(),
                            accentColorHex: _accentCtrl.text.trim(),
                            receiptFooterTagline: _taglineCtrl.text.trim(),
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Global White-Label branding saved and applied successfully!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Live Theme & Receipt Simulator Preview
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-Time Rebranding Simulator',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Preview how branding appears across merchant apps & end-customer slips',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Simulated App Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _currentPrimaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.store, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _appNameCtrl.text.isNotEmpty ? _appNameCtrl.text : _branding.brandAppName,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _currentAccentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Simulated Paper Slip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text('=== TAX INVOICE ===', style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.w700, fontSize: 11)),
                        Text('PUNE MEGA MART', style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('GSTIN: 27AABCE1234F1Z5', style: GoogleFonts.jetbrainsMono(fontSize: 10, color: AdminColors.textMuted)),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Basmati Rice 5kg', style: GoogleFonts.jetbrainsMono(fontSize: 11)),
                            Text('₹549.00', style: GoogleFonts.jetbrainsMono(fontSize: 11)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chakki Atta 10kg', style: GoogleFonts.jetbrainsMono(fontSize: 11)),
                            Text('₹415.00', style: GoogleFonts.jetbrainsMono(fontSize: 11)),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL PAID', style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.w800, fontSize: 12)),
                            Text('₹964.00', style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Text(
                            _taglineCtrl.text.isNotEmpty ? _taglineCtrl.text : _branding.receiptFooterTagline,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _currentPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Helpdesk: WhatsApp +${_waCtrl.text}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AdminColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ISSUE NEW COMMERCIAL KEY MODAL
  // =========================================================================
  void _showIssueKeyDialog(BuildContext context) {
    final storeCtrl = TextEditingController(text: 'Metro Departmental Store');
    SubscriptionTier tier = SubscriptionTier.threeYearPro;
    double storesCount = 3.0;
    double staffSeatCount = 5.0;
    bool dhandaAi = true;
    bool onlineDukan = true;
    String? generatedKey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AdminColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.keyRound, color: _currentPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Issue Commercial License Key',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: storeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Store / Merchant Legal Entity Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tier dropdown: Trial / Standard / Pro / Enterprise
                  DropdownButtonFormField<SubscriptionTier>(
                    initialValue: tier,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Subscription Tier', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                        value: SubscriptionTier.freeTrial,
                        child: Text('Free Trial (30-Day Sandbox)'),
                      ),
                      DropdownMenuItem(
                        value: SubscriptionTier.oneYearStandard,
                        child: Text('1-Year Standard Commercial License'),
                      ),
                      DropdownMenuItem(
                        value: SubscriptionTier.threeYearPro,
                        child: Text('3-Year Pro Multi-Store License'),
                      ),
                      DropdownMenuItem(
                        value: SubscriptionTier.lifetimeEnterprise,
                        child: Text('Lifetime Enterprise (Perpetual / No Expiry)'),
                      ),
                    ],
                    onChanged: (t) => setDialogState(() => tier = t ?? SubscriptionTier.threeYearPro),
                  ),
                  const SizedBox(height: 16),

                  // Store Count Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Store Count Quota:', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text('${storesCount.toInt()} Stores Allowed', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _currentPrimaryColor)),
                    ],
                  ),
                  Slider(
                    value: storesCount,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    activeColor: _currentPrimaryColor,
                    label: '${storesCount.toInt()} Stores',
                    onChanged: (v) => setDialogState(() => storesCount = v),
                  ),
                  const SizedBox(height: 8),

                  // Staff Seat Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Staff Seat Quota:', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text('${staffSeatCount.toInt()} Staff Seats', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _currentPrimaryColor)),
                    ],
                  ),
                  Slider(
                    value: staffSeatCount,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: _currentPrimaryColor,
                    label: '${staffSeatCount.toInt()} Seats',
                    onChanged: (v) => setDialogState(() => staffSeatCount = v),
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: _currentPrimaryColor,
                    title: Text('Enable Dhanda AI Module', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Google Business Profile footfall audit & review engine', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted)),
                    value: dhandaAi,
                    onChanged: (v) => setDialogState(() => dhandaAi = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: _currentPrimaryColor,
                    title: Text('Enable WhatsApp Online Dukan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('24x7 digital storefront synchronized with local POS stock', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted)),
                    value: onlineDukan,
                    onChanged: (v) => setDialogState(() => onlineDukan = v),
                  ),

                  // Generated Key Box if key was generated
                  if (generatedKey != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.success),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.checkCircle, size: 14, color: AdminColors.success),
                              const SizedBox(width: 6),
                              Text('Key Generated Successfully!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AdminColors.success)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            generatedKey!,
                            style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.w800, fontSize: 13, color: AdminColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(LucideIcons.copy, size: 13),
                            label: const Text('Copy Generated Key', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedKey!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied key $generatedKey to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(generatedKey != null ? 'Done' : 'Cancel'),
            ),
            if (generatedKey == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.key, size: 15),
                label: const Text('Generate Key'),
                onPressed: () {
                  final storeName = storeCtrl.text.isNotEmpty ? storeCtrl.text.trim() : 'New Merchant';
                  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
                  String tierPrefix = 'PRO';
                  if (tier == SubscriptionTier.freeTrial) tierPrefix = 'TRIAL';
                  if (tier == SubscriptionTier.oneYearStandard) tierPrefix = 'STD';
                  if (tier == SubscriptionTier.lifetimeEnterprise) tierPrefix = 'LIFE';

                  final key = 'BH-$tierPrefix-2026-$timestamp';

                  final newLic = MerchantLicenseKey(
                    key: key,
                    merchantId: 'm_$timestamp',
                    storeName: storeName,
                    tier: tier,
                    issuedAt: DateTime.now(),
                    expiresAt: tier == SubscriptionTier.lifetimeEnterprise
                        ? null
                        : (tier == SubscriptionTier.freeTrial
                            ? DateTime.now().add(const Duration(days: 30))
                            : (tier == SubscriptionTier.threeYearPro
                                ? DateTime.now().add(const Duration(days: 1095))
                                : DateTime.now().add(const Duration(days: 365)))),
                    maxAllowedStores: storesCount.toInt(),
                    maxStaffSeats: staffSeatCount.toInt(),
                    isDhandaAiEnabled: dhandaAi,
                    isOnlineDukanEnabled: onlineDukan,
                  );

                  setState(() => _issuedLicenses.insert(0, newLic));
                  setDialogState(() => generatedKey = key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Issued Commercial Key $key successfully!')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
