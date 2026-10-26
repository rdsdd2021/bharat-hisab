import 'package:flutter/material.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_l10n_vernacular/ezo_l10n_vernacular.dart';
import '../controllers/pos_billing_controller.dart';
import '../theme/ezo_theme.dart';
import 'receipt_preview_modal.dart';

class PosBillingScreen extends StatefulWidget {
  final PosBillingController controller;

  const PosBillingScreen({super.key, required this.controller});

  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (isDesktop) {
          return Scaffold(
            backgroundColor: EzoColors.background,
            body: Row(
              children: [
                Expanded(flex: 6, child: _buildCatalogSection(c)),
                const VerticalDivider(width: 1, color: EzoColors.border),
                Expanded(flex: 4, child: _buildCartSection(c)),
              ],
            ),
          );
        } else {
          // Mobile Layout
          return Scaffold(
            backgroundColor: EzoColors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: c.cartLines.isNotEmpty ? 76 : 0),
                    child: _buildCatalogSection(c),
                  ),
                ),
                if (c.cartLines.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildMobileFloatingCartBar(c),
                  ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCatalogSection(PosBillingController c) {
    return Column(
      children: [
        // Mode Switches & Search Bar Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: EzoColors.surface,
            border: Border(bottom: BorderSide(color: EzoColors.border, width: 1)),
          ),
          child: Column(
            children: [
              // Row: GST Mode toggle & Custom Fields
              Row(
                children: [
                  // Mode Toggle Pill
                  InkWell(
                    onTap: () => c.setGstMode(!c.isGstInvoice),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.isGstInvoice ? EzoColors.primaryLight : EzoColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: c.isGstInvoice ? EzoColors.primary : EzoColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.isGstInvoice ? LucideIcons.checkCircle2 : LucideIcons.circle,
                            size: 14,
                            color: c.isGstInvoice ? EzoColors.primary : EzoColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.isGstInvoice ? 'GST Tax Invoice' : 'Bill of Supply',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.isGstInvoice ? EzoColors.primary : EzoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Quick Customer Link Chip
                  InkWell(
                    onTap: () => _showCustomerSelectorModal(context, c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.selectedCustomer != null
                            ? EzoColors.primary.withValues(alpha: 0.12)
                            : EzoColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: c.selectedCustomer != null ? EzoColors.primary : EzoColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 13,
                            color: c.selectedCustomer != null ? EzoColors.primary : EzoColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.selectedCustomer != null ? c.selectedCustomer!.name : '+ Customer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.selectedCustomer != null ? EzoColors.primary : EzoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Add Product Button
                  InkWell(
                    onTap: () => _showAddProductQuickDialog(context, c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EzoColors.primary.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus, size: 14, color: EzoColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '+ Add SKU',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: EzoColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Custom Fields Button
                  InkWell(
                    onTap: () => _showCustomFieldsDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: EzoColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EzoColors.border, width: 1),
                      ),
                      child: const Icon(LucideIcons.slidersHorizontal, size: 16, color: EzoColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search Bar with Barcode Scanner submission & Camera Scanner Button
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: EzoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EzoColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(LucideIcons.search, size: 16, color: EzoColors.textMuted),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => c.setSearchQuery(val),
                        onSubmitted: (val) => _handleBarcodeScan(val, c),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search product or scan barcode (e.g. 8901030383794)...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EzoColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 14, color: EzoColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          c.setSearchQuery('');
                        },
                      ),
                    // Phone Camera Barcode Scanner Button
                    Tooltip(
                      message: 'Scan using Camera / Phone Scanner',
                      child: InkWell(
                        onTap: () => _showCameraBarcodeScannerModal(context, c),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: EzoColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: EzoColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.scanLine, size: 15, color: EzoColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Scan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: EzoColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category Pills
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: EzoColors.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: c.availableCategories.length,
            itemBuilder: (context, idx) {
              final cat = c.availableCategories[idx];
              final isSelected = cat == c.selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => c.setCategory(cat),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? EzoColors.primary : EzoColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? EzoColors.primary : EzoColors.border,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : EzoColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),

        // Product Grid or Empty State
        Expanded(
          child: c.filteredProducts.isEmpty
              ? _buildEmptyCatalogView(context, c)
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: c.filteredProducts.length,
                  itemBuilder: (context, idx) {
                    final item = c.filteredProducts[idx];
                    final lineIdx = c.cartLines.indexWhere((l) => l.productId == item.id);
                    final qtyInCart = lineIdx != -1 ? c.cartLines[lineIdx].quantity.toInt() : 0;

                    return _buildProductCard(item, qtyInCart, lineIdx, c);
                  },
                ),
        ),

        // Upsell Recommendation Strip
        if (c.upsellSuggestions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(top: BorderSide(color: Color(0xFFFDE68A), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: EzoColors.warning, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Recommended:',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: EzoColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: c.upsellSuggestions.map((up) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => c.addProductToCart(up),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                              ),
                              child: Text(
                                '${up.name} • ₹${up.sellingPrice.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(ProductItem item, int qtyInCart, int lineIdx, PosBillingController c) {
    return Container(
      decoration: BoxDecoration(
        color: EzoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qtyInCart > 0 ? EzoColors.primary : EzoColors.border,
          width: qtyInCart > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Initial & Stock Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: EzoColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty ? item.name[0] : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: EzoColors.primary,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isOutOfStock
                        ? EzoColors.errorBg
                        : (item.isLowStock ? EzoColors.warningBg : EzoColors.successBg),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.isOutOfStock ? 'OOS' : '${item.currentStock.toInt()} in stock',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: item.isOutOfStock
                          ? EzoColors.error
                          : (item.isLowStock ? EzoColors.warning : EzoColors.success),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Item Name
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.25,
                color: EzoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Regional Vernacular Name
            Text(
              item.regionalName.isNotEmpty ? item.regionalName : item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: EzoColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Price & Add / Stepper Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${item.sellingPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: EzoColors.primary,
                        ),
                      ),
                      if (item.mrp > item.sellingPrice)
                        Text(
                          '₹${item.mrp.toInt()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: EzoColors.textDisabled,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),

                // Stepper or + Add Button
                if (qtyInCart == 0)
                  InkWell(
                    onTap: () => c.addProductToCart(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: EzoColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.plus, size: 16, color: EzoColors.primary),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: EzoColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            if (lineIdx != -1) {
                              c.updateCartLineQty(lineIdx, c.cartLines[lineIdx].quantity - 1);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(LucideIcons.minus, size: 13, color: Colors.white),
                          ),
                        ),
                        Text(
                          '$qtyInCart',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        InkWell(
                          onTap: () => c.addProductToCart(item),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(LucideIcons.plus, size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFloatingCartBar(PosBillingController c) {
    final savings = c.totalCustomerSavings;
    final total = c.grandTotal;
    final itemCount = c.cartLines.fold<int>(0, (sum, l) => sum + l.quantity.toInt());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item count & Total
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$itemCount ${itemCount == 1 ? 'Item' : 'Items'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (savings > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: EzoColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Saved ₹${savings.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Checkout Button
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _buildMobileCartSheet(ctx, c),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EzoColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Checkout',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(LucideIcons.arrowRight, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartSheet(BuildContext context, PosBillingController c) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: EzoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EzoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Active Bill (${c.cartLines.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EzoColors.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    c.clearCart();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EzoColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Customer / Khata Selection Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InkWell(
              onTap: () => _showCustomerSelectorModal(context, c),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.selectedCustomer != null
                      ? EzoColors.primary.withValues(alpha: 0.08)
                      : EzoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: c.selectedCustomer != null
                        ? EzoColors.primary.withValues(alpha: 0.4)
                        : EzoColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: c.selectedCustomer != null
                            ? EzoColors.primary.withValues(alpha: 0.15)
                            : EzoColors.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.user,
                        size: 16,
                        color: c.selectedCustomer != null ? EzoColors.primary : EzoColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.selectedCustomer != null ? c.selectedCustomer!.name : 'Cash Customer (Walk-in)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: EzoColors.textPrimary,
                            ),
                          ),
                          Text(
                            c.selectedCustomer != null
                                ? 'Phone: ${c.selectedCustomer!.phone.isNotEmpty ? c.selectedCustomer!.phone : "N/A"}  •  Khata Udhaar: ₹${c.selectedCustomer!.netBalance.toStringAsFixed(0)}'
                                : 'Tap to link registered customer / Khata credit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: c.selectedCustomer != null ? EzoColors.primary : EzoColors.textMuted,
                              fontWeight: c.selectedCustomer != null ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.selectedCustomer != null)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 15, color: EzoColors.textMuted),
                        tooltip: 'Reset to Walk-in',
                        onPressed: () => c.setCustomer(null),
                      )
                    else
                      const Icon(LucideIcons.chevronRight, size: 14, color: EzoColors.textMuted),
                  ],
                ),
              ),
            ),
          ),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: c.cartLines.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final line = c.cartLines[idx];
                final prod = c.repository.getProduct(line.productId);
                final prodName = prod?.name ?? line.productId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prodName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: EzoColors.textPrimary,
                              ),
                            ),
                            Text(
                              '₹${line.unitSellingPrice.toStringAsFixed(2)} × ${line.quantity.toInt()} = ₹${line.totalAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: EzoColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: EzoColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: EzoColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => c.updateCartLineQty(idx, line.quantity - 1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(LucideIcons.minus, size: 12, color: EzoColors.textSecondary),
                              ),
                            ),
                            Text(
                              '${line.quantity.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: EzoColors.textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: () => c.updateCartLineQty(idx, line.quantity + 1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(LucideIcons.plus, size: 12, color: EzoColors.textSecondary),
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
          ),

          // Tax Breakdown & Totals Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: EzoColors.surfaceSecondary,
              border: Border(top: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Taxable Subtotal', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textSecondary)),
                    Text('₹${c.taxableSubtotal.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GST (CGST+SGST/IGST)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textSecondary)),
                    Text('₹${c.totalTax.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (c.totalCustomerSavings > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎉 Total Customer Savings', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: EzoColors.success)),
                      Text('₹${c.totalCustomerSavings.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: EzoColors.success)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EzoColors.textPrimary),
                    ),
                    Text(
                      '₹${c.grandTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: EzoColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dual Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final invoice = c.buildCurrentInvoice();
                          Navigator.pop(context);
                          ReceiptPreviewModal.show(
                            context,
                            invoice: invoice,
                            storeProfile: c.currentProfile,
                          );
                        },
                        icon: const Icon(LucideIcons.printer, size: 16),
                        label: const Text('Print Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EzoColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          c.setSettlementMode(SettlementMode.creditUdhaar);
                          await c.commitInvoice();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bill saved and recorded in Customer Khata!'),
                                backgroundColor: Color(0xFFEA580C),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.bookUser, size: 15),
                        label: const Text('Udhaar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildCartSection(PosBillingController c) {
    return _buildMobileCartSheet(context, c);
  }

  void _showCustomFieldsDialog(BuildContext context) {
    final c = widget.controller;
    final tableCtrl = TextEditingController(text: c.customFields.tableNumber);
    final batchCtrl = TextEditingController(text: c.customFields.batchNumber);
    final imeiCtrl = TextEditingController(text: c.customFields.ticketOrImeiNumber);
    final poCtrl = TextEditingController(text: c.customFields.poNumber);
    final ewayCtrl = TextEditingController(text: c.customFields.ewayBillNumber);
    final vehicleCtrl = TextEditingController(text: c.customFields.vehicleNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Custom Bill & Vertical Fields',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tableCtrl,
                decoration: const InputDecoration(labelText: 'Table / Room Number (Restaurant/Cafe)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: batchCtrl,
                decoration: const InputDecoration(labelText: 'Batch / Lot Number (Pharma/FMCG)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imeiCtrl,
                decoration: const InputDecoration(labelText: 'Serial / IMEI / Ticket Number (Electronics)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: poCtrl,
                decoration: const InputDecoration(labelText: 'Purchase Order (PO) Number (B2B)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ewayCtrl,
                decoration: const InputDecoration(labelText: 'E-Way Bill Number (Logistics)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vehicleCtrl,
                decoration: const InputDecoration(labelText: 'Vehicle / Transport No'),
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
            onPressed: () {
              c.setCustomFields(InvoiceCustomFields(
                tableNumber: tableCtrl.text,
                batchNumber: batchCtrl.text,
                ticketOrImeiNumber: imeiCtrl.text,
                poNumber: poCtrl.text,
                ewayBillNumber: ewayCtrl.text,
                vehicleNumber: vehicleCtrl.text,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save Fields'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCatalogView(BuildContext context, PosBillingController c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: EzoColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.packagePlus, size: 36, color: EzoColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Store Inventory is Clean & Ready',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: EzoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No products in catalog yet. You can add your own real products directly, or populate starter Kirana staples with one tap.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: EzoColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EzoColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                'Add Your First Product SKU',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _showAddProductQuickDialog(context, c),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                side: const BorderSide(color: EzoColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(LucideIcons.sparkles, size: 16, color: EzoColors.warning),
              label: Text(
                'Quick-Load 10 Essential Staples',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EzoColors.textSecondary,
                ),
              ),
              onPressed: () => _seedQuickStarterStaples(c),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductQuickDialog(BuildContext context, PosBillingController c, {String? initialBarcode}) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController(text: initialBarcode ?? '');
    final mrpCtrl = TextEditingController(text: '100');
    final priceCtrl = TextEditingController(text: '90');
    final stockCtrl = TextEditingController(text: '50');
    final hsnCtrl = TextEditingController(text: '1006');
    double gstVal = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Quick Add Product SKU',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g. Tata Salt 1kg, Milk 500ml',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / SKU Code',
                    hintText: 'Leave blank to auto-generate',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mrpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'MRP (₹)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sale Price (₹)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock Qty'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: hsnCtrl,
                        decoration: const InputDecoration(labelText: 'HSN/SAC Code'),
                      ),
                    ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EzoColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prodName = nameCtrl.text.trim();
                if (prodName.isEmpty) return;

                final mrp = double.tryParse(mrpCtrl.text) ?? 100.0;
                final sellingPrice = double.tryParse(priceCtrl.text) ?? mrp;
                final stock = double.tryParse(stockCtrl.text) ?? 50.0;
                final code = skuCtrl.text.trim().isNotEmpty
                    ? skuCtrl.text.trim()
                    : 'SKU-${DateTime.now().millisecondsSinceEpoch % 100000}';

                final item = ProductItem(
                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  name: prodName,
                  regionalName: '',
                  skuCode: code,
                  barcode: code,
                  hsnSacCode: hsnCtrl.text.trim().isNotEmpty ? hsnCtrl.text.trim() : '1006',
                  category: 'General',
                  unit: ItemUnit.pcs,
                  mrp: mrp,
                  sellingPrice: sellingPrice,
                  wholesalePrice: sellingPrice * 0.9,
                  purchasePrice: sellingPrice * 0.8,
                  gstPercent: gstVal,
                  isTaxInclusive: true,
                  currentStock: stock,
                  lowStockThreshold: 10.0,
                );

                await c.repository.upsertProduct(item);
                c.reloadCatalog();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add SKU to Shelf'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedQuickStarterStaples(PosBillingController c) async {
    final staples = [
      ProductItem(
        id: 'p_atta_01',
        name: 'Aashirvaad Shudh Chakki Atta 5kg',
        regionalName: 'आशीर्वाद आटा ५ कि.ग्रा.',
        skuCode: 'SKU-ATTA-005',
        barcode: '8901030383792',
        hsnSacCode: '1101',
        category: 'Flour & Grains',
        unit: ItemUnit.kg,
        mrp: 290.0,
        sellingPrice: 265.0,
        wholesalePrice: 250.0,
        purchasePrice: 240.0,
        gstPercent: 0.0,
        isTaxInclusive: true,
        currentStock: 45.0,
        lowStockThreshold: 10.0,
      ),
      ProductItem(
        id: 'p_oil_02',
        name: 'Fortune Sunlite Refined Sunflower Oil 1L',
        regionalName: 'फॉर्च्यून सूरजमुखी तेल १ ली.',
        skuCode: 'SKU-OIL-001',
        barcode: '8906007280145',
        hsnSacCode: '1512',
        category: 'Edible Oils',
        unit: ItemUnit.ltr,
        mrp: 165.0,
        sellingPrice: 148.0,
        wholesalePrice: 140.0,
        purchasePrice: 135.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 60.0,
        lowStockThreshold: 12.0,
      ),
      ProductItem(
        id: 'p_rice_03',
        name: 'India Gate Basmati Rice Feast Rozzana 1kg',
        regionalName: 'इंडिया गेट बासमती चावल १ कि.ग्रा.',
        skuCode: 'SKU-RICE-001',
        barcode: '8901030383793',
        hsnSacCode: '1006',
        category: 'Rice & Dals',
        unit: ItemUnit.kg,
        mrp: 110.0,
        sellingPrice: 95.0,
        wholesalePrice: 88.0,
        purchasePrice: 82.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 80.0,
        lowStockThreshold: 15.0,
      ),
      ProductItem(
        id: 'p_salt_04',
        name: 'Tata Salt Vacuum Evaporated Iodised 1kg',
        regionalName: 'टाटा नमक १ कि.ग्रा.',
        skuCode: 'SKU-SALT-001',
        barcode: '8901030383794',
        hsnSacCode: '2501',
        category: 'Spices & Seasoning',
        unit: ItemUnit.kg,
        mrp: 28.0,
        sellingPrice: 26.0,
        wholesalePrice: 24.0,
        purchasePrice: 22.0,
        gstPercent: 0.0,
        isTaxInclusive: true,
        currentStock: 120.0,
        lowStockThreshold: 20.0,
      ),
      ProductItem(
        id: 'p_sugar_05',
        name: 'Madhur Pure & Hygienic Sugar 1kg',
        regionalName: 'मधुर चीनी १ कि.ग्रा.',
        skuCode: 'SKU-SUGAR-001',
        barcode: '8901030383795',
        hsnSacCode: '1701',
        category: 'Spices & Seasoning',
        unit: ItemUnit.kg,
        mrp: 55.0,
        sellingPrice: 50.0,
        wholesalePrice: 47.0,
        purchasePrice: 44.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 90.0,
        lowStockThreshold: 15.0,
      ),
      ProductItem(
        id: 'p_tea_06',
        name: 'Tata Tea Gold Leaf Pouch 250g',
        regionalName: 'टाटा टी गोल्ड २५० ग्रा.',
        skuCode: 'SKU-TEA-001',
        barcode: '8901030383796',
        hsnSacCode: '0902',
        category: 'Beverages',
        unit: ItemUnit.pcs,
        mrp: 160.0,
        sellingPrice: 145.0,
        wholesalePrice: 138.0,
        purchasePrice: 130.0,
        gstPercent: 5.0,
        isTaxInclusive: true,
        currentStock: 40.0,
        lowStockThreshold: 8.0,
      ),
      ProductItem(
        id: 'p_milk_07',
        name: 'Amul Taaza Homogenised Toned Milk 500ml',
        regionalName: 'अमुल ताज़ा दूध ५०० मि.ली.',
        skuCode: 'SKU-MILK-001',
        barcode: '8901030383797',
        hsnSacCode: '0401',
        category: 'Dairy',
        unit: ItemUnit.pcs,
        mrp: 27.0,
        sellingPrice: 27.0,
        wholesalePrice: 25.5,
        purchasePrice: 25.0,
        gstPercent: 0.0,
        isTaxInclusive: true,
        currentStock: 30.0,
        lowStockThreshold: 5.0,
      ),
      ProductItem(
        id: 'p_bisc_08',
        name: 'Parle-G Original Gluco Biscuits 250g',
        regionalName: 'पारले-जी बिस्कुट २५० ग्रा.',
        skuCode: 'SKU-PARLE-001',
        barcode: '8901030383798',
        hsnSacCode: '1905',
        category: 'Snacks & Biscuits',
        unit: ItemUnit.pcs,
        mrp: 25.0,
        sellingPrice: 23.0,
        wholesalePrice: 21.0,
        purchasePrice: 19.5,
        gstPercent: 18.0,
        isTaxInclusive: true,
        currentStock: 75.0,
        lowStockThreshold: 15.0,
      ),
      ProductItem(
        id: 'p_maggi_09',
        name: 'Maggi 2-Minute Masala Noodles 280g (Pack of 4)',
        regionalName: 'मैगी २-मिनट मसाला नूडल्स',
        skuCode: 'SKU-MAGGI-004',
        barcode: '8901030383799',
        hsnSacCode: '1902',
        category: 'Instant Food',
        unit: ItemUnit.pcs,
        mrp: 56.0,
        sellingPrice: 52.0,
        wholesalePrice: 48.0,
        purchasePrice: 45.0,
        gstPercent: 12.0,
        isTaxInclusive: true,
        currentStock: 50.0,
        lowStockThreshold: 10.0,
      ),
      ProductItem(
        id: 'p_soap_10',
        name: 'Dettol Original Germ Protection Bathing Soap 75g',
        regionalName: 'डेटॉल ओरिजिनल साबुन ७५ ग्रा.',
        skuCode: 'SKU-DETTOL-001',
        barcode: '8901030383800',
        hsnSacCode: '3401',
        category: 'Personal Care',
        unit: ItemUnit.pcs,
        mrp: 40.0,
        sellingPrice: 38.0,
        wholesalePrice: 35.0,
        purchasePrice: 32.0,
        gstPercent: 18.0,
        isTaxInclusive: true,
        currentStock: 65.0,
        lowStockThreshold: 12.0,
      ),
    ];

    for (final p in staples) {
      await c.repository.upsertProduct(p);
    }
    c.reloadCatalog();
  }

  void _handleBarcodeScan(String rawCode, PosBillingController c) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final allProds = c.repository.getAllProducts();
    // Search exact barcode or SKU code match (case-insensitive)
    final matched = allProds.where((p) {
      return p.barcode.trim() == code ||
          p.skuCode.trim().toLowerCase() == code.toLowerCase();
    }).toList();

    if (matched.isNotEmpty) {
      final product = matched.first;
      c.addProductToCart(product);
      _searchCtrl.clear();
      c.setSearchQuery('');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added ${product.name} to cart (₹${product.sellingPrice.toStringAsFixed(0)})',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: EzoColors.success,
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barcode / SKU "$code" not found in inventory.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: EzoColors.warning,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '+ Register SKU',
            textColor: Colors.white,
            onPressed: () => _showAddProductQuickDialog(context, c, initialBarcode: code),
          ),
        ),
      );
    }
  }

  void _showCameraBarcodeScannerModal(BuildContext context, PosBillingController c) {
    bool isTorchOn = false;
    bool isFrontCamera = false;
    bool continuousScan = true;
    final manualScanCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 14,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header with Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Phone Barcode Scanner',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Flash / Torch Toggle
                        IconButton(
                          icon: Icon(
                            isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                            color: isTorchOn ? Colors.amber : Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'Flashlight',
                          onPressed: () {
                            setModalState(() => isTorchOn = !isTorchOn);
                          },
                        ),
                        // Flip Camera Toggle
                        IconButton(
                          icon: Icon(
                            LucideIcons.switchCamera,
                            color: isFrontCamera ? EzoColors.primary : Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'Switch Camera',
                          onPressed: () {
                            setModalState(() => isFrontCamera = !isFrontCamera);
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Simulated Camera Viewport
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTorchOn ? Colors.amber.withValues(alpha: 0.6) : Colors.white12,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Grid / Viewfinder reticle
                      Center(
                        child: Container(
                          width: 220,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF10B981), width: 2),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF10B981).withValues(alpha: 0.05),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Laser Red Scanning Line
                              Container(
                                height: 2,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                child: Text(
                                  'Align Barcode Inside Box',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Lens Label Indicator
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isFrontCamera ? 'Front Camera (HD)' : 'Rear Main Camera (Auto-Focus)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Barcode Test Triggers
                Text(
                  'Quick-Tap to Test Barcode Scans (In-Stock Items):',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTestBarcodeChip('Tata Salt', '8901030383794', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Fortune Oil', '8906007280145', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Maggi Noodles', '8901030383799', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Aashirvaad Atta', '8901030383792', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Parle-G', '8901030383798', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Dettol Soap', '8901030383800', c, continuousScan, ctx),
                    _buildTestBarcodeChip('Unknown SKU', '8909999999999', c, continuousScan, ctx),
                  ],
                ),
                const SizedBox(height: 14),

                // Manual Barcode Input Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: manualScanCtrl,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter or scan barcode number...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              if (!continuousScan) Navigator.pop(ctx);
                              _handleBarcodeScan(val, c);
                              manualScanCtrl.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final val = manualScanCtrl.text.trim();
                        if (val.isNotEmpty) {
                          if (!continuousScan) Navigator.pop(ctx);
                          _handleBarcodeScan(val, c);
                          manualScanCtrl.clear();
                        }
                      },
                      child: Text(
                        'Add Item',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Continuous Scanning Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Continuous Scanning Mode (Rapid Checkout)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                    Switch.adaptive(
                      value: continuousScan,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setModalState(() => continuousScan = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestBarcodeChip(
    String label,
    String barcode,
    PosBillingController c,
    bool continuousScan,
    BuildContext modalCtx,
  ) {
    return ActionChip(
      backgroundColor: const Color(0xFF1F2937),
      side: const BorderSide(color: Colors.white12),
      avatar: const Icon(LucideIcons.barcode, size: 14, color: Color(0xFF10B981)),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      onPressed: () {
        if (!continuousScan) Navigator.pop(modalCtx);
        _handleBarcodeScan(barcode, c);
      },
    );
  }

  void _showCustomerSelectorModal(BuildContext context, PosBillingController c) {
    final searchCustCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = searchCustCtrl.text.trim().toLowerCase();
          final allCustomers = c.repository.getCustomerParties();
          final filtered = allCustomers.where((cust) {
            if (query.isEmpty) return true;
            return cust.name.toLowerCase().contains(query) ||
                cust.phone.contains(query) ||
                cust.gstin.toLowerCase().contains(query);
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 14,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
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
                const SizedBox(height: 12),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Customer / Khata (ग्राहक)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EzoColors.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EzoColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.userPlus, size: 14),
                      label: Text(
                        '+ New Customer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddCustomerDialog(context, c);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: EzoColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EzoColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(LucideIcons.search, size: 16, color: EzoColors.textMuted),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchCustCtrl,
                          onChanged: (_) => setSheetState(() {}),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search customer by name or phone...',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EzoColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Walk-in / Cash Customer Option
                InkWell(
                  onTap: () {
                    c.setCustomer(null);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.selectedCustomer == null
                          ? EzoColors.primary.withValues(alpha: 0.1)
                          : EzoColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.selectedCustomer == null ? EzoColors.primary : EzoColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.selectedCustomer == null
                                ? EzoColors.primary.withValues(alpha: 0.2)
                                : EzoColors.border.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.users,
                            size: 16,
                            color: c.selectedCustomer == null ? EzoColors.primary : EzoColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash Customer (Walk-in / नकद ग्राहक)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: EzoColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Standard over-the-counter retail checkout (No credit ledger)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: EzoColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (c.selectedCustomer == null)
                          const Icon(LucideIcons.checkCircle2, size: 18, color: EzoColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Registered Customers List
                Text(
                  'Registered Customer Accounts (${filtered.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: EzoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.userX, size: 32, color: EzoColors.textMuted),
                              const SizedBox(height: 8),
                              Text(
                                'No matching customer found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: EzoColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                icon: const Icon(LucideIcons.userPlus, size: 14),
                                label: const Text('Add This Customer Now'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showAddCustomerDialog(
                                    context,
                                    c,
                                    initialName: searchCustCtrl.text.trim(),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, _) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final cust = filtered[idx];
                            final isSelected = c.selectedCustomer?.id == cust.id;
                            final hasUdhaar = cust.netBalance > 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? EzoColors.primary
                                    : EzoColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : EzoColors.primary,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cust.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: EzoColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (cust.gstin.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: EzoColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'GST',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: EzoColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    cust.phone.isNotEmpty ? cust.phone : 'No Phone',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: EzoColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: GoogleFonts.plusJakartaSans(color: EzoColors.textMuted),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    hasUdhaar
                                        ? 'Udhaar: ₹${cust.netBalance.toStringAsFixed(0)} Due'
                                        : 'Khata: ₹0 Clear',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: hasUdhaar ? EzoColors.warning : EzoColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(LucideIcons.checkCircle2, color: EzoColors.primary, size: 18)
                                  : const Icon(LucideIcons.chevronRight, size: 14, color: EzoColors.textMuted),
                              onTap: () {
                                c.setCustomer(cust);
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
      ),
    );
  }

  void _showAddCustomerDialog(
    BuildContext context,
    PosBillingController c, {
    String? initialName,
  }) {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final phoneCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final stateCodeCtrl = TextEditingController(text: '27');
    final openingBalCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(LucideIcons.userPlus, size: 18, color: EzoColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add New Customer (नया ग्राहक)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Customer Full Name *',
                  hintText: 'e.g. Ramesh Kumar, Sunita Verma',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Phone Number *',
                  hintText: '10-digit mobile number for WhatsApp receipts',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gstinCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'GSTIN (Optional, for B2B billing)',
                  hintText: 'e.g. 27ABCDE1234F1Z5',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stateCodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'State Code',
                        hintText: '27 (MH), 07 (DL), 09 (UP)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: openingBalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Opening Udhaar (₹)',
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
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
              backgroundColor: EzoColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter customer name')),
                );
                return;
              }

              final phone = phoneCtrl.text.trim();
              final gstin = gstinCtrl.text.trim();
              final stateCode = stateCodeCtrl.text.trim().isNotEmpty ? stateCodeCtrl.text.trim() : '27';
              final opening = double.tryParse(openingBalCtrl.text.trim()) ?? 0.0;

              final newCust = PartyAccount(
                id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                phone: phone,
                gstin: gstin,
                stateCode: stateCode,
                partyType: PartyType.customer,
                openingBalance: opening,
                creditLimit: 10000.0,
              );

              await c.repository.saveParty(newCust);
              c.setCustomer(newCust);
              if (ctx.mounted) Navigator.pop(ctx);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer "$name" added & linked to active bill!'),
                    backgroundColor: EzoColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save & Link to Bill'),
          ),
        ],
      ),
    );
  }
}
