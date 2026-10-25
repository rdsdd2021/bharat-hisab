import 'product_item.dart';

class InvoiceLineItem {
  final String productId;
  final String itemName;
  final String regionalName;
  final String hsnSacCode;
  final ItemUnit unit;
  final double quantity;
  final double mrp;
  final double unitSellingPrice;
  final double lineDiscountAmount;
  final double taxableAmount;
  final double gstPercent;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  final String cookingNotes;

  const InvoiceLineItem({
    required this.productId,
    required this.itemName,
    this.regionalName = '',
    this.hsnSacCode = '',
    this.unit = ItemUnit.pcs,
    required this.quantity,
    required this.mrp,
    required this.unitSellingPrice,
    this.lineDiscountAmount = 0.0,
    required this.taxableAmount,
    required this.gstPercent,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.totalAmount,
    this.cookingNotes = '',
  });

  double get totalGst => cgstAmount + sgstAmount + igstAmount;

  double get itemSavings {
    final regularTotal = mrp * quantity;
    final paidTotal = totalAmount;
    return regularTotal > paidTotal ? regularTotal - paidTotal : 0.0;
  }

  InvoiceLineItem copyWith({
    String? productId,
    String? itemName,
    String? regionalName,
    String? hsnSacCode,
    ItemUnit? unit,
    double? quantity,
    double? mrp,
    double? unitSellingPrice,
    double? lineDiscountAmount,
    double? taxableAmount,
    double? gstPercent,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? totalAmount,
    String? cookingNotes,
  }) {
    return InvoiceLineItem(
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      regionalName: regionalName ?? this.regionalName,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      mrp: mrp ?? this.mrp,
      unitSellingPrice: unitSellingPrice ?? this.unitSellingPrice,
      lineDiscountAmount: lineDiscountAmount ?? this.lineDiscountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      gstPercent: gstPercent ?? this.gstPercent,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      cookingNotes: cookingNotes ?? this.cookingNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'itemName': itemName,
      'regionalName': regionalName,
      'hsnSacCode': hsnSacCode,
      'unit': unit.label,
      'quantity': quantity,
      'mrp': mrp,
      'unitSellingPrice': unitSellingPrice,
      'lineDiscountAmount': lineDiscountAmount,
      'taxableAmount': taxableAmount,
      'gstPercent': gstPercent,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'totalAmount': totalAmount,
      'cookingNotes': cookingNotes,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      productId: json['productId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      regionalName: json['regionalName'] as String? ?? '',
      hsnSacCode: json['hsnSacCode'] as String? ?? '',
      unit: ItemUnit.fromString(json['unit'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      unitSellingPrice: (json['unitSellingPrice'] as num?)?.toDouble() ?? 0.0,
      lineDiscountAmount: (json['lineDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json['taxableAmount'] as num?)?.toDouble() ?? 0.0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igstAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      cookingNotes: json['cookingNotes'] as String? ?? '',
    );
  }
}
