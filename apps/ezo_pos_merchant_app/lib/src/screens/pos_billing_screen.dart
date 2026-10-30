import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';
import '../controllers/pos_billing_controller.dart';
import '../theme/ezo_theme.dart';
import '../widgets/barcode_scanner_modal.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/weighing_scale_modal.dart';
import 'receipt_preview_modal.dart';

class PosBillingScreen extends StatefulWidget {
  final PosBillingController controller;

  const PosBillingScreen({super.key, required this.controller});

  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _rootFocusNode = FocusNode();
  String _hardwareScanBuffer = '';
  DateTime _lastScanKeystroke = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  void _onKeyReceived(KeyEvent event, PosBillingController c) {
    if (event is! KeyDownEvent) return;

    // Hotkey F12: Save & Print
    if (event.logicalKey == LogicalKeyboardKey.f12) {
      if (c.cartLines.isNotEmpty) {
        _handleSaveAndPrint(context, c);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart is empty. Add products before printing (F12).'),
            backgroundColor: EzoColors.warning,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // Hotkey F4: Kirana Numpad
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _showKiranaNumpadModal(context, c);
      return;
    }

    // Hotkey F8: Park / Hold Sale
    if (event.logicalKey == LogicalKeyboardKey.f8) {
      if (c.cartLines.isNotEmpty) {
        c.holdCurrentSale();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏸️ Bill parked in queue! (${c.heldSales.length} held)'),
            backgroundColor: EzoColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    // External barcode scanner sends burst of keys in < 400ms followed by Enter
    if (now.difference(_lastScanKeystroke).inMilliseconds > 400) {
      _hardwareScanBuffer = '';
    }
    _lastScanKeystroke = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_hardwareScanBuffer.trim().isNotEmpty) {
        final code = _hardwareScanBuffer.trim();
        _hardwareScanBuffer = '';
        _handleBarcodeScan(code, c);
      }
    } else {
      final char = event.character;
      if (char != null && char.isNotEmpty && RegExp(r'[0-9a-zA-Z\-_]').hasMatch(char)) {
        _hardwareScanBuffer += char;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return KeyboardListener(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: (event) => _onKeyReceived(event, c),
      child: ListenableBuilder(
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
      ),
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
              // Row: GST Mode toggle & Custom Fields (Horizontally scrollable for responsiveness)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Industry Vertical Mode Switcher Pill
                    _buildVerticalSwitcherPill(context, c),
                    const SizedBox(width: 8),

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
                    const SizedBox(width: 8),

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

                  // Parked Bills / Held Queue Indicator (Always accessible)
                  InkWell(
                    onTap: () => _showParkedBillsModal(context, c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.heldSales.isNotEmpty ? EzoColors.warningBg : EzoColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: c.heldSales.isNotEmpty
                              ? EzoColors.warning.withValues(alpha: 0.5)
                              : EzoColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.pauseCircle,
                            size: 13,
                            color: c.heldSales.isNotEmpty ? EzoColors.warning : EzoColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.heldSales.isNotEmpty ? 'Held (${c.heldSales.length})' : 'Held (0)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.heldSales.isNotEmpty ? EzoColors.warning : EzoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Kirana Quick Numpad Button
                  InkWell(
                    onTap: () => _showKiranaNumpadModal(context, c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.calculator, size: 13, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            'Numpad',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.purple,
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

        // Dynamic Industry Vertical Action Bar
        _buildVerticalSpecificActionBar(context, c),

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: EzoColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? ProductImagePicker.buildThumbnail(
                            item.imageUrl,
                            width: 26,
                            height: 26,
                          )
                        : Center(
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
                builder: (ctx) => _buildMobileCartSheet(ctx, c, isBottomSheet: true),
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

  Widget _buildMobileCartSheet(BuildContext context, PosBillingController c, {bool isBottomSheet = false}) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: EzoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (visible on mobile bottom sheet)
          if (isBottomSheet)
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                if (c.cartLines.isNotEmpty)
                  InkWell(
                    onTap: () {
                      c.clearCart();
                      if (isBottomSheet && context.mounted) {
                        Navigator.pop(context);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cart cleared successfully'),
                          backgroundColor: EzoColors.textSecondary,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Clear All Cart',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Customer / Khata Selection Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: c.cartLines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.shoppingCart, size: 36, color: EzoColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Cart is empty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: EzoColors.textMuted,
                          ),
                        ),
                        Text(
                          'Scan barcode or tap items in catalog to add',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textDisabled),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: c.cartLines.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final line = c.cartLines[idx];
                      final prod = c.repository.getProduct(line.productId);
                      final prodName = prod?.name ?? line.itemName;

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
                                  const SizedBox(height: 2),
                                  InkWell(
                                    onTap: () => _showEditLinePriceDialog(context, c, idx, line),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 4,
                                      children: [
                                        Text(
                                          '₹${line.unitSellingPrice.toStringAsFixed(2)} × ${line.quantity % 1 == 0 ? line.quantity.toInt() : line.quantity.toStringAsFixed(3)} = ₹${line.totalAmount.toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: EzoColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (line.lineDiscountAmount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: EzoColors.successBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '-₹${line.lineDiscountAmount.toStringAsFixed(0)} disc',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: EzoColors.success,
                                              ),
                                            ),
                                          ),
                                        const Icon(LucideIcons.pencil, size: 10, color: EzoColors.primary),
                                        if (prod?.unit == ItemUnit.kg || c.currentProfile.industryVertical == IndustryVertical.kiranaGrocery)
                                          InkWell(
                                            onTap: () {
                                              WeighingScaleModal.show(
                                                context,
                                                targetCartLineIndex: idx,
                                                targetItemName: prodName,
                                                onWeightApplied: (wt) => c.updateCartLineQty(idx, wt),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(LucideIcons.scale, size: 9, color: Color(0xFF1E88E5)),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Weigh',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF1E40AF),
                                                    ),
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
                                    line.quantity % 1 == 0 ? '${line.quantity.toInt()}' : line.quantity.toStringAsFixed(2),
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
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 15, color: EzoColors.error),
                              tooltip: 'Remove Item',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              onPressed: () => c.removeCartLine(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Settlement Mode Selector + Tax Breakdown + Action Buttons
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: EzoColors.surfaceSecondary,
              border: Border(top: BorderSide(color: EzoColors.border, width: 1)),
            ),
            child: Column(
              children: [
                // Cash vs UPI vs Udhaar Toggle Segment
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: EzoColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EzoColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildSettlementModeChip(c, SettlementMode.cash, 'Cash', LucideIcons.banknote),
                      const SizedBox(width: 4),
                      _buildSettlementModeChip(c, SettlementMode.upiQr, 'UPI QR', LucideIcons.qrCode),
                      const SizedBox(width: 4),
                      _buildSettlementModeChip(c, SettlementMode.creditUdhaar, 'Udhaar', LucideIcons.bookUser),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Taxable Subtotal', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EzoColors.textSecondary)),
                    Text('₹${c.taxableSubtotal.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('GST (CGST+SGST/IGST)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EzoColors.textSecondary)),
                    Text('₹${c.totalTax.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (c.totalCustomerSavings > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎉 Total Customer Savings', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: EzoColors.success)),
                      Text('₹${c.totalCustomerSavings.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: EzoColors.success)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GRAND TOTAL',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EzoColors.textPrimary),
                    ),
                    Text(
                      '₹${c.grandTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: EzoColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Vertical KOT Dispatch (Restaurant Mode)
                if (c.currentProfile.industryVertical == IndustryVertical.restaurantCafe) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSendKot(context, c),
                      icon: const Icon(LucideIcons.utensilsCrossed, size: 14),
                      label: Text(
                        '🍳 Send / Print KOT (${c.selectedTable})',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 4 Action Buttons: Hold Sale, UPI QR, Print Bill (F12), Udhaar
                Row(
                  children: [
                    // Hold Sale Button
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final success = c.holdCurrentSale();
                          if (success) {
                            if (isBottomSheet && context.mounted) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⏸️ Bill parked in queue! (${c.heldSales.length} held)'),
                                backgroundColor: EzoColors.warning,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.pauseCircle, size: 13),
                        label: const Text('Hold (F8)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EzoColors.warning,
                          side: const BorderSide(color: EzoColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // UPI QR Trigger Button
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => _showUpiQrPaymentDialog(context, c),
                        icon: const Icon(LucideIcons.qrCode, size: 13),
                        label: const Text('UPI QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(color: Color(0xFF0D9488)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // Save & Print Button (F12)
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSaveAndPrint(context, c, isBottomSheet: isBottomSheet),
                        icon: const Icon(LucideIcons.printer, size: 14),
                        label: Text(
                          c.settlementMode == SettlementMode.creditUdhaar ? 'Save Udhaar (F12)' : 'Save & Print (F12)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.settlementMode == SettlementMode.creditUdhaar
                              ? const Color(0xFFEA580C)
                              : EzoColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
    return _buildMobileCartSheet(context, c, isBottomSheet: false);
  }

  Widget _buildSettlementModeChip(PosBillingController c, SettlementMode mode, String label, IconData icon) {
    final isSelected = c.settlementMode == mode;
    Color activeColor = EzoColors.primary;
    if (mode == SettlementMode.creditUdhaar) activeColor = const Color(0xFFEA580C);
    if (mode == SettlementMode.upiQr) activeColor = const Color(0xFF0D9488);

    return Expanded(
      child: InkWell(
        onTap: () async {
          if (mode == SettlementMode.creditUdhaar) {
            if (c.selectedCustomer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select or add a Customer for Udhaar (Credit) billing!'),
                  backgroundColor: Color(0xFFEA580C),
                  duration: Duration(seconds: 2),
                ),
              );
              await _showCustomerSelectorModal(context, c);
              if (c.selectedCustomer == null) {
                c.setSettlementMode(SettlementMode.cash);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No customer selected. Billing remains in Cash mode.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
                return;
              }
            }
            c.setSettlementMode(SettlementMode.creditUdhaar);
          } else if (mode == SettlementMode.upiQr) {
            c.setSettlementMode(mode);
            _showUpiQrPaymentDialog(context, c);
          } else {
            c.setSettlementMode(mode);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13, color: isSelected ? activeColor : EzoColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? activeColor : EzoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveAndPrint(BuildContext context, PosBillingController c, {bool isBottomSheet = false}) async {
    if (c.cartLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add products before printing (F12).'),
          backgroundColor: EzoColors.warning,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (c.settlementMode == SettlementMode.creditUdhaar && c.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a Customer before issuing Udhaar credit!'),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      _showCustomerSelectorModal(context, c);
      return;
    }

    final invoice = await c.commitInvoice();
    if (context.mounted) {
      if (isBottomSheet) {
        Navigator.pop(context);
      }
      ReceiptPreviewModal.show(
        context,
        invoice: invoice,
        storeProfile: c.currentProfile,
      );
    }
  }

  void _showUpiQrPaymentDialog(BuildContext context, PosBillingController c) {
    final store = c.currentProfile;
    final upiId = store.upiId.isNotEmpty ? store.upiId : '${store.phone}@upi';
    final amount = c.grandTotal;

    final upiUri = UpiQrGenerator.buildUpiPaymentUri(
      merchantUpiId: upiId,
      merchantName: store.storeName,
      amount: amount,
      note: 'POS Bill Payment',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EzoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.qrCode, color: Color(0xFF0D9488), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan & Pay via UPI',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    store.storeName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Column(
                children: [
                  Text(
                    'Exact Bill Total Locked',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF0D9488), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D9488), width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.qrCode, size: 72, color: Color(0xFF0D9488)),
                    const SizedBox(height: 6),
                    Text(
                      'NPCI DYNAMIC UPI QR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'UPI VPA: $upiId',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: EzoColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(LucideIcons.copy, size: 14),
            label: const Text('Copy Intent'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: upiUri));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UPI Intent link copied!'),
                  backgroundColor: Color(0xFF0D9488),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: EzoColors.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(LucideIcons.check, size: 14),
            label: const Text('Received & Print'),
            onPressed: () async {
              Navigator.pop(ctx);
              c.setSettlementMode(SettlementMode.upiQr);
              _handleSaveAndPrint(context, c);
            },
          ),
        ],
      ),
    );
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
    String imageUrl = '';

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
                ProductImagePicker(
                  currentImageUrl: imageUrl,
                  onImageChanged: (url) => setDlgState(() => imageUrl = url),
                ),
                const SizedBox(height: 10),
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
                  decoration: InputDecoration(
                    labelText: 'Barcode / SKU Code',
                    hintText: 'Leave blank to auto-generate',
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.camera, color: EzoColors.primary, size: 18),
                      tooltip: 'Scan Barcode with Camera / Scanner',
                      onPressed: () {
                        BarcodeScannerModal.show(
                          context,
                          onBarcodeScanned: (code) {
                            setDlgState(() => skuCtrl.text = code);
                          },
                        );
                      },
                    ),
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
                  initialValue: gstVal,
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
                  imageUrl: imageUrl,
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
    const staples = [
      ProductItem(
        id: 'p_atta_01',
        name: 'Aashirvaad Shudh Chakki Atta 5kg',
        regionalName: 'आशीर्वाद आटा ५ कि.ग्रा.',
        skuCode: 'SKU-ATTA-005',
        barcode: '8901030383792',
        shortCode: '3',
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
        shortCode: '5',
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
        shortCode: '2',
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
        shortCode: '4',
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
        shortCode: '1',
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
        shortCode: '10',
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
        shortCode: '6',
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
        shortCode: '7',
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
        shortCode: '8',
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
        shortCode: '9',
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

    final product = c.findProductByCode(code);

    if (product != null) {
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
    BarcodeScannerModal.show(
      context,
      title: 'Phone Barcode Scanner',
      onBarcodeScanned: (code) => _handleBarcodeScan(code, c),
    );
  }

  Future<void> _showCustomerSelectorModal(BuildContext context, PosBillingController c) async {
    final searchCustCtrl = TextEditingController();

    await showModalBottomSheet(
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
                    c.setSettlementMode(SettlementMode.cash);
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

  void _showEditLinePriceDialog(
    BuildContext context,
    PosBillingController c,
    int index,
    InvoiceLineItem line,
  ) {
    final canEdit = c.currentStaff?.canEditPrices ?? true;
    final canGiveDiscounts = c.currentStaff?.canGiveDiscounts ?? true;
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Your staff role does not have permission to override prices at the counter.'),
          backgroundColor: EzoColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final priceCtrl = TextEditingController(text: line.unitSellingPrice.toStringAsFixed(2));
    final discountCtrl = TextEditingController(text: line.lineDiscountAmount > 0 ? line.lineDiscountAmount.toStringAsFixed(2) : '0.00');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: EzoColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(LucideIcons.tag, size: 18, color: EzoColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Override Rate & Line Discount',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.itemName,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  'Original MRP: ₹${line.mrp.toStringAsFixed(2)}  •  Current: ₹${line.unitSellingPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price Per Unit (₹) *',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: discountCtrl,
                  enabled: canGiveDiscounts,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: canGiveDiscounts ? 'Line Discount Amount (₹)' : 'Line Discount (Role Prohibited)',
                    prefixText: '₹ ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quick Shortcuts:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: EzoColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      label: const Text('₹5 Off'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          discountCtrl.text = '5.00';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('₹10 Off'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          discountCtrl.text = '10.00';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('5% Off Rate'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          priceCtrl.text = (line.mrp * 0.95).toStringAsFixed(2);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('10% Off Rate'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          priceCtrl.text = (line.mrp * 0.90).toStringAsFixed(2);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Wholesale (-15%)'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          priceCtrl.text = (line.mrp * 0.85).toStringAsFixed(2);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Reset'),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                      onPressed: () {
                        setDlgState(() {
                          priceCtrl.text = line.mrp.toStringAsFixed(2);
                          discountCtrl.text = '0.00';
                        });
                      },
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
              onPressed: () {
                final newRate = double.tryParse(priceCtrl.text.trim()) ?? line.unitSellingPrice;
                final newDisc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
                if (newRate >= 0 && newDisc >= 0) {
                  c.updateCartLinePriceAndDiscount(index, newRate, newDisc);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated ${line.itemName}: Rate ₹${newRate.toStringAsFixed(2)}, Disc ₹${newDisc.toStringAsFixed(2)}'),
                      backgroundColor: EzoColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showKiranaNumpadModal(BuildContext context, PosBillingController c) {
    String numpadCode = '';
    double selectedQty = 1.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPadState) {
          final matchedProduct = numpadCode.isNotEmpty ? c.findProductByCode(numpadCode) : null;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
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
                      Row(
                        children: [
                          const Icon(LucideIcons.calculator, size: 18, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Kirana Numpad (त्वरित शॉर्ट-कोड)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: EzoColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: EzoColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Input Display & Live Match Preview Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: matchedProduct != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: matchedProduct != null
                            ? EzoColors.success
                            : EzoColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EzoColors.border),
                          ),
                          child: Center(
                            child: Text(
                              numpadCode.isEmpty ? '—' : numpadCode,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: matchedProduct != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      matchedProduct.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: EzoColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₹${matchedProduct.sellingPrice.toStringAsFixed(0)} / ${matchedProduct.unit.label}  •  Stock: ${matchedProduct.currentStock.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: EzoColors.success,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  numpadCode.isEmpty
                                      ? 'Type 1-4 digit short-code (e.g. 1, 2, 3)'
                                      : 'No product matched with code #$numpadCode',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: EzoColors.textMuted,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quantity Multipliers Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity Multiplier:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: EzoColors.textSecondary),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [0.5, 1.0, 2.0, 5.0].map((q) {
                          final isSel = selectedQty == q;
                          return ChoiceChip(
                            label: Text(q == 0.5 ? '½' : '${q.toInt()}x'),
                            selected: isSel,
                            selectedColor: Colors.purple,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : EzoColors.textPrimary,
                            ),
                            onSelected: (s) => setPadState(() => selectedQty = q),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4x3 Keypad Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.1,
                    children: [
                      _buildNumpadDigit('1', () => setPadState(() => numpadCode += '1')),
                      _buildNumpadDigit('2', () => setPadState(() => numpadCode += '2')),
                      _buildNumpadDigit('3', () => setPadState(() => numpadCode += '3')),
                      _buildNumpadDigit('4', () => setPadState(() => numpadCode += '4')),
                      _buildNumpadDigit('5', () => setPadState(() => numpadCode += '5')),
                      _buildNumpadDigit('6', () => setPadState(() => numpadCode += '6')),
                      _buildNumpadDigit('7', () => setPadState(() => numpadCode += '7')),
                      _buildNumpadDigit('8', () => setPadState(() => numpadCode += '8')),
                      _buildNumpadDigit('9', () => setPadState(() => numpadCode += '9')),
                      _buildNumpadDigit('00', () => setPadState(() => numpadCode += '00')),
                      _buildNumpadDigit('0', () => setPadState(() => numpadCode += '0')),
                      // Clear
                      InkWell(
                        onTap: () => setPadState(() => numpadCode = ''),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Center(
                            child: Text(
                              'CLEAR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: EzoColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dedicated Full-Width ADD / ENTER Button
                  InkWell(
                    onTap: () {
                      if (matchedProduct != null) {
                        c.addProductToCart(matchedProduct, qty: selectedQty);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${selectedQty}x ${matchedProduct.name} to bill!'),
                            backgroundColor: EzoColors.success,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        setPadState(() {
                          numpadCode = '';
                          selectedQty = 1.0;
                        });
                      } else if (numpadCode.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product with code #$numpadCode not found in catalog.'),
                            backgroundColor: EzoColors.warning,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: matchedProduct != null ? EzoColors.success : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: matchedProduct != null
                            ? [
                                BoxShadow(
                                  color: EzoColors.success.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.check, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              matchedProduct != null
                                  ? '↵ ADD ${matchedProduct.name} (${selectedQty == 0.5 ? "½" : "${selectedQty.toInt()}x"})'
                                  : '↵ ENTER / ADD TO BILL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kirana Short-Code Quick Cheatsheet
                  Text(
                    'Tap Any Kirana Staple Short-Code:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EzoColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildKiranaQuickCodeChip('1: Sugar', '1', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('2: Rice', '2', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('3: Atta', '3', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('4: Salt', '4', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('5: Oil', '5', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('6: Milk', '6', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('7: Parle-G', '7', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('8: Maggi', '8', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('9: Soap', '9', setPadState, (c) => numpadCode = c),
                      _buildKiranaQuickCodeChip('10: Tea', '10', setPadState, (c) => numpadCode = c),
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

  Widget _buildNumpadDigit(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: EzoColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EzoColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EzoColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKiranaQuickCodeChip(
    String label,
    String code,
    StateSetter setPadState,
    void Function(String) setCode,
  ) {
    return ActionChip(
      backgroundColor: Colors.purple.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.purple.withValues(alpha: 0.2)),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.purple,
        ),
      ),
      onPressed: () {
        setPadState(() {
          setCode(code);
        });
      },
    );
  }

  void _showParkedBillsModal(BuildContext context, PosBillingController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: EzoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setQueueState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      const Icon(LucideIcons.pauseCircle, size: 20, color: EzoColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        'Parked / Held Bills Queue (${c.heldSales.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EzoColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: EzoColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (c.heldSales.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(LucideIcons.pauseCircle, size: 40, color: EzoColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No parked bills in queue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: EzoColors.textSecondary,
                          ),
                        ),
                        Text(
                          'You can hold an active bill to serve the next customer without losing cart items.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: EzoColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: c.heldSales.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final held = c.heldSales[idx];
                      final timeStr =
                          '${held.heldAt.hour.toString().padLeft(2, '0')}:${held.heldAt.minute.toString().padLeft(2, '0')}';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EzoColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EzoColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: EzoColors.warningBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(LucideIcons.receipt, color: EzoColors.warning, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        held.notes,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: EzoColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: EzoColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${held.customer?.name ?? "Walk-in Customer"}  •  ${held.totalItemsCount} items (${held.totalQuantity.toStringAsFixed(0)} units)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: EzoColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${held.grandTotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: EzoColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Resume Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EzoColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(LucideIcons.play, size: 13),
                              label: Text(
                                'Resume',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                c.resumeHeldSale(held.id);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Resumed parked bill #${held.notes}!'),
                                    backgroundColor: EzoColors.success,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            // Delete from queue
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, size: 16, color: EzoColors.error),
                              onPressed: () {
                                c.deleteHeldSale(held.id);
                                setQueueState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // INDUSTRY VERTICAL DYNAMIC MODES & ACTION BARS
  // =========================================================================

  Widget _buildVerticalSwitcherPill(BuildContext context, PosBillingController c) {
    final vColor = _getVerticalColor(c.currentProfile.industryVertical);
    final vIcon = _getVerticalIcon(c.currentProfile.industryVertical);
    final vTitle = _getVerticalTitle(c.currentProfile.industryVertical);

    return InkWell(
      onTap: () => _showVerticalSwitcherModal(context, c),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: vColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: vColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(vIcon, size: 14, color: vColor),
            const SizedBox(width: 6),
            Text(
              vTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: vColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 13, color: vColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalSpecificActionBar(BuildContext context, PosBillingController c) {
    switch (c.currentProfile.industryVertical) {
      case IndustryVertical.restaurantCafe:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            border: Border(bottom: BorderSide(color: const Color(0xFFFDBA74).withValues(alpha: 0.5), width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(LucideIcons.utensilsCrossed, size: 15, color: Color(0xFFEA580C)),
                const SizedBox(width: 8),
                Text(
                  'Table / Room:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412)),
                ),
                const SizedBox(width: 10),
                Row(
                  children: ['Table 1', 'Table 2', 'Table 3', 'Table 4', 'Table 5', 'Takeaway', 'Delivery', 'Room 101', 'Room 102'].map((tbl) {
                    final isSelected = c.selectedTable == tbl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tbl),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEA580C),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF431407),
                        ),
                        onSelected: (_) => c.setSelectedTable(tbl),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );

      case IndustryVertical.pharmacyHealth:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            border: Border(bottom: BorderSide(color: Color(0xFFA7F3D0), width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(LucideIcons.pill, size: 15, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Text(
                  'Rx Pharma Mode:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showDoctorPatientDialog(context, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFA7F3D0))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.stethoscope, size: 13, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          c.patientDoctorNote != null && c.patientDoctorNote!.isNotEmpty ? c.patientDoctorNote! : '+ Patient / Doctor Note',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 13, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'Batch & 90-Day Expiry Guard Active',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case IndustryVertical.garmentsApparel:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF5FF),
            border: Border(bottom: BorderSide(color: Color(0xFFE9D5FF), width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(LucideIcons.shirt, size: 15, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text(
                  'Size:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF581C87)),
                ),
                const SizedBox(width: 6),
                ...['S', 'M', 'L', 'XL', 'XXL'].map((sz) {
                  final isSelected = c.selectedSize == sz;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => c.setGarmentAttributes(size: sz),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFD8B4FE)),
                        ),
                        child: Text(
                          sz,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF581C87),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 10),
                Text(
                  'Color:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF581C87)),
                ),
                const SizedBox(width: 6),
                ...['Std', 'Red', 'Blue', 'Black'].map((clr) {
                  final isSelected = c.selectedColor == clr;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => c.setGarmentAttributes(color: clr),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFD8B4FE)),
                        ),
                        child: Text(
                          clr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF581C87),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showBarcodeStickerPrintModal(context, c),
                  icon: const Icon(LucideIcons.tag, size: 13),
                  label: const Text('38x25mm Tag'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );

      case IndustryVertical.electronicsMobiles:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F9FF),
            border: Border(bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(LucideIcons.smartphone, size: 15, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  'Serial / 15-Digit IMEI:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showImeiPromptDialog(context, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF7DD3FC))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scanBarcode, size: 13, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          c.scannedImei != null && c.scannedImei!.isNotEmpty ? c.scannedImei! : '+ Input Device IMEI / Serial',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0369A1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.award, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        '1-Yr Warranty Cert Auto-Printed',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0369A1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case IndustryVertical.kiranaGrocery:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE), width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(LucideIcons.scale, size: 15, color: Color(0xFF1E88E5)),
                const SizedBox(width: 8),
                Text(
                  'Weighing Scale Ready:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => WeighingScaleModal.show(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.isScaleConnected ? const Color(0xFFDCFCE7) : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.isScaleConnected ? const Color(0xFF86EFAC) : const Color(0xFF93C5FD))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.isScaleConnected ? '${c.liveScaleWeightKg.toStringAsFixed(3)} KG (${c.isScaleStable ? "Live" : "Settling"})' : '1.000 KG (Live RS-232 / USB)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFF1E40AF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Units: KG | GMS | LTR | BAG',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () => _showKiranaNumpadModal(context, c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.calculator, size: 13, color: Color(0xFF1E40AF)),
                        const SizedBox(width: 4),
                        Text(
                          'Kirana Numpad (F4)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  void _showVerticalSwitcherModal(BuildContext context, PosBillingController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final verticals = IndustryVerticalInfo.getAllVerticals();
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: EzoColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏪 Switch Industry Vertical Mode',
                        style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: EzoColors.textPrimary),
                      ),
                      Text(
                        'Select a specialized retail operating mode for your counter',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EzoColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: verticals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final vInfo = verticals[idx];
                    final isCurrent = c.currentProfile.industryVertical == vInfo.vertical;
                    final vColor = _getVerticalColor(vInfo.vertical);
                    final vIcon = _getVerticalIcon(vInfo.vertical);

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmSwitchVertical(context, c, vInfo);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent ? vColor.withValues(alpha: 0.08) : EzoColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? vColor : EzoColors.border,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrent ? vColor : vColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(vIcon, color: isCurrent ? Colors.white : vColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        vInfo.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent ? vColor : EzoColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: vColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          vInfo.categoryBadge,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: vColor,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: vColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'ACTIVE',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    vInfo.subtitle,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EzoColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  void _confirmSwitchVertical(BuildContext context, PosBillingController c, IndustryVerticalInfo vInfo) {
    if (c.currentProfile.industryVertical == vInfo.vertical) return;

    final vColor = _getVerticalColor(vInfo.vertical);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getVerticalIcon(vInfo.vertical), color: vColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Switch to ${vInfo.title}',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Would you like to load pre-seeded sample products & categories for this vertical, or keep your existing catalog items?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EzoColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await c.switchIndustryVertical(vInfo.vertical, loadSampleData: false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${vInfo.title} (Catalog kept)'),
                    backgroundColor: vColor,
                  ),
                );
              }
            },
            child: Text(
              'Keep Existing Items',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: EzoColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await c.switchIndustryVertical(vInfo.vertical, loadSampleData: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚡ Switched to ${vInfo.title} and loaded sample catalog!'),
                    backgroundColor: vColor,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.sparkles, size: 15),
            label: const Text('Load Sample Catalog'),
            style: ElevatedButton.styleFrom(
              backgroundColor: vColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendKot(BuildContext context, PosBillingController c) {
    if (c.cartLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add food items before sending KOT.'), backgroundColor: EzoColors.warning),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🍳 Kitchen Order Ticket (KOT) sent for ${c.selectedTable}! (${c.cartLines.length} items)'),
        backgroundColor: const Color(0xFFEA580C),
        duration: const Duration(seconds: 3),
      ),
    );
    _showKotPreviewDialog(context, c);
  }

  void _showKotPreviewDialog(BuildContext context, PosBillingController c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.utensilsCrossed, color: Color(0xFFEA580C), size: 22),
            const SizedBox(width: 8),
            Text('Kitchen Order Ticket (KOT)', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Table: ${c.selectedTable}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF9A3412))),
                    Text('Order #${DateTime.now().minute}${DateTime.now().second}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFFC2410C))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...c.cartLines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${line.quantity.toInt()}x', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFFEA580C))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(line.itemName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Server: ${c.currentStaff?.fullName ?? "Counter 1"} • Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EzoColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🖨️ KOT slip dispatched to kitchen thermal printer!'), backgroundColor: Color(0xFFEA580C)),
              );
            },
            icon: const Icon(LucideIcons.printer, size: 14),
            label: const Text('Print Kitchen Slip'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showDoctorPatientDialog(BuildContext context, PosBillingController c) {
    final noteCtrl = TextEditingController(text: c.patientDoctorNote ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.stethoscope, color: Color(0xFF059669), size: 20),
            const SizedBox(width: 8),
            Text('Doctor / Patient Prescription', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: noteCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Patient Name & Prescribing Doctor',
            hintText: 'e.g. Ramesh Patil / Dr. Kulkarni (Reg 4920)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              c.setPatientDoctorNote(noteCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showImeiPromptDialog(BuildContext context, PosBillingController c) {
    final imeiCtrl = TextEditingController(text: c.scannedImei ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.smartphone, color: Color(0xFF0284C7), size: 20),
            const SizedBox(width: 8),
            Text('Device IMEI / Serial Number', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: imeiCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '15-Digit IMEI or Hardware Serial No',
            hintText: 'e.g. 864209048291048',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              c.setScannedImei(imeiCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
            child: const Text('Assign IMEI'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeStickerPrintModal(BuildContext context, PosBillingController c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.tag, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 8),
            Text('38x25mm Garment Barcode Sticker', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.currentProfile.storeName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Size: ${c.selectedSize} | Color: ${c.selectedColor}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                height: 36,
                color: Colors.black12,
                child: Center(
                  child: Text('||| | |||| | |||||| || |', style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 4),
              Text('TAG-GARMENT-2026', style: GoogleFonts.jetBrainsMono(fontSize: 11)),
              const SizedBox(height: 6),
              Text('MRP: ₹1,299 | Offer: ₹899', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED), fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🏷️ Sent 30 copies of 38x25mm sticker to thermal label printer!'), backgroundColor: Color(0xFF7C3AED)),
              );
            },
            icon: const Icon(LucideIcons.printer, size: 14),
            label: const Text('Print Sticker Roll'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Color _getVerticalColor(IndustryVertical v) {
    switch (v) {
      case IndustryVertical.restaurantCafe:
        return const Color(0xFFEA580C);
      case IndustryVertical.pharmacyHealth:
        return const Color(0xFF059669);
      case IndustryVertical.garmentsApparel:
        return const Color(0xFF7C3AED);
      case IndustryVertical.electronicsMobiles:
        return const Color(0xFF0284C7);
      case IndustryVertical.kiranaGrocery:
        return const Color(0xFF1E88E5);
    }
  }

  IconData _getVerticalIcon(IndustryVertical v) {
    switch (v) {
      case IndustryVertical.restaurantCafe:
        return LucideIcons.utensilsCrossed;
      case IndustryVertical.pharmacyHealth:
        return LucideIcons.pill;
      case IndustryVertical.garmentsApparel:
        return LucideIcons.shirt;
      case IndustryVertical.electronicsMobiles:
        return LucideIcons.smartphone;
      case IndustryVertical.kiranaGrocery:
        return LucideIcons.shoppingCart;
    }
  }

  String _getVerticalTitle(IndustryVertical v) {
    switch (v) {
      case IndustryVertical.restaurantCafe:
        return 'Restaurant / Cafe';
      case IndustryVertical.pharmacyHealth:
        return 'Pharmacy & Health';
      case IndustryVertical.garmentsApparel:
        return 'Garments & Apparel';
      case IndustryVertical.electronicsMobiles:
        return 'Electronics & Mobile';
      case IndustryVertical.kiranaGrocery:
        return 'Kirana & Grocery';
    }
  }
}
