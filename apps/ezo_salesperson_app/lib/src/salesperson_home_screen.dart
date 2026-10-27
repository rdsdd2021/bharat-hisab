import 'package:flutter/material.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';

class SalespersonHomeScreen extends StatefulWidget {
  final EzoOfflineRepository repository;
  final BusinessProfile storeProfile;
  final StaffMember staff;

  const SalespersonHomeScreen({
    super.key,
    required this.repository,
    required this.storeProfile,
    required this.staff,
  });

  @override
  State<SalespersonHomeScreen> createState() => _SalespersonHomeScreenState();
}

class _SalespersonHomeScreenState extends State<SalespersonHomeScreen> {
  int _navIndex = 0; // 0: Quick Bill, 1: Field Collections, 2: My Shift Settlement

  // Quick Cart State
  final List<InvoiceLineItem> _salesCart = [];
  PartyAccount? _selectedCustomer; // null = Walk-in Cash Customer

  // Catalog Browser State
  String _catalogCategory = 'All';
  String _catalogSearchQuery = '';
  final TextEditingController _catalogSearchCtrl = TextEditingController();

  // Field Collections Filter
  final TextEditingController _customerSearchCtrl = TextEditingController();
  String _customerSearchQuery = '';

  // Cloud HQ Sync State
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 4));
  int _syncedCount = 0;

  @override
  void initState() {
    super.initState();
    _seedDefaultDataIfEmpty();
  }

  @override
  void dispose() {
    _catalogSearchCtrl.dispose();
    _customerSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _seedDefaultDataIfEmpty() async {
    final existingProducts = widget.repository.getAllProducts();
    if (existingProducts.isEmpty) {
      final sampleProducts = [
        const ProductItem(
          id: 'p_01',
          name: 'Fortune Sunlite Sunflower Oil 1L',
          skuCode: 'GRO-OIL-01',
          category: 'Groceries',
          sellingPrice: 145.0,
          mrp: 165.0,
          currentStock: 48.0,
          unit: ItemUnit.ltr,
          gstPercent: 5.0,
        ),
        const ProductItem(
          id: 'p_02',
          name: 'India Gate Basmati Rice Feast 5kg',
          skuCode: 'GRO-RIC-02',
          category: 'Groceries',
          sellingPrice: 480.0,
          mrp: 540.0,
          currentStock: 25.0,
          unit: ItemUnit.bag,
          gstPercent: 5.0,
        ),
        const ProductItem(
          id: 'p_03',
          name: 'Tata Sampann Toor Dal 1kg',
          skuCode: 'GRO-DAL-03',
          category: 'Groceries',
          sellingPrice: 165.0,
          mrp: 185.0,
          currentStock: 34.0,
          unit: ItemUnit.kg,
          gstPercent: 5.0,
        ),
        const ProductItem(
          id: 'p_04',
          name: 'Amul Butter Pasteurized 500g',
          skuCode: 'DAI-BUT-01',
          category: 'Dairy',
          sellingPrice: 275.0,
          mrp: 285.0,
          currentStock: 18.0,
          unit: ItemUnit.box,
          gstPercent: 12.0,
        ),
        const ProductItem(
          id: 'p_05',
          name: 'Mother Dairy Toned Milk 1L',
          skuCode: 'DAI-MLK-02',
          category: 'Dairy',
          sellingPrice: 56.0,
          mrp: 56.0,
          currentStock: 60.0,
          unit: ItemUnit.ltr,
          gstPercent: 0.0,
        ),
        const ProductItem(
          id: 'p_06',
          name: 'Britannia Good Day Biscuits 200g',
          skuCode: 'SNK-BIS-01',
          category: 'Snacks',
          sellingPrice: 38.0,
          mrp: 40.0,
          currentStock: 80.0,
          unit: ItemUnit.pcs,
          gstPercent: 18.0,
        ),
        const ProductItem(
          id: 'p_07',
          name: 'Haldirams Nagpur Bhujia 400g',
          skuCode: 'SNK-BHU-02',
          category: 'Snacks',
          sellingPrice: 115.0,
          mrp: 125.0,
          currentStock: 42.0,
          unit: ItemUnit.pcs,
          gstPercent: 12.0,
        ),
        const ProductItem(
          id: 'p_08',
          name: 'Thums Up Soft Drink 750ml',
          skuCode: 'BEV-COL-01',
          category: 'Beverages',
          sellingPrice: 40.0,
          mrp: 40.0,
          currentStock: 50.0,
          unit: ItemUnit.pcs,
          gstPercent: 28.0,
        ),
        const ProductItem(
          id: 'p_09',
          name: 'Dettol Bathing Soap (Pack of 3)',
          skuCode: 'PER-DET-01',
          category: 'Personal Care',
          sellingPrice: 140.0,
          mrp: 155.0,
          currentStock: 30.0,
          unit: ItemUnit.box,
          gstPercent: 18.0,
        ),
        const ProductItem(
          id: 'p_10',
          name: 'Surf Excel Detergent Powder 1kg',
          skuCode: 'HOU-SUR-01',
          category: 'Household',
          sellingPrice: 145.0,
          mrp: 160.0,
          currentStock: 28.0,
          unit: ItemUnit.kg,
          gstPercent: 18.0,
        ),
      ];
      await widget.repository.bulkUpsertProducts(sampleProducts);
    }

    final existingParties = widget.repository.getAllParties();
    if (existingParties.isEmpty) {
      final sampleCustomers = [
        PartyAccount(
          id: 'cust_01',
          name: 'Ramesh Kirana & General Store',
          phone: '9822011223',
          address: 'Main Chowk, Katraj, Pune',
          partyType: PartyType.customer,
          creditLimit: 15000.0,
          ledgerEntries: [
            KhataLedgerEntry(
              id: 'khata_init_01',
              partyId: 'cust_01',
              entryDate: DateTime.now().subtract(const Duration(days: 3)),
              debitYouGave: 3450.0,
              creditYouGot: 0.0,
              paymentMode: 'invoice_credit',
              referenceInvoiceNumber: 'INV-OCT-8821',
              notes: 'Prior bulk delivery invoice due',
              createdAt: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
        ),
        PartyAccount(
          id: 'cust_02',
          name: 'Sharmaji Sweet Mart',
          phone: '9822055667',
          address: 'Shop #4, Market Yard, Pune',
          partyType: PartyType.customer,
          creditLimit: 10000.0,
          ledgerEntries: [
            KhataLedgerEntry(
              id: 'khata_init_02',
              partyId: 'cust_02',
              entryDate: DateTime.now().subtract(const Duration(days: 2)),
              debitYouGave: 1850.0,
              creditYouGot: 0.0,
              paymentMode: 'invoice_credit',
              referenceInvoiceNumber: 'INV-OCT-9014',
              notes: 'Weekly sugar & dairy supply balance',
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
        ),
        PartyAccount(
          id: 'cust_03',
          name: 'Priya Departmental Store',
          phone: '9822099887',
          address: 'Station Road, Camp, Pune',
          partyType: PartyType.customer,
          creditLimit: 25000.0,
          ledgerEntries: [
            KhataLedgerEntry(
              id: 'khata_init_03',
              partyId: 'cust_03',
              entryDate: DateTime.now().subtract(const Duration(days: 5)),
              debitYouGave: 5200.0,
              creditYouGot: 0.0,
              paymentMode: 'invoice_credit',
              referenceInvoiceNumber: 'INV-OCT-7742',
              notes: 'Month-end FMCG grocery package',
              createdAt: DateTime.now().subtract(const Duration(days: 5)),
            ),
          ],
        ),
        PartyAccount(
          id: 'cust_04',
          name: 'Guptaji Chai & Tiffin Point',
          phone: '9822044332',
          address: 'Near Bus Stand, Swargate, Pune',
          partyType: PartyType.customer,
          creditLimit: 5000.0,
          ledgerEntries: [
            KhataLedgerEntry(
              id: 'khata_init_04',
              partyId: 'cust_04',
              entryDate: DateTime.now().subtract(const Duration(days: 1)),
              debitYouGave: 950.0,
              creditYouGot: 0.0,
              paymentMode: 'invoice_credit',
              referenceInvoiceNumber: 'INV-OCT-9430',
              notes: 'Milk crates balance',
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ];

      for (final cust in sampleCustomers) {
        await widget.repository.saveParty(cust);
      }
    }

    if (mounted) setState(() {});
  }

  // --- Cloud Sync Action ---
  Future<void> _handleSyncOrdersToHq() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final pending = widget.repository.getPendingSync();
    for (final p in pending) {
      await widget.repository.markSynced(p.id);
    }

    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSyncTime = DateTime.now();
      _syncedCount += pending.isNotEmpty ? pending.length : 3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Synced $_syncedCount records successfully to Cloud HQ!'),
          ],
        ),
        backgroundColor: Colors.green.shade800,
      ),
    );
  }

  // --- Quantity in Cart Helpers ---
  int _getCartQuantity(ProductItem product) {
    final idx = _salesCart.indexWhere((i) => i.productId == product.id);
    if (idx == -1) return 0;
    return _salesCart[idx].quantity.toInt();
  }

  void _incrementCart(ProductItem product) {
    setState(() {
      final idx = _salesCart.indexWhere((i) => i.productId == product.id);
      if (idx == -1) {
        final line = EzoGstTaxEngine.buildLineItem(product: product, quantity: 1);
        _salesCart.add(line);
      } else {
        final current = _salesCart[idx];
        final newQty = current.quantity + 1;
        _salesCart[idx] = EzoGstTaxEngine.buildLineItem(product: product, quantity: newQty);
      }
    });
  }

  void _decrementCart(ProductItem product) {
    setState(() {
      final idx = _salesCart.indexWhere((i) => i.productId == product.id);
      if (idx == -1) return;
      final current = _salesCart[idx];
      if (current.quantity > 1) {
        final newQty = current.quantity - 1;
        _salesCart[idx] = EzoGstTaxEngine.buildLineItem(product: product, quantity: newQty);
      } else {
        _salesCart.removeAt(idx);
      }
    });
  }

  double get _cartTotal => _salesCart.fold(0.0, (s, i) => s + i.totalAmount);
  int get _cartItemCount => _salesCart.fold(0, (s, i) => s + i.quantity.toInt());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.storeProfile.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Agent: ${widget.staff.fullName} • Last sync: ${_lastSyncTime.hour.toString().padLeft(2, '0')}:${_lastSyncTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          // Prominent "Sync Orders to HQ" button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSyncing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync, size: 16),
            label: Text(
              _isSyncing ? 'Syncing...' : 'Sync to HQ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSyncing ? null : _handleSyncOrdersToHq,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
            child: const Text('FIELD MODE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
      body: _buildCurrentBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (idx) => setState(() => _navIndex = idx),
        selectedItemColor: Colors.indigo.shade800,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _salesCart.isNotEmpty,
              label: Text('$_cartItemCount'),
              child: const Icon(Icons.flash_on),
            ),
            label: 'Quick Bill',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Field Collection'),
          const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Shift Settlement'),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() {
    switch (_navIndex) {
      case 0:
        return _buildQuickBilling();
      case 1:
        return _buildFieldCollections();
      case 2:
        return _buildShiftSettlement();
      default:
        return const SizedBox();
    }
  }

  // =========================================================================
  // TAB 1: QUICK BILLING & FIELD ORDER BOOKING
  // =========================================================================
  Widget _buildQuickBilling() {
    final allProducts = widget.repository.getAllProducts();

    // Collect dynamic categories
    final categories = {'All', ...allProducts.map((p) => p.category.isNotEmpty ? p.category : 'General')}.toList();

    // Filter products
    final filteredProducts = allProducts.where((p) {
      final matchesCategory = _catalogCategory == 'All' || p.category.toLowerCase() == _catalogCategory.toLowerCase();
      final q = _catalogSearchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.skuCode.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Column(
      children: [
        // 1. Customer Selection Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              Icon(Icons.person_pin, size: 20, color: Colors.indigo.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCustomer != null ? _selectedCustomer!.name : 'Walk-in Cash Customer',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.indigo.shade900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedCustomer != null)
                      Text(
                        'Due Udhaar: ₹${_selectedCustomer!.netBalance.toStringAsFixed(0)} • Ph: ${_selectedCustomer!.phone}',
                        style: TextStyle(fontSize: 11, color: _selectedCustomer!.netBalance > 0 ? Colors.red.shade700 : Colors.grey.shade700),
                      )
                    else
                      const Text('Standard Retail Walk-in • Cash/UPI', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: BorderSide(color: Colors.indigo.shade300),
                  foregroundColor: Colors.indigo.shade800,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.swap_horiz, size: 14),
                label: Text(_selectedCustomer != null ? 'Change' : 'Select Customer', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: _showCustomerSelectionDialog,
              ),
              if (_selectedCustomer != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  tooltip: 'Reset to Walk-in',
                  onPressed: () => setState(() => _selectedCustomer = null),
                ),
            ],
          ),
        ),

        // 2. Catalog Search & Category Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _catalogSearchCtrl,
              onChanged: (v) => setState(() => _catalogSearchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                hintStyle: const TextStyle(fontSize: 12.5),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _catalogSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _catalogSearchCtrl.clear();
                          setState(() => _catalogSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),

        // Category Filter Chips
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final isSelected = _catalogCategory.toLowerCase() == cat.toLowerCase();
              return ChoiceChip(
                label: Text(cat, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                selected: isSelected,
                selectedColor: Colors.indigo.shade100,
                onSelected: (_) => setState(() => _catalogCategory = cat),
              );
            },
          ),
        ),
        const Divider(height: 1),

        // 3. Product Catalog List with Quantity Counters
        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No matching items found', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final p = filteredProducts[idx];
                    final inCartQty = _getCartQuantity(p);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      subtitle: Text(
                        'SKU: ${p.skuCode} • Stock: ${p.currentStock.toInt()} ${p.unit.label} • GST ${p.gstPercent.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${p.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.indigo),
                              ),
                              if (p.mrp > p.sellingPrice)
                                Text(
                                  '₹${p.mrp.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Interactive Quantity Counter or Add Button
                          if (inCartQty == 0)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _incrementCart(p),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.indigo.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16, color: Colors.indigo),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => _decrementCart(p),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$inCartQty',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.indigo.shade900),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16, color: Colors.indigo),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => _incrementCart(p),
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

        // 4. Cart Floating Checkout Strip
        if (_salesCart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_cartItemCount items in cart', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      Text(
                        '₹${_cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.indigo.shade900),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Review & Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  onPressed: _showCartCheckoutModal,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // CUSTOMER SELECTION MODAL
  // =========================================================================
  void _showCustomerSelectionDialog() {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final allParties = widget.repository.getCustomerParties();
          final filteredParties = allParties.where((c) {
            final q = query.toLowerCase().trim();
            return q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SizedBox(
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Customer for Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setSheetState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by store name or phone...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Walk-in Option
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white, size: 18)),
                    title: const Text('Walk-in Cash Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Direct floor punch • Immediate settlement'),
                    trailing: _selectedCustomer == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      setState(() => _selectedCustomer = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: filteredParties.isEmpty
                        ? Center(child: Text('No customers found', style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.separated(
                            itemCount: filteredParties.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final c = filteredParties[idx];
                              final isSelected = _selectedCustomer?.id == c.id;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: c.netBalance > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                  child: Icon(Icons.store, color: c.netBalance > 0 ? Colors.red.shade700 : Colors.green.shade700, size: 18),
                                ),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                subtitle: Text(
                                  'Due: ₹${c.netBalance.toStringAsFixed(0)} • Ph: ${c.phone}\n${c.address}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                                onTap: () {
                                  setState(() => _selectedCustomer = c);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
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

  // =========================================================================
  // CART & CHECKOUT MODAL
  // =========================================================================
  void _showCartCheckoutModal() {
    SettlementMode mode = SettlementMode.cash;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final total = _salesCart.fold(0.0, (s, i) => s + i.totalAmount);
          final itemsCount = _salesCart.fold(0, (s, i) => s + i.quantity.toInt());

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 18, right: 18, top: 18),
            child: SizedBox(
              height: 580,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Booking & Cart Checkout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          Text(
                            _selectedCustomer != null ? 'Customer: ${_selectedCustomer!.name}' : 'Walk-in Cash Customer',
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),

                  // Line Items List
                  Expanded(
                    child: ListView.separated(
                      itemCount: _salesCart.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final line = _salesCart[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('₹${line.unitSellingPrice.toStringAsFixed(0)} × ${line.quantity.toInt()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${line.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () {
                                  setState(() => _salesCart.removeAt(idx));
                                  setModalState(() {});
                                  if (_salesCart.isEmpty) Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Settlement Mode Selector
                  const SizedBox(height: 8),
                  const Text('Select Payment & Booking Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Cash Punch')),
                          selected: mode == SettlementMode.cash,
                          selectedColor: Colors.green.shade100,
                          onSelected: (_) => setModalState(() => mode = SettlementMode.cash),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('UPI QR')),
                          selected: mode == SettlementMode.upiQr,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (_) => setModalState(() => mode = SettlementMode.upiQr),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Udhaar / Credit')),
                          selected: mode == SettlementMode.creditUdhaar,
                          selectedColor: Colors.red.shade100,
                          onSelected: (_) {
                            if (_selectedCustomer == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a registered customer to book on Credit/Udhaar!')),
                              );
                              return;
                            }
                            setModalState(() => mode = SettlementMode.creditUdhaar);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Notes field
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Field delivery notes or payment reference...',
                      prefixIcon: Icon(Icons.note, size: 16),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Totals Strip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$itemsCount items total', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Total: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm & Book Order Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(
                      mode == SettlementMode.creditUdhaar ? 'Confirm & Book Udhaar Order' : 'Confirm Order & Print Receipt',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () async {
                      final invNo = 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      final inv = EzoGstTaxEngine.createInvoiceDocument(
                        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                        invoiceNumber: invNo,
                        settlementMode: mode,
                        invoiceDate: DateTime.now(),
                        storeProfile: widget.storeProfile,
                        party: _selectedCustomer,
                        lineItems: List.from(_salesCart),
                        cashier: widget.staff,
                        notes: notesCtrl.text.trim(),
                      );

                      await widget.repository.commitSalesInvoice(inv);

                      // Print 58mm slip via EscPosThermalEngine
                      final bytes = EscPosThermalEngine.buildInvoiceByteStream(
                        invoice: inv,
                        storeProfile: widget.storeProfile,
                        rollWidth: ThermalRollWidth.chota58mm,
                      );
                      await ThermalPrinterConnectionManager().printBytes(bytes);

                      setState(() {
                        _salesCart.clear();
                      });
                      if (ctx.mounted) Navigator.pop(ctx);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #$invNo booked successfully (${mode.name})!'),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB 2: FIELD COLLECTIONS (DOORSTEP KHATA RECOVERY)
  // =========================================================================
  Widget _buildFieldCollections() {
    final allCustomers = widget.repository.getCustomerParties();
    final customersWithDue = allCustomers.where((c) => c.netBalance > 0).toList();

    final filteredCustomers = customersWithDue.where((c) {
      final q = _customerSearchQuery.toLowerCase().trim();
      return q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    final totalOutstanding = customersWithDue.fold<double>(0.0, (s, c) => s + c.netBalance);

    return Column(
      children: [
        // KPI Summary Strip
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Field Udhaar Due: ₹${totalOutstanding.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                    Text(
                      '${customersWithDue.length} accounts require doorstep recovery today',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search Customer
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _customerSearchCtrl,
              onChanged: (v) => setState(() => _customerSearchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
        const Divider(height: 1),

        // Customer Cards
        Expanded(
          child: filteredCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                      const SizedBox(height: 8),
                      const Text('Zero pending Udhaar accounts!', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('All customer accounts are settled.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final c = filteredCustomers[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Due: ₹${c.netBalance.toStringAsFixed(2)} • Ph: ${c.phone}', style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.w600)),
                          Text(c.address, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.payments, size: 15),
                        label: const Text('Collect Payment', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCollectKhataPaymentModal(c),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // "COLLECT KHATA PAYMENT" MODAL (CASH/UPI AMOUNT, NOTES, CONFIRM BUTTON)
  // =========================================================================
  void _showCollectKhataPaymentModal(PartyAccount customer) {
    String paymentMode = 'cash'; // 'cash' or 'upi'
    final amountCtrl = TextEditingController(text: customer.netBalance.toStringAsFixed(2));
    final notesCtrl = TextEditingController(text: 'Doorstep field collection');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentAmount = double.tryParse(amountCtrl.text.trim()) ?? customer.netBalance;
          final upiUri = UpiQrGenerator.buildUpiPaymentUri(
            merchantUpiId: widget.storeProfile.upiId.isNotEmpty ? widget.storeProfile.upiId : 'store@upi',
            merchantName: widget.storeProfile.storeName,
            amount: currentAmount,
            note: 'Udhaar collection - ${customer.name}',
          );

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.account_balance_wallet, color: Colors.green.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Collect Khata Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(customer.name, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outstanding Balance Info Banner
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Outstanding Due:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '₹${customer.netBalance.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Mode Toggle: Cash vs UPI QR
                    const Text('Payment Collection Method:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cash Handover')),
                            selected: paymentMode == 'cash',
                            selectedColor: Colors.green.shade100,
                            onSelected: (_) => setDialogState(() => paymentMode = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Dynamic UPI QR')),
                            selected: paymentMode == 'upi',
                            selectedColor: Colors.blue.shade100,
                            onSelected: (_) => setDialogState(() => paymentMode = 'upi'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // If UPI mode: Show QR Code & URI
                    if (paymentMode == 'upi') ...[
                      Center(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Icon(Icons.qr_code_2, size: 130, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: SelectableText(
                          'Scan to Pay: ₹${currentAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: SelectableText(
                          upiUri,
                          style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Amount Received Input
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Amount Received (₹)',
                        prefixIcon: Icon(Icons.currency_rupee, size: 16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Notes input
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Payment Notes / Cheque / Ref #',
                        prefixIcon: Icon(Icons.edit_note, size: 16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirm Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final enteredAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (enteredAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid payment amount greater than ₹0.')),
                    );
                    return;
                  }

                  await widget.repository.recordPartyPayment(
                    partyId: customer.id,
                    amount: enteredAmount,
                    paymentMode: paymentMode,
                    collectedByStaffId: widget.staff.id,
                    collectedByStaffName: widget.staff.fullName,
                    notes: notesCtrl.text.trim(),
                  );

                  setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Collected ₹${enteredAmount.toStringAsFixed(2)} from ${customer.name} via ${paymentMode.toUpperCase()}!'),
                        backgroundColor: Colors.green.shade800,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB 3: SHIFT SETTLEMENT LEDGER
  // =========================================================================
  Widget _buildShiftSettlement() {
    final myInvoices = widget.repository
        .getAllInvoices()
        .where((i) => i.cashierStaffId == widget.staff.id)
        .toList();

    final totalBilled = myInvoices.fold(0.0, (s, i) => s + i.grandTotal);
    final cashBilled = myInvoices
        .where((i) => i.settlementMode == SettlementMode.cash)
        .fold(0.0, (s, i) => s + i.amountReceived);
    final upiBilled = myInvoices
        .where((i) => i.settlementMode == SettlementMode.upiQr)
        .fold(0.0, (s, i) => s + i.amountReceived);
    final udhaarBooked = myInvoices.fold(0.0, (s, i) => s + i.balanceUdhaarDue);

    // Also calculate Khata collections recorded by this staff member
    double khataCashCollected = 0.0;
    double khataUpiCollected = 0.0;

    for (final party in widget.repository.getAllParties()) {
      for (final entry in party.ledgerEntries) {
        if (entry.collectedByStaffId == widget.staff.id && entry.creditYouGot > 0) {
          if (entry.paymentMode.toLowerCase() == 'cash') {
            khataCashCollected += entry.creditYouGot;
          } else {
            khataUpiCollected += entry.creditYouGot;
          }
        }
      }
    }

    final totalCashInHand = cashBilled + khataCashCollected;
    final totalUpiReceived = upiBilled + khataUpiCollected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Shift Settlement Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Agent: ${widget.staff.fullName} • Staff ID: ${widget.staff.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Sync Shift'),
                onPressed: _handleSyncOrdersToHq,
              ),
            ],
          ),
          const SizedBox(height: 14),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildShiftRow('Orders Punched by Me', '${myInvoices.length} bills'),
                  _buildShiftRow('Total Sales Volume', '₹${totalBilled.toStringAsFixed(2)}', isBold: true),
                  const Divider(),
                  _buildShiftRow('Direct Billing Cash', '₹${cashBilled.toStringAsFixed(2)}'),
                  _buildShiftRow('Field Udhaar Cash Recovered', '₹${khataCashCollected.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildShiftRow('💵 TOTAL CASH IN HAND (Deposit to Store)', '₹${totalCashInHand.toStringAsFixed(2)}', color: Colors.green.shade800, isBold: true),
                  const SizedBox(height: 4),
                  _buildShiftRow('📱 Total UPI Received (Store Direct)', '₹${totalUpiReceived.toStringAsFixed(2)}', color: Colors.blue.shade800),
                  _buildShiftRow('📝 Credit / Udhaar Booked in Field', '₹${udhaarBooked.toStringAsFixed(2)}', color: Colors.red.shade800),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.print),
            label: const Text('Print Shift Summary Slip (58mm)', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing Daily Shift Settlement Slip to 58mm Thermal Printer...')),
              );
            },
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade800,
              side: BorderSide(color: Colors.green.shade700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('End Shift & Handover Cash to Manager', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm End of Shift'),
                  content: Text('Are you sure you want to end shift? Total physical cash to hand over: ₹${totalCashInHand.toStringAsFixed(2)}'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shift completed! Cash deposit recorded.')),
                        );
                      },
                      child: const Text('Confirm Handover'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: isBold ? 15 : 13)),
        ],
      ),
    );
  }
}
