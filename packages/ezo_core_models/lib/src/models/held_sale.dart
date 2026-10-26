import 'invoice_line_item.dart';
import 'party_account.dart';

class HeldSale {
  final String id;
  final DateTime heldAt;
  final PartyAccount? customer;
  final List<InvoiceLineItem> cartLines;
  final double grandTotal;
  final String notes;

  const HeldSale({
    required this.id,
    required this.heldAt,
    this.customer,
    required this.cartLines,
    required this.grandTotal,
    this.notes = '',
  });

  int get totalItemsCount => cartLines.length;

  double get totalQuantity => cartLines.fold(0.0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heldAt': heldAt.toIso8601String(),
      'customer': customer?.toJson(),
      'cartLines': cartLines.map((e) => e.toJson()).toList(),
      'grandTotal': grandTotal,
      'notes': notes,
    };
  }

  factory HeldSale.fromJson(Map<String, dynamic> json) {
    return HeldSale(
      id: json['id'] as String? ?? '',
      heldAt: json['heldAt'] != null ? DateTime.parse(json['heldAt'] as String) : DateTime.now(),
      customer: json['customer'] != null ? PartyAccount.fromJson(json['customer'] as Map<String, dynamic>) : null,
      cartLines: (json['cartLines'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }
}
