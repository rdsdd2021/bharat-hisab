import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _khataService = EzoKhataService(repository: widget.repository);
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
                  'Total You Will Get',
                  '₹${totalReceivables.toStringAsFixed(2)}',
                  LucideIcons.arrowDownLeft,
                  EzoColors.success,
                  EzoColors.successBg,
                ),
                const SizedBox(width: 8),
                _buildKhataKpiCard(
                  'Total You Will Give',
                  '₹${totalPayables.toStringAsFixed(2)}',
                  LucideIcons.arrowUpRight,
                  EzoColors.error,
                  EzoColors.errorBg,
                ),
              ],
            ),
          ),

          // Sub-Tabs
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

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCustomersList(customers),
                _buildSuppliersList(suppliers),
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
                      fontSize: 11,
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

  Widget _buildCustomersList(List<PartyAccount> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Text(
          'No customers in Khata yet.',
          style: GoogleFonts.plusJakartaSans(color: EzoColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final c = customers[idx];
        final isDue = c.isPaymentDueTodayOrOverdue;

        return Container(
          color: EzoColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDue ? EzoColors.errorBg : EzoColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    c.name.isNotEmpty ? c.name[0] : 'C',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDue ? EzoColors.error : EzoColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                      InkWell(
                        onTap: () => _sendWhatsAppReminder(c),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(LucideIcons.messageSquare, color: EzoColors.whatsapp, size: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EzoColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _showRecordPaymentDialog(c),
                        child: const Text('Got Pay'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuppliersList(List<PartyAccount> suppliers) {
    if (suppliers.isEmpty) {
      return Center(
        child: Text(
          'No suppliers in Khata yet.',
          style: GoogleFonts.plusJakartaSans(color: EzoColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final s = suppliers[idx];
        return Container(
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
              Text(
                '₹${s.netBalance.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: EzoColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashDrawerTab() {
    const recon = CashDrawerReconciliation(
      openingCash: 5000.0,
      cashSales: 12450.0,
      cashUdhaarCollections: 2500.0,
      cashExpenses: 800.0,
      actualCountedCash: 19150.0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Cash Drawer Reconciliation',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
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
                _buildReconRow('Cash Udhaar Collected', '+ ₹${recon.cashUdhaarCollections.toStringAsFixed(2)}', color: EzoColors.success),
                _buildReconRow('Cash Expenses Paid', '- ₹${recon.cashExpenses.toStringAsFixed(2)}', color: EzoColors.error),
                const Divider(height: 16),
                _buildReconRow('Expected Cash in Drawer', '₹${recon.expectedCashInDrawer.toStringAsFixed(2)}', isBold: true),
                _buildReconRow('Actual Counted Cash', '₹${recon.actualCountedCash.toStringAsFixed(2)}', isBold: true),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Drawer Status:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: EzoColors.successBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        'BALANCED (₹0.00 Diff)',
                        style: GoogleFonts.plusJakartaSans(color: EzoColors.success, fontWeight: FontWeight.w800, fontSize: 11),
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

  void _sendWhatsAppReminder(PartyAccount customer) {
    final reminderMsg = WhatsAppReminderBuilder.buildReminderText(
      customer: customer,
      storeProfile: widget.storeProfile,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('WhatsApp Reminder for ${customer.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(child: SelectableText(reminderMsg, style: GoogleFonts.plusJakartaSans(fontSize: 12))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: EzoColors.whatsapp, foregroundColor: Colors.white),
            icon: const Icon(LucideIcons.send, size: 14),
            label: const Text('Launch WhatsApp'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Launched WhatsApp reminder for ${customer.phone}')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(PartyAccount customer) {
    final amtCtrl = TextEditingController(text: customer.netBalance.toStringAsFixed(0));
    String mode = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Record Payment - ${customer.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI / QR')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer / NEFT')),
                ],
                onChanged: (val) => setDialogState(() => mode = val ?? 'cash'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text) ?? 0.0;
                if (amt > 0) {
                  await _khataService.recordCustomerPayment(
                    customerId: customer.id,
                    amount: amt,
                    paymentMode: mode,
                    storeProfile: widget.storeProfile,
                    cashier: widget.cashier,
                  );
                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save & Issue Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    PartyType type = PartyType.customer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Add Party to Khata', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Party / Customer Name')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  final newParty = PartyAccount(
                    id: 'party_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    partyType: type,
                  );
                  await widget.repository.saveParty(newParty);
                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add to Khata'),
            ),
          ],
        ),
      ),
    );
  }
}
