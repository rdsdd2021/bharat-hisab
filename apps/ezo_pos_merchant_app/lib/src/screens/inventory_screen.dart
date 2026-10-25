import 'package:flutter/material.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import '../theme/ezo_theme.dart';

class InventoryScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;

  const InventoryScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final BulkInventoryEditor _bulkEditor = BulkInventoryEditor();
  StockHealthFilter _activeFilter = StockHealthFilter.all;
  String _searchQuery = '';
  bool _isBulkSaving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadBulkEditor();
  }

  void _loadBulkEditor() {
    _bulkEditor.loadProducts(widget.repository.getAllProducts());
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.repository.getAllProducts();
    final lowStockCount = products.where((p) => p.isLowStock).length;
    final totalCostValue = products.fold(0.0, (sum, p) => sum + p.stockAssetValueAtCost);
    final totalRetailValue = products.fold(0.0, (sum, p) => sum + p.stockRetailValue);

    return Scaffold(
      backgroundColor: EzoColors.background,
      body: Column(
        children: [
          // 2x2 KPI Dashboard Cards Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: EzoColors.surface,
              border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKpiCard('Total SKUs', '${products.length}', LucideIcons.boxes, EzoColors.primary, EzoColors.primaryLight),
                    const SizedBox(width: 8),
                    _buildKpiCard('Cost Valuation', '₹${totalCostValue.toStringAsFixed(0)}', LucideIcons.wallet, EzoColors.success, EzoColors.successBg),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildKpiCard('Retail Valuation', '₹${totalRetailValue.toStringAsFixed(0)}', LucideIcons.store, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
                    const SizedBox(width: 8),
                    _buildKpiCard('Low Stock Alerts', '$lowStockCount Items', LucideIcons.alertTriangle, EzoColors.warning, EzoColors.warningBg),
                  ],
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
              tabs: const [
                Tab(text: 'Item Catalog'),
                Tab(text: 'Bulk Edit Grid'),
                Tab(text: 'Barcode Stickers'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCatalogTab(products),
                _buildBulkEditTab(),
                _buildBarcodeStickersTab(products),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EzoColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(LucideIcons.plus, size: 16),
        label: Text('Add Product', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        onPressed: () => _showAddProductDialog(context),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EzoColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EzoColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bg,
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
                      color: EzoColors.textMuted,
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildCatalogTab(List<ProductItem> allProducts) {
    var filtered = allProducts;
    if (_activeFilter == StockHealthFilter.lowStock) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    } else if (_activeFilter == StockHealthFilter.outOfStock) {
      filtered = filtered.where((p) => p.isOutOfStock).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q) || p.skuCode.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        // Search & Filter Strip
        Container(
          padding: const EdgeInsets.all(10),
          color: EzoColors.surface,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: EzoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EzoColors.border, width: 1),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: EzoColors.textMuted),
                    hintText: 'Search catalog by SKU or item name...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFilterPill('All (${allProducts.length})', _activeFilter == StockHealthFilter.all, () {
                    setState(() => _activeFilter = StockHealthFilter.all);
                  }),
                  const SizedBox(width: 6),
                  _buildFilterPill('Low Stock', _activeFilter == StockHealthFilter.lowStock, () {
                    setState(() => _activeFilter = StockHealthFilter.lowStock);
                  }),
                  const SizedBox(width: 6),
                  _buildFilterPill('Out of Stock', _activeFilter == StockHealthFilter.outOfStock, () {
                    setState(() => _activeFilter = StockHealthFilter.outOfStock);
                  }),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Product List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = filtered[idx];
              return Container(
                color: EzoColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          p.category.isNotEmpty ? p.category[0] : 'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: EzoColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: EzoColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${p.skuCode} • HSN: ${p.hsnSacCode} • GST: ${p.gstPercent}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: EzoColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${p.sellingPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: EzoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: p.isOutOfStock
                                ? EzoColors.errorBg
                                : (p.isLowStock ? EzoColors.warningBg : EzoColors.successBg),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${p.currentStock.toInt()} ${p.unit.name.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.isOutOfStock
                                  ? EzoColors.error
                                  : (p.isLowStock ? EzoColors.warning : EzoColors.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? EzoColors.primary : EzoColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? EzoColors.primary : EzoColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : EzoColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBulkEditTab() {
    return Column(
      children: [
        // Action Bar for Bulk Editor
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFFFFFBEB),
          child: Row(
            children: [
              const Icon(LucideIcons.zap, color: EzoColors.warning, size: 16),
              const SizedBox(width: 8),
              Text(
                'Spreadsheet Grid',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.percent, size: 13),
                label: const Text('+10% Markup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EzoColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  setState(() {
                    _bulkEditor.applyMarkupPercentage(percentage: 10.0);
                  });
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EzoColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                icon: _isBulkSaving
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.save, size: 13),
                label: const Text('Save Bulk'),
                onPressed: _isBulkSaving ? null : _handleCommitBulk,
              ),
            ],
          ),
        ),
        // Spreadsheet Grid Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item Name')),
                  DataColumn(label: Text('SKU Code')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Selling Price (₹)')),
                  DataColumn(label: Text('MRP (₹)')),
                  DataColumn(label: Text('Purchase Cost (₹)')),
                  DataColumn(label: Text('Current Stock')),
                  DataColumn(label: Text('GST %')),
                ],
                rows: _bulkEditor.drafts.map((draft) {
                  return DataRow(
                    color: draft.isModified ? WidgetStateProperty.all(const Color(0xFFFEF3C7)) : null,
                    cells: [
                      DataCell(Text(draft.name)),
                      DataCell(Text(draft.skuCode)),
                      DataCell(Text(draft.category)),
                      DataCell(
                        TextFormField(
                          initialValue: draft.sellingPrice.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() => draft.sellingPrice = parsed);
                              draft.isModified = true;
                            }
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: draft.mrp.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() => draft.mrp = parsed);
                              draft.isModified = true;
                            }
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: draft.purchasePrice.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() => draft.purchasePrice = parsed);
                              draft.isModified = true;
                            }
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: draft.currentStock.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              setState(() => draft.currentStock = parsed);
                              draft.isModified = true;
                            }
                          },
                        ),
                      ),
                      DataCell(Text('${draft.gstPercent}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeStickersTab(List<ProductItem> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, idx) {
        final p = products[idx];
        final discountPercent = p.discountPercent.round();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EzoColors.border, width: 1),
          ),
          child: Row(
            children: [
              // Simulated Adhesive Barcode Sticker Box
              Container(
                width: 200,
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: EzoColors.border, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.storeProfile.storeName, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 8)),
                    const SizedBox(height: 3),
                    // Barcode Graphic bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        18,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: i % 3 == 0 ? 2.5 : 1.2,
                          height: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(p.barcode.isNotEmpty ? p.barcode : p.skuCode, style: GoogleFonts.jetBrainsMono(fontSize: 7.5, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    // Promotional Discount Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        discountPercent > 0
                            ? 'MRP ₹${p.mrp.toInt()} | SAVE $discountPercent%'
                            : 'PRICE: ₹${p.sellingPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 7.5, fontWeight: FontWeight.bold, color: EzoColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Barcode: ${p.barcode.isNotEmpty ? p.barcode : p.skuCode}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.printer, size: 13),
                      label: const Text('Print Sticker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dispatched barcode sticker for ${p.name} to ESC/POS printer')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCommitBulk() async {
    setState(() => _isBulkSaving = true);
    final modified = _bulkEditor.drafts.where((d) => d.isModified).toList();
    for (final draft in modified) {
      final orig = widget.repository.getProduct(draft.productId);
      if (orig != null) {
        final updated = orig.copyWith(
          mrp: draft.mrp,
          sellingPrice: draft.sellingPrice,
          wholesalePrice: draft.wholesalePrice,
          purchasePrice: draft.purchasePrice,
          currentStock: draft.currentStock,
        );
        await widget.repository.upsertProduct(updated);
      }
    }
    setState(() {
      _isBulkSaving = false;
      _loadBulkEditor();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Committed ${modified.length} bulk item updates to local storage')),
      );
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final hsnCtrl = TextEditingController(text: '1006');
    double gstVal = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Add New Product SKU', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 8),
                TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU Code / Barcode')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: mrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP (₹)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (₹)'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN/SAC'))),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<double>(
                  value: gstVal,
                  decoration: const InputDecoration(labelText: 'GST Tax Slab'),
                  items: const [
                    DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                    DropdownMenuItem(value: 5.0, child: Text('5% (Groceries/Grains)')),
                    DropdownMenuItem(value: 12.0, child: Text('12% (Processed Food)')),
                    DropdownMenuItem(value: 18.0, child: Text('18% (Standard GST)')),
                    DropdownMenuItem(value: 28.0, child: Text('28% (Luxury/Sin)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => gstVal = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newProduct = ProductItem(
                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'New Product',
                  regionalName: '',
                  skuCode: skuCtrl.text.isNotEmpty ? skuCtrl.text : 'SKU-${DateTime.now().millisecondsSinceEpoch}',
                  barcode: skuCtrl.text,
                  hsnSacCode: hsnCtrl.text,
                  category: 'General',
                  unit: ItemUnit.pcs,
                  mrp: double.tryParse(mrpCtrl.text) ?? 100.0,
                  sellingPrice: double.tryParse(priceCtrl.text) ?? 90.0,
                  wholesalePrice: (double.tryParse(priceCtrl.text) ?? 90.0) * 0.9,
                  purchasePrice: (double.tryParse(priceCtrl.text) ?? 90.0) * 0.8,
                  gstPercent: gstVal,
                  isTaxInclusive: true,
                  currentStock: double.tryParse(stockCtrl.text) ?? 50.0,
                  lowStockThreshold: 10.0,
                );
                await widget.repository.upsertProduct(newProduct);
                _loadBulkEditor();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Add SKU'),
            ),
          ],
        ),
      ),
    );
  }
}
