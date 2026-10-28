import 'package:flutter/foundation.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';
import '../demo/demo_data_seeder.dart';

class PosBillingController extends ChangeNotifier {
  final EzoOfflineRepository repository;

  // Active Store Profile & Staff
  BusinessProfile _currentProfile;
  String _selectedTable = 'Table 1';
  String? _patientDoctorNote;
  String _selectedSize = 'M';
  String _selectedColor = 'Standard';
  String? _scannedImei;
  final StaffMember? _currentStaff;

  // Invoice Mode Settings
  bool _isGstInvoice = true;
  InvoiceDocType _docType = InvoiceDocType.gstTaxInvoice;
  PrintFormat _printFormat = PrintFormat.chota58mm;
  SettlementMode _settlementMode = SettlementMode.cash;

  // Active Cart State
  final List<InvoiceLineItem> _cartLines = [];
  final List<HeldSale> _heldSales = [];
  PartyAccount? _selectedCustomer;
  double _billDiscount = 0.0;
  double? _customAmountReceived;
  InvoiceCustomFields _customFields = const InvoiceCustomFields();

  // Search and Category Filter
  String _selectedCategory = 'All';
  String _searchQuery = '';

  PosBillingController({
    required this.repository,
    required BusinessProfile initialProfile,
    StaffMember? initialStaff,
  })  : _currentProfile = initialProfile,
        _currentStaff = initialStaff;

  // Getters
  BusinessProfile get currentProfile => _currentProfile;
  StaffMember? get currentStaff => _currentStaff;
  bool get isGstInvoice => _isGstInvoice;
  InvoiceDocType get docType => _docType;
  PrintFormat get printFormat => _printFormat;
  SettlementMode get settlementMode => _settlementMode;
  List<InvoiceLineItem> get cartLines => List.unmodifiable(_cartLines);
  List<HeldSale> get heldSales => List.unmodifiable(_heldSales);
  PartyAccount? get selectedCustomer => _selectedCustomer;
  double get billDiscount => _billDiscount;
  InvoiceCustomFields get customFields => _customFields;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Computed Totals
  double get taxableSubtotal => _cartLines.fold(0.0, (sum, i) => sum + i.taxableAmount);
  double get totalCgst => _cartLines.fold(0.0, (sum, i) => sum + i.cgstAmount);
  double get totalSgst => _cartLines.fold(0.0, (sum, i) => sum + i.sgstAmount);
  double get totalIgst => _cartLines.fold(0.0, (sum, i) => sum + i.igstAmount);
  double get totalTax => totalCgst + totalSgst + totalIgst;

  double get grandTotal {
    final raw = (taxableSubtotal + totalTax - _billDiscount).clamp(0.0, double.infinity);
    return raw.roundToDouble();
  }

  double get amountReceived {
    if (_customAmountReceived != null) return _customAmountReceived!;
    if (_settlementMode == SettlementMode.creditUdhaar) return 0.0;
    return grandTotal;
  }

  double get balanceUdhaarDue {
    final diff = grandTotal - amountReceived;
    return diff > 0.001 ? diff : 0.0;
  }

  double get totalCustomerSavings {
    double itemSavings = 0.0;
    for (final line in _cartLines) {
      itemSavings += line.itemSavings;
    }
    return itemSavings + _billDiscount;
  }

