import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import '../theme/ezo_theme.dart';

class ReportsHubScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final StaffMember? cashier;

  const ReportsHubScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
    this.cashier,
  });

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _salesPeriodFilter = 'all'; // 'all', 'today', 'month'
  final TextEditingController _invoiceSearchCtrl = TextEditingController();
  final TextEditingController _cashCountCtrl = TextEditingController(text: '19150');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _invoiceSearchCtrl.dispose();
    _cashCountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EzoColors.background,
      body: Column(
        children: [
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: EzoColors.surface,
              border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: EzoColors.primary,
              unselectedLabelColor: EzoColors.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorColor: EzoColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Daily Sales (बिक्री)'),
                Tab(text: 'GST Tax Report (3B)'),
                Tab(text: 'HSN Summary'),
                Tab(text: 'Profit & Loss'),
                Tab(text: 'Day-End Cash Drawer'),
                Tab(text: 'Stock & Ageing'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDailySalesTab(),
                _buildGstTab(),
                _buildHsnSummaryTab(),
                _buildPnlTab(),
                _buildDayEndCashDrawerTab(),
                _buildStockAndAgeingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesTab() {
    final now = DateTime.now();
    final allInvoices = widget.repository.getAllInvoices();
    final searchQuery = _invoiceSearchCtrl.text.trim().toLowerCase();

    // Filter by period
    final periodInvoices = allInvoices.where((inv) {
      if (inv.isCancelled) return false;
      if (_salesPeriodFilter == 'today') {
        return inv.invoiceDate.year == now.year &&
            inv.invoiceDate.month == now.month &&
            inv.invoiceDate.day == now.day;
      } else if (_salesPeriodFilter == 'month') {
        return inv.invoiceDate.year == now.year &&
            inv.invoiceDate.month == now.month;
      }
      return true;
    }).toList();

    // Filter by search query
    final displayInvoices = periodInvoices.where((inv) {
      if (searchQuery.isEmpty) return true;
      return inv.invoiceNumber.toLowerCase().contains(searchQuery) ||
          inv.partyName.toLowerCase().contains(searchQuery) ||
          inv.partyPhone.contains(searchQuery);
    }).toList();

    // Sort newest first
    displayInvoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    // KPI Calculations
    double grossRevenue = 0.0;
    double cashCollected = 0.0;
    double upiCollected = 0.0;
    double udhaarIssued = 0.0;
    double totalTax = 0.0;

    for (final inv in periodInvoices) {
      grossRevenue += inv.grandTotal;
      if (inv.settlementMode == SettlementMode.cash) {
        cashCollected += inv.amountReceived;
      } else if (inv.settlementMode == SettlementMode.upiQr) {
        upiCollected += inv.amountReceived;
      } else if (inv.settlementMode == SettlementMode.creditUdhaar) {
        udhaarIssued += inv.balanceUdhaarDue;
      }
      totalTax += (inv.totalCgst + inv.totalSgst + inv.totalIgst);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row & Search
          Row(
            children: [
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('All Time'),
                    selected: _salesPeriodFilter == 'all',
                    onSelected: (s) => setState(() => _salesPeriodFilter = 'all'),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _salesPeriodFilter == 'all' ? Colors.white : EzoColors.textSecondary,
                    ),
                    selectedColor: EzoColors.primary,
                  ),
                  ChoiceChip(
                    label: const Text('Today (आज)'),
                    selected: _salesPeriodFilter == 'today',
                    onSelected: (s) => setState(() => _salesPeriodFilter = 'today'),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _salesPeriodFilter == 'today' ? Colors.white : EzoColors.textSecondary,
                    ),
                    selectedColor: EzoColors.primary,
                  ),
                  ChoiceChip(
                    label: const Text('This Month'),
                    selected: _salesPeriodFilter == 'month',
                    onSelected: (s) => setState(() => _salesPeriodFilter = 'month'),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _salesPeriodFilter == 'month' ? Colors.white : EzoColors.textSecondary,
                    ),
                    selectedColor: EzoColors.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar with Clear Button
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(LucideIcons.search, size: 15, color: EzoColors.textMuted),
                ),
                Expanded(
                  child: TextField(
                    controller: _invoiceSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EzoColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search invoices by Bill #, customer name, phone...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_invoiceSearchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 14, color: EzoColors.textMuted),
                    onPressed: () {
                      _invoiceSearchCtrl.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary KPI Cards Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSalesKpiCard(
                'Gross Revenue',
                '₹${grossRevenue.toStringAsFixed(2)}',
                LucideIcons.indianRupee,
                EzoColors.primary,
                EzoColors.primaryLight,
              ),
              _buildSalesKpiCard(
                'Bills Issued',
                '${periodInvoices.length}',
                LucideIcons.receipt,
                EzoColors.textPrimary,
                EzoColors.surfaceSecondary,
              ),
              _buildSalesKpiCard(
                'Cash Received',
                '₹${cashCollected.toStringAsFixed(2)}',
                LucideIcons.banknote,
                EzoColors.success,
                EzoColors.successBg,
              ),
              _buildSalesKpiCard(
                'UPI / QR Sales',
                '₹${upiCollected.toStringAsFixed(2)}',
                LucideIcons.qrCode,
                EzoColors.primary,
                const Color(0xFFEFF6FF),
              ),
              _buildSalesKpiCard(
                'Udhaar (Credit)',
                '₹${udhaarIssued.toStringAsFixed(2)}',
                LucideIcons.bookOpen,
                EzoColors.warning,
                const Color(0xFFFEF3C7),
              ),
              _buildSalesKpiCard(
                'GST Tax Collected',
                '₹${totalTax.toStringAsFixed(2)}',
                LucideIcons.fileSpreadsheet,
                Colors.purple,
                const Color(0xFFF3E8FF),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Invoice List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Invoices & Receipts (${displayInvoices.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: EzoColors.textPrimary,
                ),
              ),
              Text(
                'Tap bill to inspect & reprint',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: EzoColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Invoice Cards List
          if (displayInvoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: EzoColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EzoColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(LucideIcons.receipt, size: 36, color: EzoColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No invoices found for this selection',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EzoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayInvoices.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final inv = displayInvoices[idx];
                final dateStr =
                    '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')} ${inv.invoiceDate.hour.toString().padLeft(2, '0')}:${inv.invoiceDate.minute.toString().padLeft(2, '0')}';

                Color badgeBg = EzoColors.successBg;
                Color badgeColor = EzoColors.success;
                String badgeText = 'CASH';

                if (inv.settlementMode == SettlementMode.upiQr) {
                  badgeBg = const Color(0xFFEFF6FF);
                  badgeColor = EzoColors.primary;
                  badgeText = 'UPI';
                } else if (inv.settlementMode == SettlementMode.creditUdhaar) {
                  badgeBg = const Color(0xFFFEF3C7);
                  badgeColor = EzoColors.warning;
                  badgeText = 'UDHAAR';
                } else if (inv.settlementMode == SettlementMode.cardBank) {
                  badgeBg = const Color(0xFFF3E8FF);
                  badgeColor = Colors.purple;
                  badgeText = 'CARD';
                }

                return InkWell(
                  onTap: () => _showInvoiceDetailModal(inv),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EzoColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EzoColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Bill # + Date + Mode Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  inv.invoiceNumber,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: EzoColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: EzoColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Customer Name + Items Count + Grand Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                inv.partyName.isNotEmpty ? inv.partyName : 'Cash Customer (Walk-in)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '₹${inv.grandTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: EzoColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Row 3: Items Count, Tax, Billed By
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${inv.lineItems.length} items  •  GST: ₹${(inv.totalCgst + inv.totalSgst + inv.totalIgst).toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: EzoColors.textMuted,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'By: ${inv.cashierStaffName}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: EzoColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.chevronRight, size: 13, color: EzoColors.textMuted),
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
        ],
      ),
    );
  }

  Widget _buildSalesKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      width: 170,
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
          const SizedBox(width: 10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: EzoColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetailModal(InvoiceDocument inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 14),

              // Store Header
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.storeProfile.storeName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (widget.storeProfile.address.isNotEmpty)
                      Text(
                        widget.storeProfile.address,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                      ),
                    if (widget.storeProfile.gstin.isNotEmpty)
                      Text(
                        'GSTIN: ${widget.storeProfile.gstin}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EzoColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: EzoColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: EzoColors.border),
                      ),
                      child: Text(
                        'TAX INVOICE / RETAIL RECEIPT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),

              // Metadata Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice: ${inv.invoiceNumber}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        'Date: ${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year} ${inv.invoiceDate.hour}:${inv.invoiceDate.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                      ),
                      Text(
                        'Cashier: ${inv.cashierStaffName}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Customer: ${inv.partyName.isNotEmpty ? inv.partyName : 'Cash Customer'}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      if (inv.partyPhone.isNotEmpty)
                        Text(
                          'Phone: ${inv.partyPhone}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                        ),
                      if (inv.partyGstin.isNotEmpty)
                        Text(
                          'GSTIN: ${inv.partyGstin}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EzoColors.primary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),

              // Items Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.8),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: EzoColors.surfaceSecondary),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('Item', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('Qty', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('Rate', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('Total', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  for (final item in inv.lineItems)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(item.itemName, style: GoogleFonts.plusJakartaSans(fontSize: 11.5)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(item.quantity.toStringAsFixed(0), textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 11.5)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('₹${item.unitSellingPrice.toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11.5)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('₹${item.totalAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(),

              // Financial Totals
              _buildReceiptRow('Taxable Subtotal', '₹${inv.taxableSubtotal.toStringAsFixed(2)}'),
              if (inv.totalCgst > 0)
                _buildReceiptRow('Central GST (CGST)', '₹${inv.totalCgst.toStringAsFixed(2)}'),
              if (inv.totalSgst > 0)
                _buildReceiptRow('State GST (SGST)', '₹${inv.totalSgst.toStringAsFixed(2)}'),
              if (inv.totalIgst > 0)
                _buildReceiptRow('Integrated GST (IGST)', '₹${inv.totalIgst.toStringAsFixed(2)}'),
              if (inv.billDiscountAmount > 0)
                _buildReceiptRow('Discount', '- ₹${inv.billDiscountAmount.toStringAsFixed(2)}', color: EzoColors.error),
              const Divider(),
              _buildReceiptRow('Grand Total', '₹${inv.grandTotal.toStringAsFixed(2)}', isBold: true, fontSize: 15),
              _buildReceiptRow('Amount Settled (${inv.settlementMode.name.toUpperCase()})', '₹${inv.amountReceived.toStringAsFixed(2)}', color: EzoColors.success),
              if (inv.balanceUdhaarDue > 0)
                _buildReceiptRow('Udhaar Balance Due', '₹${inv.balanceUdhaarDue.toStringAsFixed(2)}', color: EzoColors.warning, isBold: true),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.printer, size: 16),
                      label: const Text('Reprint Thermal Slip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        // Build and dispatch ESC/POS stream to active printer
                        final bytes = EscPosThermalEngine.buildInvoiceByteStream(
                          invoice: inv,
                          storeProfile: widget.storeProfile,
                          rollWidth: ThermalRollWidth.chota58mm,
                        );
                        await ThermalPrinterConnectionManager().printBytes(bytes);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🖨️ Thermal receipt dispatched for ${inv.invoiceNumber}'),
                              backgroundColor: EzoColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.copy, size: 15),
                    label: const Text('Copy Slip'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                    onPressed: () {
                      final asciiSlip = EscPosThermalEngine.renderReceiptAsciiPreview(
                        invoice: inv,
                        storeProfile: widget.storeProfile,
                      );
                      Clipboard.setData(ClipboardData(text: asciiSlip));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thermal receipt text copied to clipboard!')),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  if (widget.cashier?.canDeleteBills ?? true)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: EzoColors.error),
                      tooltip: 'Void / Cancel Invoice',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Cancel this Invoice?'),
                          content: Text('Are you sure you want to void ${inv.invoiceNumber}? Stock quantities will be restored.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: EzoColors.error),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Void Bill'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.repository.cancelInvoice(inv.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color, bool isBold = false, double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? EzoColors.textPrimary : EzoColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isBold ? EzoColors.textPrimary : EzoColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstTab() {
    final invoices = widget.repository.getAllInvoices().where((i) => !i.isCancelled).toList();
    final gstr3b = EzoReportEngine.generateGstr3bSummary(salesInvoices: invoices, purchaseInvoices: []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GSTR-3B Tax Summary Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.fileSpreadsheet, size: 18, color: EzoColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'GSTR-3B Monthly Statutory Tax Return',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.download, size: 12),
                      label: const Text('Export JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.surfaceSecondary,
                        foregroundColor: EzoColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(color: EzoColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exported GSTR-3B payload format for GST Portal')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTaxTile('Outward Supplies (Taxable)', '₹${gstr3b.outwardTaxableSupplies.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    _buildTaxTile('Net CGST', '₹${gstr3b.netCgstPayable.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTaxTile('Net SGST', '₹${gstr3b.netSgstPayable.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    _buildTaxTile('Total Net Tax Payable', '₹${gstr3b.totalNetTaxPayable.toStringAsFixed(2)}', isPrimary: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GSTR-1 Invoices Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GSTR-1 Outward Supplies Overview',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                ),
                const SizedBox(height: 10),
                _buildReceiptRow('Total B2C Small Invoices', '${invoices.where((i) => i.partyGstin.isEmpty).length} bills'),
                _buildReceiptRow('Total B2B Invoices', '${invoices.where((i) => i.partyGstin.isNotEmpty).length} bills'),
                _buildReceiptRow('Total GST Collected', '₹${gstr3b.totalNetTaxPayable.toStringAsFixed(2)}', isBold: true, color: EzoColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHsnSummaryTab() {
    final invoices = widget.repository.getAllInvoices().where((i) => !i.isCancelled).toList();
    final products = {for (var p in widget.repository.getAllProducts()) p.id: p};
    final hsnRows = EzoReportEngine.generateGstr1HsnSummary(invoices, products);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GSTR-1 HSN / SAC Code Summary (${hsnRows.length})',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.download, size: 13),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EzoColors.surfaceSecondary,
                  foregroundColor: EzoColors.textPrimary,
                  elevation: 0,
                  side: const BorderSide(color: EzoColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  final csv = EzoReportEngine.exportToCsv(
                    headers: ['HSN Code', 'Description', 'Qty', 'Taxable Value', 'CGST', 'SGST', 'Total Value'],
                    rows: hsnRows.map((r) => [r.hsnSacCode, r.description, r.totalQuantity, r.taxableValue, r.centralTaxAmount, r.stateTaxAmount, r.totalValue]).toList(),
                  );
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exported GSTR-1 HSN CSV (${csv.length} bytes) to clipboard!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textPrimary),
                dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textSecondary),
                columns: const [
                  DataColumn(label: Text('HSN/SAC')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Total Qty')),
                  DataColumn(label: Text('Taxable Value')),
                  DataColumn(label: Text('CGST')),
                  DataColumn(label: Text('SGST')),
                  DataColumn(label: Text('Total Value')),
                ],
                rows: hsnRows.map((r) {
                  return DataRow(cells: [
                    DataCell(Text(r.hsnSacCode)),
                    DataCell(Text(r.description)),
                    DataCell(Text('${r.totalQuantity}')),
                    DataCell(Text('₹${r.taxableValue.toStringAsFixed(2)}')),
                    DataCell(Text('₹${r.centralTaxAmount.toStringAsFixed(2)}')),
                    DataCell(Text('₹${r.stateTaxAmount.toStringAsFixed(2)}')),
                    DataCell(Text('₹${r.totalValue.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxTile(String label, String value, {bool isPrimary = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? EzoColors.primaryLight : EzoColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPrimary ? EzoColors.primary.withValues(alpha: 0.3) : EzoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EzoColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isPrimary ? EzoColors.primary : EzoColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPnlTab() {
    final canViewProfit = widget.cashier?.canViewProfitReports ?? true;
    if (!canViewProfit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: EzoColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lock, color: EzoColors.warning, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Profit & Loss Reports Restricted',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Your staff role (\) does not have permission to view store margins and profit data.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    final now = DateTime.now();
    final pnl = EzoReportEngine.generateProfitAndLoss(
      sales: widget.repository.getAllInvoices().where((i) => !i.isCancelled).toList(),
      productsMap: {for (var p in widget.repository.getAllProducts()) p.id: p},
      totalExpenses: 2500.0,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 1)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EzoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EzoColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profit & Loss Statement (Last 30 Days)', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary)),
                IconButton(
                  icon: const Icon(LucideIcons.download, size: 16),
                  tooltip: 'Export P&L Summary',
                  onPressed: () {
                    final report = 'P&L Statement: Gross Sales ₹${pnl.grossRevenue}, Net Profit ₹${pnl.netProfit} (${pnl.netMarginPercent.toStringAsFixed(1)}%)';
                    Clipboard.setData(ClipboardData(text: report));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('P&L report copied to clipboard!')));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            _buildPnlRow('Gross Revenue (Sales)', '₹${pnl.grossRevenue.toStringAsFixed(2)}', EzoColors.textPrimary),
            _buildPnlRow('Cost of Goods Sold (COGS)', '- ₹${pnl.costOfGoodsSold.toStringAsFixed(2)}', EzoColors.error),
            const Divider(height: 16),
            _buildPnlRow('Gross Profit (Margin: ${pnl.grossMarginPercent.toStringAsFixed(1)}%)', '₹${pnl.grossProfit.toStringAsFixed(2)}', EzoColors.primary, isBold: true),
            _buildPnlRow('Operating Expenses', '- ₹${pnl.operatingExpenses.toStringAsFixed(2)}', EzoColors.error),
            const Divider(height: 16),
            _buildPnlRow('Net Profit (Margin: ${pnl.netMarginPercent.toStringAsFixed(1)}%)', '₹${pnl.netProfit.toStringAsFixed(2)}', EzoColors.success, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEndCashDrawerTab() {
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
                'Day-End Cash Drawer Reconciliation',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.checkCheck, size: 14),
                label: const Text('Reconcile & Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EzoColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Day-end cash drawer closed with counted cash ₹${recon.actualCountedCash.toStringAsFixed(2)}'),
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
                _buildReceiptRow('Opening Float', '₹${recon.openingCash.toStringAsFixed(2)}'),
                _buildReceiptRow('Cash Sales Today', '+ ₹${recon.cashSales.toStringAsFixed(2)}', color: EzoColors.success),
                _buildReceiptRow('Cash Udhaar Collected', '+ ₹${recon.cashUdhaarCollections.toStringAsFixed(2)}', color: EzoColors.success),
                _buildReceiptRow('Cash Expenses Paid', '- ₹${recon.cashExpenses.toStringAsFixed(2)}', color: EzoColors.error),
                const Divider(height: 16),
                _buildReceiptRow('Expected Cash in Drawer', '₹${recon.expectedCashInDrawer.toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Counted Cash In Till:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
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

  Widget _buildStockAndAgeingTab() {
    final summary = EzoReportEngine.generateStockValuation(widget.repository.getAllProducts());
    final ageing = EzoReportEngine.generateCustomerAgeingReport(widget.repository.getCustomerParties());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Valuation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock Inventory Valuation', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary)),
                const Divider(height: 20),
                _buildPnlRow('Total SKUs Tracked', '${summary.totalSkus}', EzoColors.textPrimary),
                _buildPnlRow('Total Quantity in Stock', '${summary.totalQuantity.toInt()} units', EzoColors.textPrimary),
                _buildPnlRow('Stock Asset Value (Cost)', '₹${summary.totalAssetValueAtCost.toStringAsFixed(2)}', EzoColors.success, isBold: true),
                _buildPnlRow('Stock Retail Value', '₹${summary.totalRetailValue.toStringAsFixed(2)}', const Color(0xFF7C3AED), isBold: true),
                const Divider(height: 16),
                _buildPnlRow('Potential Unrealized Profit', '₹${summary.potentialGrossProfit.toStringAsFixed(2)}', EzoColors.primary, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Customer Ageing
          Text('Customer Udhaar Ageing Analysis', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: EzoColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EzoColors.border, width: 1),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: EzoColors.textPrimary),
                dataTextStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textSecondary),
                columns: const [
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Total Due (₹)')),
                  DataColumn(label: Text('0 - 30 Days')),
                  DataColumn(label: Text('31 - 60 Days')),
                  DataColumn(label: Text('61 - 90 Days')),
                  DataColumn(label: Text('90+ Days')),
                ],
                rows: ageing.map((a) {
                  return DataRow(cells: [
                    DataCell(Text(a.customerName)),
                    DataCell(Text('₹${a.totalDue}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: EzoColors.error))),
                    DataCell(Text('₹${a.days0To30}')),
                    DataCell(Text('₹${a.days31To60}')),
                    DataCell(Text('₹${a.days61To90}')),
                    DataCell(Text('₹${a.days90Plus}', style: GoogleFonts.plusJakartaSans(color: a.days90Plus > 0 ? EzoColors.error : EzoColors.textSecondary))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnlRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
