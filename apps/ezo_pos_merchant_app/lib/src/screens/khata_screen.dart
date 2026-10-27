import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import '../theme/ezo_theme.dart';

class KhataScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final StaffMember cashier;

  const KhataScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
    required this.cashier,
  });

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late EzoKhataService _khataService;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _cashCountCtrl = TextEditingController(text: '19150');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _khataService = EzoKhataService(repository: widget.repository);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _cashCountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.repository.getCustomerParties();
    final suppliers = widget.repository.getSupplierParties();
    final totalReceivables = customers.fold(0.0, (sum, c) => sum + (c.netBalance > 0 ? c.netBalance : 0.0));
    final totalPayables = suppliers.fold(0.0, (sum, s) => sum + (s.netBalance > 0 ? s.netBalance : 0.0));

    return Scaffold(
      backgroundColor: EzoColors.background,
      body: Column(
        children: [
          // KPI Summary Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: EzoColors.surface,
              border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: Row(
              children: [
                _buildKhataKpiCard(
                  'Total You Will Get (Receivables)',
                  '₹${totalReceivables.toStringAsFixed(2)}',
                  LucideIcons.arrowDownLeft,
                  EzoColors.success,
                  EzoColors.successBg,
                ),
                const SizedBox(width: 8),
                _buildKhataKpiCard(
                  'Total You Will Give (Payables)',
                  '₹${totalPayables.toStringAsFixed(2)}',
                  LucideIcons.arrowUpRight,
                  EzoColors.error,
                  EzoColors.errorBg,
                ),
              ],
            ),
          ),

          // Sub-Tabs Header
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: EzoColors.surface,
              border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: EzoColors.primary,
              unselectedLabelColor: EzoColors.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorColor: EzoColors.primary,
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: 'Customers (${customers.length})'),
                Tab(text: 'Suppliers (${suppliers.length})'),
                const Tab(text: 'Cash Reconciliation'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCustomersTab(customers),
                _buildSuppliersTab(suppliers),
                _buildCashDrawerTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EzoColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.userPlus, size: 16),
        label: Text('Add Khata Party', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        onPressed: () => _showAddPartyDialog(context),
      ),
    );
  }

  Widget _buildKhataKpiCard(String title, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
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

  Widget _buildCustomersTab(List<PartyAccount> customers) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = query.isEmpty
        ? customers
        : customers.where((c) {
            return c.name.toLowerCase().contains(query) || c.phone.contains(query);
          }).toList();

    return Column(
      children: [
        // Search Strip
        Container(
          padding: const EdgeInsets.all(10),
          color: EzoColors.surface,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: EzoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 16, color: EzoColors.textMuted),
                hintText: 'Search customers by name or phone...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 14, color: EzoColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: EzoColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.bookUser, size: 30, color: EzoColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          customers.isEmpty ? 'No Customers in Khata Yet' : 'No Customers Matched',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: EzoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage customer credit (udhaar), track balances, and send automated WhatsApp reminders with UPI payment links.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: EzoColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EzoColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.userPlus, size: 16),
                          label: const Text('Add Customer to Khata'),
                          onPressed: () => _showAddPartyDialog(context, defaultType: PartyType.customer),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final c = filtered[idx];
                    final isDue = c.isPaymentDueTodayOrOverdue;

                    return InkWell(
                      onTap: () => _showCustomerStatementModal(context, c),
                      child: Container(
                        color: EzoColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDue ? EzoColors.errorBg : EzoColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: isDue ? EzoColors.error : EzoColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Customer Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: EzoColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isDue) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: EzoColors.errorBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'DUE TODAY',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: EzoColors.error,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ph: ${c.phone} • ${c.ledgerEntries.length} entries',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                                  ),
                                ],
                              ),
                            ),

                            // Balance & Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${c.netBalance.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: c.netBalance > 0 ? EzoColors.error : EzoColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Send WhatsApp Reminder
                                    InkWell(
                                      onTap: () => _sendWhatsAppReminder(c),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(LucideIcons.messageSquare, color: EzoColors.whatsapp, size: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Give Credit (+ Udhaar)
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: EzoColors.error,
                                        side: const BorderSide(color: EzoColors.error, width: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        minimumSize: Size.zero,
                                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () => _showGiveCreditDialog(c),
                                      child: const Text('+ Udhaar'),
                                    ),
                                    const SizedBox(width: 6),
                                    // Got Pay (- Jama)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EzoColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        minimumSize: Size.zero,
                                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () => _showRecordPaymentDialog(c),
                                      child: const Text('- Jama'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSuppliersTab(List<PartyAccount> suppliers) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = query.isEmpty
        ? suppliers
        : suppliers.where((s) {
            return s.name.toLowerCase().contains(query) || s.phone.contains(query);
          }).toList();

    if (suppliers.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.truck, size: 30, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Suppliers in Khata Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: EzoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Record vendor purchase invoices, track wholesale payables, and manage payment settlements with your suppliers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: EzoColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.truck, size: 16),
                label: const Text('Add First Supplier'),
                onPressed: () => _showAddPartyDialog(context, defaultType: PartyType.supplier),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final s = filtered[idx];
        return InkWell(
          onTap: () => _showCustomerStatementModal(context, s),
          child: Container(
            color: EzoColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EzoColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.truck, color: EzoColors.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: EzoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GSTIN: ${s.gstin.isNotEmpty ? s.gstin : 'Unregistered'} • Ph: ${s.phone}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${s.netBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: EzoColors.error,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showRecordPaymentDialog(s),
                      child: const Text('Pay Vendor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashDrawerTab() {
    final double countedVal = double.tryParse(_cashCountCtrl.text) ?? 19150.0;
    final recon = CashDrawerReconciliation(
      openingCash: 5000.0,
      cashSales: 12450.0,
      cashUdhaarCollections: 2500.0,
      cashExpenses: 800.0,
      actualCountedCash: countedVal,
    );

    final isBalanced = recon.isBalanced;
    final diff = recon.discrepancy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Cash Drawer Reconciliation',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.checkCheck, size: 13),
                label: const Text('Close Drawer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EzoColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Cash Drawer closed with actual cash ₹${recon.actualCountedCash.toStringAsFixed(2)}'),
                      backgroundColor: EzoColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Column(
              children: [
                _buildReconRow('Opening Cash Float', '₹${recon.openingCash.toStringAsFixed(2)}'),
                _buildReconRow('Cash Sales Today', '+ ₹${recon.cashSales.toStringAsFixed(2)}', color: EzoColors.success),
                _buildReconRow('Cash Udhaar Collected Today', '+ ₹${recon.cashUdhaarCollections.toStringAsFixed(2)}', color: EzoColors.success),
                _buildReconRow('Cash Expenses Paid Out', '- ₹${recon.cashExpenses.toStringAsFixed(2)}', color: EzoColors.error),
                const Divider(height: 16),
                _buildReconRow('Expected Cash in Drawer', '₹${recon.expectedCashInDrawer.toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 8),

                // Actual Counted Cash Input Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actual Counted Cash In Drawer:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                    ),
                    SizedBox(
                      width: 120,
                      height: 36,
                      child: TextField(
                        controller: _cashCountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Drawer Status:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBalanced ? EzoColors.successBg : (diff > 0 ? const Color(0xFFEFF6FF) : EzoColors.errorBg),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBalanced
                            ? 'BALANCED (₹0.00 Diff)'
                            : (diff > 0 ? 'SURPLUS (+₹${diff.toStringAsFixed(2)})' : 'SHORTAGE (-₹${(-diff).toStringAsFixed(2)})'),
                        style: GoogleFonts.plusJakartaSans(
                          color: isBalanced ? EzoColors.success : (diff > 0 ? const Color(0xFF2563EB) : EzoColors.error),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? EzoColors.textPrimary : EzoColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isBold ? EzoColors.textPrimary : EzoColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerStatementModal(BuildContext context, PartyAccount party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final currentParty = widget.repository.getParty(party.id) ?? party;
        final entries = currentParty.ledgerEntries;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: EzoColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentParty.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: EzoColors.textPrimary),
                      ),
                      Text(
                        'Ph: ${currentParty.phone} • ${currentParty.partyType.name.toUpperCase()}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${currentParty.netBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: currentParty.netBalance > 0 ? EzoColors.error : EzoColors.success,
                        ),
                      ),
                      Text(
                        currentParty.netBalance > 0 ? 'Total Due' : 'Settled / Advance',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: EzoColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),

              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.arrowUpRight, size: 14, color: EzoColors.error),
                      label: const Text('Give Credit (+ Udhaar)'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: EzoColors.error),
                        foregroundColor: EzoColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showGiveCreditDialog(currentParty);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.arrowDownLeft, size: 14),
                      label: const Text('Got Pay (- Jama)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRecordPaymentDialog(currentParty);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.messageSquare, size: 14),
                      label: const Text('WhatsApp Reminder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.whatsapp,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendWhatsAppReminder(currentParty);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: EzoColors.error, size: 18),
                    tooltip: 'Delete Party',
                    onPressed: () => _confirmDeleteParty(context, currentParty),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),

              Text(
                'Ledger Statement Transactions (${entries.length})',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Ledger Transactions List
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text('No transactions recorded yet.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted)),
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (c, i) {
                          final e = entries[entries.length - 1 - i]; // newest first
                          final isDebit = e.debitYouGave > 0;
                          final dateStr = '${e.entryDate.day}/${e.entryDate.month}/${e.entryDate.year}';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDebit ? EzoColors.errorBg : EzoColors.successBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isDebit ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                                    size: 14,
                                    color: isDebit ? EzoColors.error : EzoColors.success,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isDebit ? 'Credit Given (+ Udhaar)' : 'Payment Received (- Jama)',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                      Text(
                                        '$dateStr • Mode: ${e.paymentMode.toUpperCase()} ${e.notes.isNotEmpty ? '• ${e.notes}' : ''}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isDebit ? '+' : '-'} ₹${(isDebit ? e.debitYouGave : e.creditYouGot).toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDebit ? EzoColors.error : EzoColors.success,
                                  ),
                                ),
                              ],
                            ),
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

  void _showGiveCreditDialog(PartyAccount customer) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(LucideIcons.arrowUpRight, color: EzoColors.error, size: 20),
            const SizedBox(width: 8),
            Text('Give Credit (+ Udhaar)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Credit Amount (₹) *', prefixIcon: Icon(LucideIcons.indianRupee, size: 16)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: refCtrl,
              decoration: const InputDecoration(labelText: 'Bill / Voucher # (Optional)', hintText: 'e.g. BILL-1024'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes / Item Description', hintText: 'e.g. Kirana items grocery'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EzoColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0.0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid credit amount')));
                return;
              }

              final entry = KhataLedgerEntry(
                id: 'khata_${DateTime.now().millisecondsSinceEpoch}',
                partyId: customer.id,
                entryDate: DateTime.now(),
                debitYouGave: amt,
                creditYouGot: 0.0,
                paymentMode: 'manual_credit',
                collectedByStaffId: widget.cashier.id,
                collectedByStaffName: widget.cashier.fullName,
                referenceInvoiceNumber: refCtrl.text.trim(),
                notes: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Manual Udhaar Credit',
                createdAt: DateTime.now(),
              );

              await widget.repository.db.addKhataEntry(entry);
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Issued ₹${amt.toStringAsFixed(2)} Udhaar to ${customer.name}'),
                    backgroundColor: EzoColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirm Udhaar (+ Add)'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(PartyAccount customer) {
    final amtCtrl = TextEditingController(text: customer.netBalance > 0 ? customer.netBalance.toStringAsFixed(0) : '500');
    final noteCtrl = TextEditingController();
    String mode = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(LucideIcons.arrowDownLeft, color: EzoColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Record Payment (- Jama): ${customer.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid (₹) *', prefixIcon: Icon(LucideIcons.indianRupee, size: 16)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI / QR')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer / NEFT')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (val) => setDialogState(() => mode = val ?? 'cash'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Payment Note / Reference ID (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EzoColors.success, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text) ?? 0.0;
                if (amt > 0) {
                  final receiptMsg = await _khataService.recordCustomerPayment(
                    customerId: customer.id,
                    amount: amt,
                    paymentMode: mode,
                    storeProfile: widget.storeProfile,
                    cashier: widget.cashier,
                    notes: noteCtrl.text.trim(),
                  );
                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Received ₹${amt.toStringAsFixed(2)} payment from ${customer.name}!'),
                        backgroundColor: EzoColors.success,
                        action: SnackBarAction(
                          label: 'WhatsApp Slip',
                          textColor: Colors.white,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: receiptMsg));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receipt message copied to clipboard!')),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save & Issue Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendWhatsAppReminder(PartyAccount customer) {
    final reminderMsg = WhatsAppReminderBuilder.buildReminderText(
      customer: customer,
      storeProfile: widget.storeProfile,
    );
    final waMeLink = WhatsAppReminderBuilder.buildWaMeLink(
      customer: customer,
      storeProfile: widget.storeProfile,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(LucideIcons.messageSquare, color: EzoColors.whatsapp, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('WhatsApp Reminder: ${customer.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personalized Reminder Message Preview:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: SelectableText(reminderMsg, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF14532D), height: 1.35)),
              ),
              const SizedBox(height: 10),
              Text('1-Tap wa.me Link:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11, color: EzoColors.textMuted)),
              const SizedBox(height: 3),
              SelectableText(
                waMeLink,
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF2563EB)),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.copy, size: 14),
            label: const Text('Copy Text'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reminderMsg));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WhatsApp reminder message copied to clipboard!')),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: EzoColors.whatsapp, foregroundColor: Colors.white),
            icon: const Icon(LucideIcons.send, size: 14),
            label: const Text('Launch WhatsApp'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reminderMsg));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Launched WhatsApp reminder for ${customer.name} (${customer.phone})'),
                  backgroundColor: EzoColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddPartyDialog(BuildContext context, {PartyType defaultType = PartyType.customer}) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final openingBalCtrl = TextEditingController(text: '0');
    PartyType type = defaultType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(type == PartyType.customer ? 'Add New Customer' : 'Add New Supplier', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Customer'),
                      selected: type == PartyType.customer,
                      onSelected: (s) => setDialogState(() => type = PartyType.customer),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Supplier'),
                      selected: type == PartyType.supplier,
                      onSelected: (s) => setDialogState(() => type = PartyType.supplier),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Party / Full Name *')),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone *')),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address / Area')),
                const SizedBox(height: 8),
                TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)')),
                const SizedBox(height: 8),
                TextField(
                  controller: openingBalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: type == PartyType.customer ? 'Opening Udhaar Balance (₹)' : 'Opening Payable Balance (₹)',
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
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a party name')));
                  return;
                }

                final opening = double.tryParse(openingBalCtrl.text) ?? 0.0;
                final partyId = 'party_${DateTime.now().millisecondsSinceEpoch}';

                final newParty = PartyAccount(
                  id: partyId,
                  name: name,
                  phone: phone,
                  address: addressCtrl.text.trim(),
                  gstin: gstinCtrl.text.trim(),
                  partyType: type,
                );

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);

                await widget.repository.saveParty(newParty);

                if (opening > 0) {
                  final initialEntry = KhataLedgerEntry(
                    id: 'init_${DateTime.now().millisecondsSinceEpoch}',
                    partyId: partyId,
                    entryDate: DateTime.now(),
                    debitYouGave: type == PartyType.customer ? opening : 0.0,
                    creditYouGot: type == PartyType.customer ? 0.0 : opening,
                    paymentMode: 'opening_balance',
                    collectedByStaffId: widget.cashier.id,
                    collectedByStaffName: widget.cashier.fullName,
                    notes: 'Opening Khata Balance',
                    createdAt: DateTime.now(),
                  );
                  await widget.repository.db.addKhataEntry(initialEntry);
                }

                if (mounted) {
                  setState(() {});
                }
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Added "$name" to Khata ledger!')),
                );
              },
              child: const Text('Save to Khata'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteParty(BuildContext sheetContext, PartyAccount party) {
    showDialog(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Party from Khata?'),
        content: Text('Are you sure you want to remove ${party.name}? All ledger transaction history will be erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EzoColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx); // pop confirm
              Navigator.pop(sheetContext); // pop modal
              await widget.repository.deleteParty(party.id);
              if (mounted) {
                setState(() {});
              }
              messenger.showSnackBar(
                SnackBar(content: Text('Removed ${party.name} from Khata')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
