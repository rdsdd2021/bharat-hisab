import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import '../theme/ezo_theme.dart';
import '../widgets/barcode_scanner_modal.dart';
import '../widgets/product_image_picker.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
  StockHealthFilter _activeHealthFilter = StockHealthFilter.all;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isBulkSaving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadBulkEditor();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadBulkEditor() {
    _bulkEditor.loadProducts(widget.repository.getAllProducts());
  }

  List<String> _extractDistinctCategories(List<ProductItem> products) {
    final categories = <String>{'All'};
    for (final p in products) {
      if (p.category.trim().isNotEmpty) {
        categories.add(p.category.trim());
      }
    }
    return categories.toList();
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

    // Filter by stock health
    if (_activeHealthFilter == StockHealthFilter.lowStock) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    } else if (_activeHealthFilter == StockHealthFilter.outOfStock) {
      filtered = filtered.where((p) => p.isOutOfStock).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.skuCode.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            p.regionalName.toLowerCase().contains(q);
      }).toList();
    }

    final categories = _extractDistinctCategories(allProducts);

    return Column(
      children: [
        // Search & Filter Strip
        Container(
          padding: const EdgeInsets.all(10),
          color: EzoColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar with Clear Button
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: EzoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EzoColors.border, width: 1),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: EzoColors.textMuted),
                    hintText: 'Search catalog by SKU, item name, barcode, regional...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    isDense: true,
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
              const SizedBox(height: 8),

              // Stock Health Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All (${allProducts.length})', _activeHealthFilter == StockHealthFilter.all, () {
                      setState(() => _activeHealthFilter = StockHealthFilter.all);
                    }),
                    const SizedBox(width: 6),
                    _buildFilterPill('Low Stock (${allProducts.where((p) => p.isLowStock).length})', _activeHealthFilter == StockHealthFilter.lowStock, () {
                      setState(() => _activeHealthFilter = StockHealthFilter.lowStock);
                    }),
                    const SizedBox(width: 6),
                    _buildFilterPill('Out of Stock (${allProducts.where((p) => p.isOutOfStock).length})', _activeHealthFilter == StockHealthFilter.outOfStock, () {
                      setState(() => _activeHealthFilter = StockHealthFilter.outOfStock);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Category Filter Chips (Horizontal Scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : EzoColors.textSecondary,
                        ),
                        selectedColor: EzoColors.primary,
                        backgroundColor: EzoColors.surfaceSecondary,
                        side: BorderSide(
                          color: isSelected ? EzoColors.primary : EzoColors.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Product List
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
                            child: Icon(LucideIcons.boxes, size: 30, color: EzoColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Products Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: EzoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add your stock inventory with barcodes, purchase/retail prices, and low-stock alerts.',
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
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add Product Item'),
                          onPressed: () => _showAddProductDialog(context),
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
                    final p = filtered[idx];
                    return InkWell(
                      onTap: () => _showEditProductDialog(context, p),
                      child: Container(
                        color: EzoColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            // Category Icon / Avatar / Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: EzoColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: p.imageUrl.isNotEmpty
                                    ? ProductImagePicker.buildThumbnail(
                                        p.imageUrl,
                                        width: 38,
                                        height: 38,
                                      )
                                    : Center(
                                        child: Text(
                                          p.category.isNotEmpty ? p.category[0].toUpperCase() : 'P',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: EzoColors.primary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: EzoColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (p.regionalName.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${p.regionalName})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: EzoColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: ${p.skuCode} • Cat: ${p.category} • GST: ${p.gstPercent}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: EzoColors.textMuted,
                                    ),
                                  ),
                                  if (p.barcode.isNotEmpty)
                                    Text(
                                      'Barcode: ${p.barcode}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        color: EzoColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Price & Stock Display
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
                                const SizedBox(height: 3),
                                InkWell(
                                  onTap: () => _showStockAdjustmentModal(context, p),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.isOutOfStock
                                          ? EzoColors.errorBg
                                          : (p.isLowStock ? EzoColors.warningBg : EzoColors.successBg),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: p.isOutOfStock
                                            ? EzoColors.error.withValues(alpha: 0.3)
                                            : (p.isLowStock ? EzoColors.warning.withValues(alpha: 0.3) : EzoColors.success.withValues(alpha: 0.3)),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.arrowUpDown,
                                          size: 10,
                                          color: p.isOutOfStock
                                              ? EzoColors.error
                                              : (p.isLowStock ? EzoColors.warning : EzoColors.success),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${p.currentStock.toInt()} ${p.unit.name.toUpperCase()}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: p.isOutOfStock
                                                ? EzoColors.error
                                                : (p.isLowStock ? EzoColors.warning : EzoColors.success),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Quick Action Buttons
                            const SizedBox(width: 6),
                            PopupMenuButton<String>(
                              icon: const Icon(LucideIcons.moreVertical, size: 16, color: EzoColors.textMuted),
                              padding: EdgeInsets.zero,
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditProductDialog(context, p);
                                } else if (val == 'stock') {
                                  _showStockAdjustmentModal(context, p);
                                } else if (val == 'barcode') {
                                  _showBarcodeStickerGeneratorModal(context, p);
                                } else if (val == 'delete') {
                                  _confirmDeleteProductDialog(context, p);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.pencil, size: 14, color: EzoColors.primary),
                                      SizedBox(width: 8),
                                      Text('Edit SKU Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'stock',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.arrowUpDown, size: 14, color: EzoColors.success),
                                      SizedBox(width: 8),
                                      Text('Adjust Stock (In / Out)'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'barcode',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.printer, size: 14, color: Color(0xFF7C3AED)),
                                      SizedBox(width: 8),
                                      Text('Print Barcode Label'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.trash2, size: 14, color: EzoColors.error),
                                      SizedBox(width: 8),
                                      Text('Delete Product', style: TextStyle(color: EzoColors.error)),
                                    ],
                                  ),
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
                'Spreadsheet Batch Editor',
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
              const SizedBox(width: 6),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.percent, size: 13),
                label: const Text('-5% Discount'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  setState(() {
                    _bulkEditor.applyMarkupPercentage(percentage: -5.0);
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
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.barcode, size: 40, color: EzoColors.textMuted),
            const SizedBox(height: 12),
            Text('No products available for barcode stickers.', style: GoogleFonts.plusJakartaSans(color: EzoColors.textMuted)),
          ],
        ),
      );
    }

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
              InkWell(
                onTap: () => _showBarcodeStickerGeneratorModal(context, p),
                child: Container(
                  width: 200,
                  height: 105,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: EzoColors.border, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
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
                          20,
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Barcode: ${p.barcode.isNotEmpty ? p.barcode : p.skuCode}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted)),
                    Text('Stock: ${p.currentStock.toInt()} ${p.unit.name.toUpperCase()}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.printer, size: 13),
                          label: const Text('Print Sticker'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EzoColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _showBarcodeStickerGeneratorModal(context, p),
                        ),
                      ],
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
    final regionalCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final mrpCtrl = TextEditingController(text: '100');
    final priceCtrl = TextEditingController(text: '90');
    final costCtrl = TextEditingController(text: '70');
    final wholesaleCtrl = TextEditingController(text: '80');
    final stockCtrl = TextEditingController(text: '50');
    final lowStockCtrl = TextEditingController(text: '10');
    final hsnCtrl = TextEditingController(text: '1006');
    String category = 'General';
    ItemUnit unit = ItemUnit.pcs;
    double gstVal = 5.0;
    bool showOnOnlineDukan = true;
    String imageUrl = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(LucideIcons.packagePlus, color: EzoColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Add New Product SKU', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImagePicker(
                  currentImageUrl: imageUrl,
                  onImageChanged: (url) => setDlgState(() => imageUrl = url),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. Fortune Rice 5kg')),
                const SizedBox(height: 8),
                TextField(controller: regionalCtrl, decoration: const InputDecoration(labelText: 'Regional / Vernacular Name', hintText: 'e.g. चावल / ভাত')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skuCtrl,
                        decoration: const InputDecoration(labelText: 'SKU Code', hintText: 'Auto if blank'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Barcode (EAN-13)',
                          hintText: 'Scan or type',
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
                            tooltip: 'Scan Barcode with Camera / Scanner',
                            onPressed: () {
                              BarcodeScannerModal.show(
                                context,
                                onBarcodeScanned: (code) {
                                  setDlgState(() {
                                    barcodeCtrl.text = code;
                                    if (skuCtrl.text.trim().isEmpty) {
                                      skuCtrl.text = code;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'General', child: Text('General')),
                          DropdownMenuItem(value: 'Groceries', child: Text('Groceries & Grains')),
                          DropdownMenuItem(value: 'Dairy', child: Text('Dairy & Milk')),
                          DropdownMenuItem(value: 'Beverages', child: Text('Beverages & Drinks')),
                          DropdownMenuItem(value: 'Snacks', child: Text('Snacks & Biscuits')),
                          DropdownMenuItem(value: 'Personal Care', child: Text('Personal Care')),
                          DropdownMenuItem(value: 'Home Care', child: Text('Home Care & Cleaning')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ItemUnit>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: ItemUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => unit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: mrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP (₹) *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price (₹) *'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Purchase Cost (₹)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: wholesaleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wholesale Price (₹)'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: lowStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Alert Qty'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN / SAC Code'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: gstVal,
                        decoration: const InputDecoration(labelText: 'GST Tax Slab'),
                        items: const [
                          DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                          DropdownMenuItem(value: 5.0, child: Text('5% (Grains)')),
                          DropdownMenuItem(value: 12.0, child: Text('12% (Processed)')),
                          DropdownMenuItem(value: 18.0, child: Text('18% (Standard)')),
                          DropdownMenuItem(value: 28.0, child: Text('28% (Luxury)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => gstVal = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on WhatsApp Online Dukan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  value: showOnOnlineDukan,
                  activeThumbColor: EzoColors.primary,
                  onChanged: (v) => setDlgState(() => showOnOnlineDukan = v),
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
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a product name')));
                  return;
                }
                final mrp = double.tryParse(mrpCtrl.text) ?? 100.0;
                final price = double.tryParse(priceCtrl.text) ?? 90.0;
                final cost = double.tryParse(costCtrl.text) ?? (price * 0.8);
                final wholesale = double.tryParse(wholesaleCtrl.text) ?? (price * 0.9);
                final stock = double.tryParse(stockCtrl.text) ?? 0.0;
                final lowStock = double.tryParse(lowStockCtrl.text) ?? 5.0;
                final sku = skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : 'SKU-${DateTime.now().millisecondsSinceEpoch}';
                final barcode = barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : sku;

                final newProduct = ProductItem(
                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  regionalName: regionalCtrl.text.trim(),
                  skuCode: sku,
                  barcode: barcode,
                  hsnSacCode: hsnCtrl.text.trim(),
                  category: category,
                  unit: unit,
                  mrp: mrp,
                  sellingPrice: price,
                  wholesalePrice: wholesale,
                  purchasePrice: cost,
                  gstPercent: gstVal,
                  isTaxInclusive: true,
                  currentStock: stock,
                  lowStockThreshold: lowStock,
                  showOnOnlineDukan: showOnOnlineDukan,
                  imageUrl: imageUrl,
                );

                await widget.repository.upsertProduct(newProduct);
                _loadBulkEditor();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added SKU "$name" successfully!')),
                  );
                }
              },
              child: const Text('Add SKU'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductItem product) {
    final nameCtrl = TextEditingController(text: product.name);
    final regionalCtrl = TextEditingController(text: product.regionalName);
    final skuCtrl = TextEditingController(text: product.skuCode);
    final barcodeCtrl = TextEditingController(text: product.barcode);
    final mrpCtrl = TextEditingController(text: product.mrp.toStringAsFixed(2));
    final priceCtrl = TextEditingController(text: product.sellingPrice.toStringAsFixed(2));
    final costCtrl = TextEditingController(text: product.purchasePrice.toStringAsFixed(2));
    final wholesaleCtrl = TextEditingController(text: product.wholesalePrice.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: product.currentStock.toStringAsFixed(0));
    final lowStockCtrl = TextEditingController(text: product.lowStockThreshold.toStringAsFixed(0));
    final hsnCtrl = TextEditingController(text: product.hsnSacCode);
    String category = product.category;
    ItemUnit unit = product.unit;
    double gstVal = product.gstPercent;
    bool showOnOnlineDukan = product.showOnOnlineDukan;
    String imageUrl = product.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(LucideIcons.pencil, color: EzoColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Edit SKU: ${product.name}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImagePicker(
                  currentImageUrl: imageUrl,
                  onImageChanged: (url) => setDlgState(() => imageUrl = url),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                const SizedBox(height: 8),
                TextField(controller: regionalCtrl, decoration: const InputDecoration(labelText: 'Regional / Vernacular Name')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU Code'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: barcodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Barcode (EAN-13)',
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
                            tooltip: 'Scan Barcode with Camera / Scanner',
                            onPressed: () {
                              BarcodeScannerModal.show(
                                context,
                                onBarcodeScanned: (code) {
                                  setDlgState(() => barcodeCtrl.text = code);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'General', child: Text('General')),
                          DropdownMenuItem(value: 'Groceries', child: Text('Groceries & Grains')),
                          DropdownMenuItem(value: 'Dairy', child: Text('Dairy & Milk')),
                          DropdownMenuItem(value: 'Beverages', child: Text('Beverages & Drinks')),
                          DropdownMenuItem(value: 'Snacks', child: Text('Snacks & Biscuits')),
                          DropdownMenuItem(value: 'Personal Care', child: Text('Personal Care')),
                          DropdownMenuItem(value: 'Home Care', child: Text('Home Care & Cleaning')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ItemUnit>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: ItemUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => unit = val);
                        },
                      ),
                    ),
                  ],
                ),
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
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Purchase Cost (₹)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: wholesaleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wholesale Price (₹)'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Stock'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: lowStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Threshold'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN / SAC Code'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: gstVal,
                        decoration: const InputDecoration(labelText: 'GST Tax Slab'),
                        items: const [
                          DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                          DropdownMenuItem(value: 5.0, child: Text('5% (Grains)')),
                          DropdownMenuItem(value: 12.0, child: Text('12% (Processed)')),
                          DropdownMenuItem(value: 18.0, child: Text('18% (Standard)')),
                          DropdownMenuItem(value: 28.0, child: Text('28% (Luxury)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDlgState(() => gstVal = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on WhatsApp Online Dukan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  value: showOnOnlineDukan,
                  activeThumbColor: EzoColors.primary,
                  onChanged: (v) => setDlgState(() => showOnOnlineDukan = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(LucideIcons.arrowUpDown, size: 14, color: EzoColors.success),
                      label: const Text('Adjust Stock', style: TextStyle(color: EzoColors.success, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showStockAdjustmentModal(context, product);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(LucideIcons.trash2, size: 14, color: EzoColors.error),
                      label: const Text('Delete SKU', style: TextStyle(color: EzoColors.error, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDeleteProductDialog(context, product);
                      },
                    ),
                  ],
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
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name cannot be empty')));
                  return;
                }

                final updated = product.copyWith(
                  name: name,
                  regionalName: regionalCtrl.text.trim(),
                  skuCode: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : product.skuCode,
                  barcode: barcodeCtrl.text.trim(),
                  category: category,
                  unit: unit,
                  mrp: double.tryParse(mrpCtrl.text) ?? product.mrp,
                  sellingPrice: double.tryParse(priceCtrl.text) ?? product.sellingPrice,
                  purchasePrice: double.tryParse(costCtrl.text) ?? product.purchasePrice,
                  wholesalePrice: double.tryParse(wholesaleCtrl.text) ?? product.wholesalePrice,
                  currentStock: double.tryParse(stockCtrl.text) ?? product.currentStock,
                  lowStockThreshold: double.tryParse(lowStockCtrl.text) ?? product.lowStockThreshold,
                  hsnSacCode: hsnCtrl.text.trim(),
                  gstPercent: gstVal,
                  showOnOnlineDukan: showOnOnlineDukan,
                  imageUrl: imageUrl,
                );

                await widget.repository.upsertProduct(updated);
                _loadBulkEditor();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated "${updated.name}" successfully!')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockAdjustmentModal(BuildContext context, ProductItem product) {
    bool isStockIn = true;
    final qtyCtrl = TextEditingController(text: '10');
    String reason = 'Supplier Delivery / Restock';

    final stockInReasons = [
      'Supplier Delivery / Restock',
      'Customer Return / Exchange',
      'Inventory Count Surplus',
      'Purchase Order Received',
    ];

    final stockOutReasons = [
      'Damaged / Expired Goods',
      'Wastage / Spoilage',
      'Customer Return to Supplier',
      'Theft / Shortage Loss',
      'Inventory Count Correction',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final enteredQty = double.tryParse(qtyCtrl.text) ?? 0.0;
          final currentStock = product.currentStock;
          final finalStock = isStockIn ? currentStock + enteredQty : (currentStock - enteredQty);

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: EzoColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        isStockIn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        color: isStockIn ? EzoColors.success : EzoColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stock Adjustment: ${product.name}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Current In-Hand Stock: ${currentStock.toInt()} ${product.unit.name.toUpperCase()}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted)),
                  const SizedBox(height: 14),

                  // Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStockIn ? EzoColors.success : EzoColors.surfaceSecondary,
                            foregroundColor: isStockIn ? Colors.white : EzoColors.textSecondary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 15),
                          label: const Text('Stock In (+ Jama)'),
                          onPressed: () {
                            setModalState(() {
                              isStockIn = true;
                              reason = stockInReasons.first;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isStockIn ? EzoColors.error : EzoColors.surfaceSecondary,
                            foregroundColor: !isStockIn ? Colors.white : EzoColors.textSecondary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(LucideIcons.minus, size: 15),
                          label: const Text('Stock Out (- Nikasi)'),
                          onPressed: () {
                            setModalState(() {
                              isStockIn = false;
                              reason = stockOutReasons.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quantity input
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Adjustment Quantity (${product.unit.label})',
                      prefixIcon: const Icon(LucideIcons.boxes, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Quantity Buttons
                  Wrap(
                    spacing: 6,
                    children: [1, 5, 10, 25, 50].map((q) {
                      return ActionChip(
                        label: Text('+$q'),
                        onPressed: () {
                          qtyCtrl.text = q.toString();
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Reason Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(labelText: 'Adjustment Reason / Note'),
                    items: (isStockIn ? stockInReasons : stockOutReasons).map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12.5)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => reason = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Preview Calculation Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EzoColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EzoColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Projected New Stock:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          '${finalStock.toInt()} ${product.unit.name.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: finalStock < 0 ? EzoColors.error : (isStockIn ? EzoColors.success : EzoColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStockIn ? EzoColors.success : EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final adj = double.tryParse(qtyCtrl.text) ?? 0.0;
                        if (adj <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid positive quantity')));
                          return;
                        }
                        final newStock = isStockIn ? (currentStock + adj) : (currentStock - adj).clamp(0.0, double.infinity);
                        final updated = product.copyWith(currentStock: newStock);
                        await widget.repository.upsertProduct(updated);
                        _loadBulkEditor();
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Updated ${product.name} stock: ${currentStock.toInt()} → ${newStock.toInt()} ($reason)'),
                              backgroundColor: EzoColors.success,
                            ),
                          );
                        }
                      },
                      child: Text(
                        isStockIn ? 'Confirm Stock In (+ Add)' : 'Confirm Stock Out (- Deduct)',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteProductDialog(BuildContext context, ProductItem product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: EzoColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Delete Product SKU?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}" (SKU: ${product.skuCode}) from your inventory?\n\nThis action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EzoColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.repository.deleteProduct(product.id);
              _loadBulkEditor();
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted SKU "${product.name}" from catalog.')),
                );
              }
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeStickerGeneratorModal(BuildContext context, ProductItem product) {
    int printCopies = 1;
    bool showStoreName = true;
    bool showPrices = true;
    bool showBarcodeText = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStickerState) {
          final discountPercent = product.discountPercent.round();

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: EzoColors.border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(LucideIcons.printer, color: Color(0xFF7C3AED), size: 22),
                      const SizedBox(width: 8),
                      Text('Barcode Label Sticker Generator', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Print thermal adhesive barcode stickers for retail shelves & packaging',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EzoColors.textMuted)),
                  const SizedBox(height: 16),

                  // Real-time Preview Box
                  Center(
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showStoreName)
                            Text(widget.storeProfile.storeName, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.black87)),
                          const SizedBox(height: 4),
                          // Simulated Barcode Bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              22,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: i % 3 == 0 ? 2.5 : 1.2,
                                height: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (showBarcodeText) ...[
                            const SizedBox(height: 2),
                            Text(
                              product.barcode.isNotEmpty ? product.barcode : product.skuCode,
                              style: GoogleFonts.jetBrainsMono(fontSize: 8.5, letterSpacing: 1.5, color: Colors.black),
                            ),
                          ],
                          if (showPrices) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                discountPercent > 0
                                    ? 'MRP ₹${product.mrp.toInt()}  |  SAVE $discountPercent%'
                                    : 'PRICE: ₹${product.sellingPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.bold, color: EzoColors.warning),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Toggles
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Display Store Name', style: TextStyle(fontSize: 12)),
                    value: showStoreName,
                    activeThumbColor: EzoColors.primary,
                    onChanged: (v) => setStickerState(() => showStoreName = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Display MRP & Savings Badge', style: TextStyle(fontSize: 12)),
                    value: showPrices,
                    activeThumbColor: EzoColors.primary,
                    onChanged: (v) => setStickerState(() => showPrices = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Display Barcode Number Text', style: TextStyle(fontSize: 12)),
                    value: showBarcodeText,
                    activeThumbColor: EzoColors.primary,
                    onChanged: (v) => setStickerState(() => showBarcodeText = v),
                  ),
                  const SizedBox(height: 8),

                  // Copies Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Number of Sticker Copies:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minusCircle, size: 20, color: EzoColors.textMuted),
                            onPressed: () {
                              if (printCopies > 1) {
                                setStickerState(() => printCopies--);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: EzoColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: EzoColors.border),
                            ),
                            child: Text('$printCopies', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plusCircle, size: 20, color: EzoColors.primary),
                            onPressed: () {
                              setStickerState(() => printCopies++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.copy, size: 14),
                          label: const Text('Copy SVG'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () {
                            final svg = BarcodeStickerDesigner.renderStickerSvg(
                              product: product,
                              storeName: widget.storeProfile.storeName,
                            );
                            Clipboard.setData(ClipboardData(text: svg));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Label SVG copied to clipboard!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EzoColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.printer, size: 16),
                          label: Text('Print $printCopies Labels (ESC/POS)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            // Dispatch sticker to printer connection manager
                            final activePrinter = ThermalPrinterConnectionManager().activeDevice;
                            final printerName = activePrinter?.name ?? 'Virtual Thermal Driver';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🖨️ Dispatched $printCopies barcode labels for "${product.name}" to $printerName'),
                                backgroundColor: EzoColors.success,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
