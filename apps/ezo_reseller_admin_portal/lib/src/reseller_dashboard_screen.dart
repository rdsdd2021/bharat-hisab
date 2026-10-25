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

class _ResellerDashboardScreenState extends State<ResellerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Active Multi-Tenant License Store
  final List<MerchantLicenseKey> _issuedLicenses = [
    MerchantLicenseKey(
      key: 'EZO-PRO-2026-PUNE-8877',
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
      key: 'EZO-LIFE-2026-MUMBAI-1122',
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
      key: 'EZO-PRO-2026-BLR-5544',
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
      key: 'EZO-STD-2026-DELHI-4433',
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
      key: 'EZO-STD-2026-HYD-9988',
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
      'verticalColor': Color(0xFF2563EB),
      'todaySales': 42850.0,
      'todayInvoices': 68,
      'lastSync': 'Just now',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Sunil Verma',
    },
    {
      'name': 'The Spice Bistro & Cafe',
      'city': 'Bengaluru, Karnataka',
      'vertical': 'Restaurant & Cafe',
      'verticalColor': Color(0xFFEA580C),
      'todaySales': 68400.0,
      'todayInvoices': 94,
      'lastSync': '1 min ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Rohan Nair',
    },
    {
      'name': 'Bombay Electronics Hub',
      'city': 'Mumbai, Maharashtra',
      'vertical': 'Consumer Tech',
      'verticalColor': Color(0xFF0284C7),
      'todaySales': 112000.0,
      'todayInvoices': 28,
      'lastSync': '3 mins ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Amit Shah',
    },
    {
      'name': 'Sanjivani Medicos & Wellness',
      'city': 'Delhi NCR',
      'vertical': 'Healthcare & Pharma',
      'verticalColor': Color(0xFF059669),
      'todaySales': 31200.0,
      'todayInvoices': 45,
      'lastSync': '5 mins ago',
      'isOnline': true,
      'queuedOutbox': 0,
      'cashierOnDuty': 'Pooja Sharma',
    },
    {
      'name': 'FabStyle Boutique & Garments',
      'city': 'Hyderabad, Telangana',
      'vertical': 'Fashion & Apparel',
      'verticalColor': Color(0xFF7C3AED),
      'todaySales': 24600.0,
      'todayInvoices': 19,
      'lastSync': '18 mins ago (Offline)',
      'isOnline': false,
      'queuedOutbox': 4,
      'cashierOnDuty': 'Anjali Reddy',
    },
  ];

  // White-Label Configuration
  WhiteLabelBranding _branding = const WhiteLabelBranding(
    brandAppName: 'RetailMaster POS Suite',
    resellerCompanyName: 'OmniTech Cloud Solutions LLP',
    supportWhatsApp: '919876500000',
    primaryColorHex: '#4338CA',
    accentColorHex: '#F59E0B',
    receiptFooterTagline: 'Thank you for shopping! Powered by RetailMaster Cloud POS',
  );

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
                color: AdminColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _branding.brandAppName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white,
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
                          color: const Color(0xFFFBBF24),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_branding.resellerCompanyName} • Central Cloud Control Tower',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
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
              backgroundColor: AdminColors.primary,
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
          indicatorColor: const Color(0xFF818CF8),
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
    final totalFleetSales = _fleetStores.fold<double>(0.0, (sum, s) => sum + (s['todaySales'] as double));
    final totalFleetInvoices = _fleetStores.fold<int>(0, (sum, s) => sum + (s['todayInvoices'] as int));
    final onlineStores = _fleetStores.where((s) => s['isOnline'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fleet Performance KPIs
          Row(
            children: [
              _buildFleetKpi(
                title: 'TOTAL FLEET SALES (TODAY)',
                value: '₹${totalFleetSales.toStringAsFixed(0)}',
                subtitle: '+18.4% vs yesterday',
                icon: LucideIcons.indianRupee,
                iconColor: AdminColors.primary,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                      OutlinedButton.icon(
                        icon: const Icon(LucideIcons.refreshCw, size: 13),
                        label: const Text('Refresh Fleet Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminColors.primary,
                          side: const BorderSide(color: AdminColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fleet heartbeat telemetry refreshed!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  color: AdminColors.surfaceSecondary,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _tableHeader('STORE / BRANCH')),
                      Expanded(flex: 2, child: _tableHeader('INDUSTRY VERTICAL')),
                      Expanded(flex: 2, child: _tableHeader('TODAY SALES')),
                      Expanded(flex: 2, child: _tableHeader('BILLS TODAY')),
                      Expanded(flex: 2, child: _tableHeader('HEARTBEAT / SYNC')),
                      Expanded(flex: 2, child: _tableHeader('CASHIER ON DUTY')),
                      Expanded(flex: 2, child: _tableHeader('REMOTE ACTIONS')),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _fleetStores.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final store = _fleetStores[idx];
                    final isOnline = store['isOnline'] as bool;
                    final vertColor = store['verticalColor'] as Color;

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

                          // Today Sales
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${(store['todaySales'] as double).toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                          ),

                          // Invoices Today
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${store['todayInvoices']} Bills',
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOnline ? 'Online' : 'Offline (${store['queuedOutbox']} queued)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isOnline ? AdminColors.success : AdminColors.warning,
                                      ),
                                    ),
                                    Text(
                                      store['lastSync'] as String,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AdminColors.textMuted),
                                    ),
                                  ],
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
                                Text(
                                  store['cashierOnDuty'] as String,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                                ),
                              ],
                            ),
                          ),

                          // Remote Actions
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Triggered remote sync ping for ${store['name']}!')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AdminColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(LucideIcons.arrowUpDown, size: 13, color: AdminColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Opening cloud ledger inspect for ${store['name']}...')),
                                    );
                                  },
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
        ],
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
    return Expanded(
      child: Container(
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
  // TAB 2: TENANT LICENSES & QUOTA MANAGER
  // =========================================================================
  Widget _buildLicenseManagerTab() {
    final lifetimeCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.lifetimeEnterprise).length;
    final proCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.threeYearPro).length;
    final stdCount = _issuedLicenses.where((l) => l.tier == SubscriptionTier.oneYearStandard).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Strip
          Row(
            children: [
              _buildResellerKpiCard('Total Issued Licenses', '${_issuedLicenses.length}', LucideIcons.keyRound, AdminColors.primary),
              const SizedBox(width: 12),
              _buildResellerKpiCard('Lifetime Enterprise', '$lifetimeCount', LucideIcons.crown, const Color(0xFFD97706)),
              const SizedBox(width: 12),
              _buildResellerKpiCard('3-Year Pro Seats', '$proCount', LucideIcons.badgeCheck, AdminColors.success),
              const SizedBox(width: 12),
              _buildResellerKpiCard('1-Year Standard', '$stdCount', LucideIcons.timer, AdminColors.info),
            ],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Merchant License Keys',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: AdminColors.textPrimary),
                          ),
                          Text(
                            'Cryptographically generated keys enforce branch store limits and staff seat quotas locally',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('New License Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
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

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _issuedLicenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final lic = _issuedLicenses[idx];
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
                                    color: isLifetime ? const Color(0xFFD97706) : AdminColors.primary,
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
                                            color: isLifetime ? const Color(0xFFB45309) : AdminColors.primary,
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
                                      const Icon(LucideIcons.copy, size: 13, color: AdminColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Copy Key',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Quota Badges & Add-on Gates
                          Row(
                            children: [
                              _quotaChip(LucideIcons.store, 'Max Stores: ${lic.maxAllowedStores}'),
                              const SizedBox(width: 6),
                              _quotaChip(LucideIcons.users, 'Staff Seats: ${lic.maxStaffSeats}'),
                              const SizedBox(width: 6),
                              _quotaChip(
                                lic.isDhandaAiEnabled ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                                'Dhanda AI: ${lic.isDhandaAiEnabled ? 'ON' : 'OFF'}',
                                isEnabled: lic.isDhandaAiEnabled,
                              ),
                              const SizedBox(width: 6),
                              _quotaChip(
                                lic.isOnlineDukanEnabled ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                                'Online Dukan: ${lic.isOnlineDukanEnabled ? 'ON' : 'OFF'}',
                                isEnabled: lic.isOnlineDukanEnabled,
                              ),
                              const Spacer(),

                              // Quick Admin Actions
                              OutlinedButton(
                                onPressed: () {
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
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added +1 Staff Seat quota for ${lic.storeName}!')),
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
    return Expanded(
      child: Container(
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
          Icon(icon, size: 12, color: isEnabled ? AdminColors.primary : AdminColors.textMuted),
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
    final appNameCtrl = TextEditingController(text: _branding.brandAppName);
    final resellerCtrl = TextEditingController(text: _branding.resellerCompanyName);
    final waCtrl = TextEditingController(text: _branding.supportWhatsApp);
    final primaryCtrl = TextEditingController(text: _branding.primaryColorHex);
    final taglineCtrl = TextEditingController(text: _branding.receiptFooterTagline);

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
                    'Global White-Label Branding Engine',
                    style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Re-brand the entire Flutter monorepo with your own brand assets, theme colors, and customer touchpoints.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.textMuted),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: appNameCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'White-Label App Name (e.g. RetailMaster POS, VyaparPro)',
                      prefixIcon: const Icon(LucideIcons.appWindow, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: resellerCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Reseller / Franchisor Legal Company Name',
                      prefixIcon: const Icon(LucideIcons.building2, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: waCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Central Support WhatsApp Hotline (e.g. 919876500000)',
                      prefixIcon: const Icon(LucideIcons.messageCircle, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: primaryCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Brand Primary Color Hex Code (e.g. #4338CA)',
                      prefixIcon: const Icon(LucideIcons.palette, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: taglineCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Receipt Footer Tagline (Printed on all slips & PDFs)',
                      prefixIcon: const Icon(LucideIcons.receipt, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.save, size: 15),
                      label: Text(
                        'Save & Deploy White-Label Branding',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        setState(() {
                          _branding = _branding.copyWith(
                            brandAppName: appNameCtrl.text,
                            resellerCompanyName: resellerCtrl.text,
                            supportWhatsApp: waCtrl.text,
                            primaryColorHex: primaryCtrl.text,
                            receiptFooterTagline: taglineCtrl.text,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Global White-Label configuration updated successfully!')),
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
                    'Preview how branding appears to merchants & end-customers',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Simulated App Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.store, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _branding.brandAppName,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const Spacer(),
                        const Icon(LucideIcons.wifi, color: Colors.white70, size: 14),
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
                            _branding.receiptFooterTagline,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.primary,
                            ),
                          ),
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
    int stores = 3;
    int staff = 5;
    bool dhandaAi = true;
    bool onlineDukan = true;

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
                child: const Icon(LucideIcons.keyRound, color: AdminColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Issue New Commercial License Key',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
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
                const SizedBox(height: 12),

                DropdownButtonFormField<SubscriptionTier>(
                  initialValue: tier,
                  decoration: const InputDecoration(labelText: 'Subscription Tier', border: OutlineInputBorder()),
                  items: SubscriptionTier.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text('${t.name.toUpperCase()} (${t == SubscriptionTier.lifetimeEnterprise ? 'No Expiry' : (t == SubscriptionTier.threeYearPro ? '3 Years' : '1 Year')})'),
                    );
                  }).toList(),
                  onChanged: (t) => setDialogState(() => tier = t ?? SubscriptionTier.threeYearPro),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: stores,
                        decoration: const InputDecoration(labelText: 'Branch Stores Quota', border: OutlineInputBorder()),
                        items: [1, 2, 3, 5, 10, 25].map((n) => DropdownMenuItem(value: n, child: Text('$n Stores'))).toList(),
                        onChanged: (n) => setDialogState(() => stores = n ?? 3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: staff,
                        decoration: const InputDecoration(labelText: 'Staff Seats Quota', border: OutlineInputBorder()),
                        items: [2, 5, 10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n Seats'))).toList(),
                        onChanged: (n) => setDialogState(() => staff = n ?? 5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminColors.primary,
                  title: Text('Enable Dhanda AI Module', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('Google Business Profile footfall audit & review replier', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted)),
                  value: dhandaAi,
                  onChanged: (v) => setDialogState(() => dhandaAi = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AdminColors.primary,
                  title: Text('Enable WhatsApp Online Dukan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('24x7 digital storefront synchronized with local POS stock', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.textMuted)),
                  value: onlineDukan,
                  onChanged: (v) => setDialogState(() => onlineDukan = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final storeName = storeCtrl.text.isNotEmpty ? storeCtrl.text : 'New Merchant';
                final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
                final key = 'EZO-${tier.name.toUpperCase()}-$timestamp';

                final newLic = MerchantLicenseKey(
                  key: key,
                  merchantId: 'm_$timestamp',
                  storeName: storeName,
                  tier: tier,
                  issuedAt: DateTime.now(),
                  expiresAt: tier == SubscriptionTier.lifetimeEnterprise
                      ? null
                      : (tier == SubscriptionTier.threeYearPro
                          ? DateTime.now().add(const Duration(days: 1095))
                          : DateTime.now().add(const Duration(days: 365))),
                  maxAllowedStores: stores,
                  maxStaffSeats: staff,
                  isDhandaAiEnabled: dhandaAi,
                  isOnlineDukanEnabled: onlineDukan,
                );

                setState(() => _issuedLicenses.insert(0, newLic));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Issued Commercial Key $key successfully!')),
                );
              },
              child: const Text('Generate Cryptographic Key'),
            ),
          ],
        ),
      ),
    );
  }
}
