enum ItemUnit {
  pcs('PCS'),
  kg('KG'),
  ltr('LTR'),
  box('BOX'),
  bag('BAG'),
  mtr('MTR');

  final String label;
  const ItemUnit(this.label);

  static ItemUnit fromString(String? val) {
    if (val == null) return ItemUnit.pcs;
    return ItemUnit.values.firstWhere(
      (u) => u.name.toLowerCase() == val.toLowerCase() || u.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ItemUnit.pcs,
    );
  }
}

class ProductItem {
  final String id;
  final String name;
  final String regionalName;
  final String skuCode;
  final String barcode;
  final String hsnSacCode;
  final String category;
  final ItemUnit unit;
  final double mrp;
  final double sellingPrice;
  final double wholesalePrice;
  final double purchasePrice;
  final double gstPercent;
  final bool isTaxInclusive;
  final double currentStock;
  final double lowStockThreshold;
  final String batchNumber;
  final DateTime? expiryDate;
  final String imageUrl;
  final bool showOnOnlineDukan;
  final double totalUnitsSold;
  final List<String> upsellProductIds;

  const ProductItem({
    required this.id,
    required this.name,
    this.regionalName = '',
    required this.skuCode,
    this.barcode = '',
    this.hsnSacCode = '',
    this.category = 'General',
    this.unit = ItemUnit.pcs,
    required this.mrp,
    required this.sellingPrice,
    this.wholesalePrice = 0.0,
    this.purchasePrice = 0.0,
    this.gstPercent = 0.0,
    this.isTaxInclusive = true,
    this.currentStock = 0.0,
    this.lowStockThreshold = 5.0,
    this.batchNumber = '',
    this.expiryDate,
    this.imageUrl = '',
    this.showOnOnlineDukan = false,
    this.totalUnitsSold = 0.0,
    this.upsellProductIds = const [],
  });

  double get discountOnMrp => mrp > sellingPrice ? mrp - sellingPrice : 0.0;

  double get discountPercent {
    if (mrp <= 0 || sellingPrice >= mrp) return 0.0;
    return ((mrp - sellingPrice) / mrp) * 100.0;
  }

  bool get isLowStock => currentStock <= lowStockThreshold && currentStock > 0;

  bool get isOutOfStock => currentStock <= 0;

  double get stockAssetValueAtCost => currentStock * purchasePrice;

  double get stockRetailValue => currentStock * sellingPrice;

  ProductItem copyWith({
    String? id,
    String? name,
    String? regionalName,
    String? skuCode,
    String? barcode,
    String? hsnSacCode,
    String? category,
    ItemUnit? unit,
    double? mrp,
    double? sellingPrice,
    double? wholesalePrice,
    double? purchasePrice,
    double? gstPercent,
    bool? isTaxInclusive,
    double? currentStock,
    double? lowStockThreshold,
    String? batchNumber,
    DateTime? expiryDate,
    String? imageUrl,
    bool? showOnOnlineDukan,
    double? totalUnitsSold,
    List<String>? upsellProductIds,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      regionalName: regionalName ?? this.regionalName,
      skuCode: skuCode ?? this.skuCode,
      barcode: barcode ?? this.barcode,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      gstPercent: gstPercent ?? this.gstPercent,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      showOnOnlineDukan: showOnOnlineDukan ?? this.showOnOnlineDukan,
      totalUnitsSold: totalUnitsSold ?? this.totalUnitsSold,
      upsellProductIds: upsellProductIds ?? this.upsellProductIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'regionalName': regionalName,
      'skuCode': skuCode,
      'barcode': barcode,
      'hsnSacCode': hsnSacCode,
      'category': category,
      'unit': unit.label,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'wholesalePrice': wholesalePrice,
      'purchasePrice': purchasePrice,
      'gstPercent': gstPercent,
      'isTaxInclusive': isTaxInclusive,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'showOnOnlineDukan': showOnOnlineDukan,
      'totalUnitsSold': totalUnitsSold,
      'upsellProductIds': upsellProductIds,
    };
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      regionalName: json['regionalName'] as String? ?? '',
      skuCode: json['skuCode'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      hsnSacCode: json['hsnSacCode'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      unit: ItemUnit.fromString(json['unit'] as String?),
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0.0,
      isTaxInclusive: json['isTaxInclusive'] as bool? ?? true,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble() ?? 5.0,
      batchNumber: json['batchNumber'] as String? ?? '',
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'] as String) : null,
      imageUrl: json['imageUrl'] as String? ?? '',
      showOnOnlineDukan: json['showOnOnlineDukan'] as bool? ?? false,
      totalUnitsSold: (json['totalUnitsSold'] as num?)?.toDouble() ?? 0.0,
      upsellProductIds: (json['upsellProductIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