  List<ProductItem> get filteredProducts {
    var all = repository.getAllProducts();
    if (_selectedCategory != 'All') {
      all = all.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      all = all.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.skuCode.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q)).toList();
    }
    return all;
  }

  List<String> get availableCategories {
    final cats = repository.getAllProducts().map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<ProductItem> get upsellSuggestions {
    return UpsellRecommender.getUpsellSuggestions(
      cartLines: _cartLines,
      catalog: repository.getAllProducts(),
      maxSuggestions: 4,
    );
  }

  // Setters & Modifiers
  void setGstMode(bool isGst) {
    _isGstInvoice = isGst;
    _recalculateCart();
    notifyListeners();
  }

  void setDocType(InvoiceDocType type) {
    _docType = type;
    notifyListeners();
  }

  void setPrintFormat(PrintFormat format) {
    _printFormat = format;
    notifyListeners();
  }

  void setSettlementMode(SettlementMode mode) {
    _settlementMode = mode;
    if (mode == SettlementMode.creditUdhaar) {
      _customAmountReceived = 0.0;
    } else {
      _customAmountReceived = grandTotal;
    }
    notifyListeners();
  }

  void setCustomer(PartyAccount? customer) {
    _selectedCustomer = customer;
    _recalculateCart();
    notifyListeners();
  }

  void setCustomFields(InvoiceCustomFields fields) {
    _customFields = fields;
    notifyListeners();
  }

  void setBillDiscount(double discount) {
    _billDiscount = discount;
    notifyListeners();
  }

  void setCustomAmountReceived(double amount) {
    _customAmountReceived = amount;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addProductToCart(ProductItem product, {double qty = 1.0, String cookingNotes = ''}) {
    final existingIdx = _cartLines.indexWhere((l) => l.productId == product.id);
    if (existingIdx != -1) {
      final current = _cartLines[existingIdx];
      updateCartLineQty(existingIdx, current.quantity + qty);
    } else {
      final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
      final line = EzoGstTaxEngine.buildLineItem(
        product: product,
        quantity: qty,
        isGstInvoice: _isGstInvoice,
        isInterStateSupply: isInterState,
        cookingNotes: cookingNotes,
      );
      _cartLines.add(line);
      notifyListeners();
    }
  }

  void updateCartLineQty(int index, double newQty) {
    if (newQty <= 0) {
      _cartLines.removeAt(index);
    } else {
      final line = _cartLines[index];
      final prod = repository.getProduct(line.productId);
      if (prod != null) {
        final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
        _cartLines[index] = EzoGstTaxEngine.buildLineItem(
          product: prod,
          quantity: newQty,
          overrideUnitPrice: line.unitSellingPrice,
          lineDiscountAmount: line.lineDiscountAmount,
          isGstInvoice: _isGstInvoice,
          isInterStateSupply: isInterState,
          cookingNotes: line.cookingNotes,
        );
      }
    }
    notifyListeners();
  }

  void updateCartLinePrice(int index, double newSellingPrice) {
    if (index >= 0 && index < _cartLines.length && newSellingPrice >= 0) {
      final line = _cartLines[index];
      final prod = repository.getProduct(line.productId);
      if (prod != null) {
        final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
        _cartLines[index] = EzoGstTaxEngine.buildLineItem(
          product: prod,
          quantity: line.quantity,
          overrideUnitPrice: newSellingPrice,
          lineDiscountAmount: line.lineDiscountAmount,
          isGstInvoice: _isGstInvoice,
          isInterStateSupply: isInterState,
          cookingNotes: line.cookingNotes,
        );
        notifyListeners();
      }
    }
  }

  void updateCartLineDiscount(int index, double discountAmount) {
    if (index >= 0 && index < _cartLines.length && discountAmount >= 0) {
      final line = _cartLines[index];
      final prod = repository.getProduct(line.productId);
      if (prod != null) {
        final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
        _cartLines[index] = EzoGstTaxEngine.buildLineItem(
          product: prod,
          quantity: line.quantity,
          overrideUnitPrice: line.unitSellingPrice,
          lineDiscountAmount: discountAmount,
          isGstInvoice: _isGstInvoice,
          isInterStateSupply: isInterState,
          cookingNotes: line.cookingNotes,
        );
        notifyListeners();
      }
    }
  }

  void updateCartLinePriceAndDiscount(int index, double newSellingPrice, double lineDiscount) {
    if (index >= 0 && index < _cartLines.length && newSellingPrice >= 0 && lineDiscount >= 0) {
      final line = _cartLines[index];
      final prod = repository.getProduct(line.productId);
      if (prod != null) {
        final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
        _cartLines[index] = EzoGstTaxEngine.buildLineItem(
          product: prod,
          quantity: line.quantity,
          overrideUnitPrice: newSellingPrice,
          lineDiscountAmount: lineDiscount,
          isGstInvoice: _isGstInvoice,
          isInterStateSupply: isInterState,
          cookingNotes: line.cookingNotes,
        );
        notifyListeners();
      }
    }
  }

  /// Finds a product matching a numeric short-code, exact barcode, or SKU
  ProductItem? findProductByCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return null;
    final all = repository.getAllProducts();

    // 1. Check numeric short-code (1-4 digit quick codes)
    final byShortCode = all.where((p) => p.shortCode.trim() == code);
    if (byShortCode.isNotEmpty) return byShortCode.first;

    // 2. Check exact barcode
    final byBarcode = all.where((p) => p.barcode.trim() == code);
    if (byBarcode.isNotEmpty) return byBarcode.first;

    // 3. Check SKU code (case-insensitive)
    final bySku = all.where((p) => p.skuCode.trim().toLowerCase() == code.toLowerCase());
    if (bySku.isNotEmpty) return bySku.first;

    return null;
  }

  /// Quickly adds a product matching code (numeric short-code, barcode, or SKU)
  bool addProductByCode(String code, {double qty = 1.0}) {
    final product = findProductByCode(code);
    if (product != null) {
      addProductToCart(product, qty: qty);
      return true;
    }
    return false;
  }

  /// Parks/holds the current active sale to serve the next queue
  bool holdCurrentSale({String notes = ''}) {
    if (_cartLines.isEmpty) return false;
    final held = HeldSale(
      id: 'held_${DateTime.now().millisecondsSinceEpoch}',
      heldAt: DateTime.now(),
      customer: _selectedCustomer,
      cartLines: List.from(_cartLines),
      grandTotal: grandTotal,
      notes: notes.isNotEmpty ? notes : 'Parked Bill #${_heldSales.length + 1}',
    );
    _heldSales.add(held);
    clearCart();
    return true;
  }

  /// Resumes a parked sale by restoring its customer and cart items
  bool resumeHeldSale(String heldSaleId) {
    final idx = _heldSales.indexWhere((h) => h.id == heldSaleId);
    if (idx == -1) return false;
    final held = _heldSales.removeAt(idx);

    _cartLines.clear();
    _cartLines.addAll(held.cartLines);
    _selectedCustomer = held.customer;
    _recalculateCart();
    notifyListeners();
    return true;
  }

  /// Dismisses/deletes a held sale from the queue
  void deleteHeldSale(String heldSaleId) {
    _heldSales.removeWhere((h) => h.id == heldSaleId);
    notifyListeners();
  }

  void removeCartLine(int index) {
    if (index >= 0 && index < _cartLines.length) {
      _cartLines.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartLines.clear();
    _billDiscount = 0.0;
    _customAmountReceived = null;
    _customFields = const InvoiceCustomFields();
    _selectedCustomer = null;
    notifyListeners();
  }

  void _recalculateCart() {
    final isInterState = _currentProfile.stateCode != (_selectedCustomer?.stateCode ?? _currentProfile.stateCode);
    for (int i = 0; i < _cartLines.length; i++) {
      final line = _cartLines[i];
      final prod = repository.getProduct(line.productId);
      if (prod != null) {
        _cartLines[i] = EzoGstTaxEngine.buildLineItem(
          product: prod,
          quantity: line.quantity,
          overrideUnitPrice: line.unitSellingPrice,
          lineDiscountAmount: line.lineDiscountAmount,
          isGstInvoice: _isGstInvoice,
          isInterStateSupply: isInterState,
          cookingNotes: line.cookingNotes,
        );
      }
    }
  }

  /// Builds the complete InvoiceDocument from active cart
  InvoiceDocument buildCurrentInvoice() {
    final billNo = 'BH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    return EzoGstTaxEngine.createInvoiceDocument(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: billNo,
      docType: _docType,
      settlementMode: _settlementMode,
      invoiceDate: DateTime.now(),
      storeProfile: _currentProfile,
      party: _selectedCustomer,
      lineItems: _cartLines,
      billLevelDiscount: _billDiscount,
      amountReceived: amountReceived,
      customFields: _customFields,
      cashier: _currentStaff,
    );
  }

  /// Commits invoice to local offline database and decrements inventory
  Future<InvoiceDocument> commitInvoice() async {
    final invoice = buildCurrentInvoice();
    await repository.commitSalesInvoice(invoice);
    clearCart();
    return invoice;
  }

  /// Reloads the catalog from repository storage
  void reloadCatalog() {
    notifyListeners();
  }

  // Mode-Specific Getters & Setters
  String get selectedTable => _selectedTable;
  String? get patientDoctorNote => _patientDoctorNote;
  String get selectedSize => _selectedSize;
  String get selectedColor => _selectedColor;
  String? get scannedImei => _scannedImei;

  void setSelectedTable(String table) {
    _selectedTable = table;
    _customFields = _customFields.copyWith(tableNumber: table);
    notifyListeners();
  }

  void setPatientDoctorNote(String note) {
    _patientDoctorNote = note;
    _customFields = _customFields.copyWith(poNumber: note);
    notifyListeners();
  }

  void setGarmentAttributes({String? size, String? color}) {
    if (size != null) _selectedSize = size;
    if (color != null) _selectedColor = color;
    notifyListeners();
  }

  void setScannedImei(String imei) {
    _scannedImei = imei;
    _customFields = _customFields.copyWith(ticketOrImeiNumber: imei);
    notifyListeners();
  }

  Future<void> switchIndustryVertical(IndustryVertical newVertical, {bool loadSampleData = false}) async {
    final updatedProfile = _currentProfile.copyWith(
      industryVertical: newVertical,
      defaultPrintFormat: newVertical == IndustryVertical.restaurantCafe
          ? PrintFormat.bada80mm
          : PrintFormat.chota58mm,
      branding: _currentProfile.branding.copyWith(
        primaryColorHex: newVertical == IndustryVertical.restaurantCafe
            ? '#EA580C'
            : (newVertical == IndustryVertical.pharmacyHealth
                ? '#059669'
                : (newVertical == IndustryVertical.garmentsApparel
                    ? '#7C3AED'
                    : (newVertical == IndustryVertical.electronicsMobiles ? '#0284C7' : '#1E88E5'))),
      ),
    );
    _currentProfile = updatedProfile;
    await repository.saveProfile(updatedProfile);

    if (loadSampleData) {
      await DemoDataSeeder.seedVerticalStore(
        repo: repository,
        vertical: newVertical,
        storeName: _currentProfile.storeName,
        phone: _currentProfile.phone,
      );
    }

    _selectedCategory = 'All';
    _searchQuery = '';
    _cartLines.clear();
    _customFields = InvoiceCustomFields(
      tableNumber: newVertical == IndustryVertical.restaurantCafe ? _selectedTable : '',
    );
    notifyListeners();
  }
}