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
    final locale = LocaleController();

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

              // Search Bar
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: locale.tr('searchProduct'),
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textMuted),
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

        // Product Grid
        Expanded(
          child: GridView.builder(
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

          // Walk-in Customer Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EzoColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EzoColors.border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.user, size: 16, color: EzoColors.textSecondary),
                  const SizedBox(width: 8),
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
                          'Tap to link registered customer / Khata',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: EzoColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 14, color: EzoColors.textMuted),
                ],
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
}
