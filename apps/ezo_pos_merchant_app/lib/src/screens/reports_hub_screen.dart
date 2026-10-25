import 'package:flutter/material.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import '../theme/ezo_theme.dart';

class ReportsHubScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;

  const ReportsHubScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
  });

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
              labelColor: EzoColors.primary,
              unselectedLabelColor: EzoColors.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorColor: EzoColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'GST Statutory'),
                Tab(text: 'P&L Financial'),
                Tab(text: 'Stock Value'),
                Tab(text: 'Ageing'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildGstTab(),
                _buildPnlTab(),
                _buildStockValuationTab(),
                _buildAgeingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstTab() {
    final invoices = widget.repository.getAllInvoices();
    final products = {for (var p in widget.repository.getAllProducts()) p.id: p};
    final hsnRows = EzoReportEngine.generateGstr1HsnSummary(invoices, products);
    final gstr3b = EzoReportEngine.generateGstr3bSummary(salesInvoices: invoices, purchaseInvoices: []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GSTR-3B Tax Summary Container
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
                Row(
                  children: [
                    const Icon(LucideIcons.fileSpreadsheet, size: 16, color: EzoColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'GSTR-3B Monthly Tax Liability Summary',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: EzoColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTaxTile('Outward Supplies', '₹${gstr3b.outwardTaxableSupplies.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    _buildTaxTile('Net CGST', '₹${gstr3b.netCgstPayable.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTaxTile('Net SGST', '₹${gstr3b.netSgstPayable.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    _buildTaxTile('Total Net Tax', '₹${gstr3b.totalNetTaxPayable.toStringAsFixed(2)}', isPrimary: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GSTR-1 HSN Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GSTR-1 HSN Summary',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exported GSTR-1 HSN CSV (${csv.length} bytes)')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

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
    final now = DateTime.now();
    final pnl = EzoReportEngine.generateProfitAndLoss(
      sales: widget.repository.getAllInvoices(),
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
            Text('Profit & Loss Statement (Last 30 Days)', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EzoColors.textPrimary)),
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

  Widget _buildStockValuationTab() {
    final summary = EzoReportEngine.generateStockValuation(widget.repository.getAllProducts());

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
    );
  }

  Widget _buildAgeingTab() {
    final ageing = EzoReportEngine.generateCustomerAgeingReport(widget.repository.getCustomerParties());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
