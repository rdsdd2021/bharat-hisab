import 'invoice_custom_fields.dart';
import 'invoice_line_item.dart';

enum InvoiceDocType {
  gstTaxInvoice,
  nonGstBillOfSupply,
  quotationEstimate,
  proformaInvoice,
  purchaseOrder,
  salesReturnCreditNote,
  purchaseReturnDebitNote,
  kitchenOrderTicketKot,
}

enum SettlementMode {
  cash,
  upiQr,
  cardBank,
  creditUdhaar,
  splitPayment,
}

class InvoiceDocument {
  final String id;
  final String invoiceNumber;
  final InvoiceDocType docType;
  final SettlementMode settlementMode;
  final DateTime invoiceDate;
  final String storeProfileId;
  final String storeStateCode;
  final String partyId;
  final String partyName;
  final String partyPhone;
  final String partyGstin;
  final String partyStateCode;
  final String partyAddress;
  final List<InvoiceLineItem> lineItems;
  final double taxableSubtotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double billDiscountAmount;
  final double roundOffAdjustment;
  final double grandTotal;
  final double amountReceived;
  final InvoiceCustomFields customFields;
  final String cashierStaffId;
  final String cashierStaffName;
  final String notes;
  final bool isCancelled;
  final DateTime createdAt;

  const InvoiceDocument({
    required this.id,
    required this.invoiceNumber,
    this.docType = InvoiceDocType.gstTaxInvoice,
    this.settlementMode = SettlementMode.cash,
    required this.invoiceDate,
    required this.storeProfileId,
    required this.storeStateCode,
    this.partyId = '',
    this.partyName = 'Cash Customer',
    this.partyPhone = '',
    this.partyGstin = '',
    this.partyStateCode = '',
    this.partyAddress = '',
    this.lineItems = const [],
    this.taxableSubtotal = 0.0,
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.billDiscountAmount = 0.0,
    this.roundOffAdjustment = 0.0,
    required this.grandTotal,
    required this.amountReceived,
    this.customFields = const InvoiceCustomFields(),
    this.cashierStaffId = '',
    this.cashierStaffName = 'Cashier',
    this.notes = '',
    this.isCancelled = false,
    required this.createdAt,
  });

  double get totalTax => totalCgst + totalSgst + totalIgst;

  double get balanceUdhaarDue {
    final diff = grandTotal - amountReceived;
    return diff > 0.001 ? diff : 0.0;
  }

  double get customerSavings {
    double itemLevelSavings = 0.0;
    for (final item in lineItems) {
      itemLevelSavings += item.itemSavings;
    }
    return itemLevelSavings + billDiscountAmount;
  }

  bool get isInterStateSupply {
    if (storeStateCode.isEmpty || partyStateCode.isEmpty) return false;
    return storeStateCode.trim() != partyStateCode.trim();
  }

  InvoiceDocument copyWith({
    String? id,
    String? invoiceNumber,
    InvoiceDocType? docType,
    SettlementMode? settlementMode,
    DateTime? invoiceDate,
    String? storeProfileId,
    String? storeStateCode,
    String? partyId,
    String? partyName,
    String? partyPhone,
    String? partyGstin,
    String? partyStateCode,
    String? partyAddress,
    List<InvoiceLineItem>? lineItems,
    double? taxableSubtotal,
    double? totalCgst,
    double? totalSgst,
    double? totalIgst,
    double? billDiscountAmount,
    double? roundOffAdjustment,
    double? grandTotal,
    double? amountReceived,
    InvoiceCustomFields? customFields,
    String? cashierStaffId,
    String? cashierStaffName,
    String? notes,
    bool? isCancelled,
    DateTime? createdAt,
  }) {
    return InvoiceDocument(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      docType: docType ?? this.docType,
      settlementMode: settlementMode ?? this.settlementMode,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      storeProfileId: storeProfileId ?? this.storeProfileId,
      storeStateCode: storeStateCode ?? this.storeStateCode,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      partyGstin: partyGstin ?? this.partyGstin,
      partyStateCode: partyStateCode ?? this.partyStateCode,
      partyAddress: partyAddress ?? this.partyAddress,
      lineItems: lineItems ?? this.lineItems,
      taxableSubtotal: taxableSubtotal ?? this.taxableSubtotal,
      totalCgst: totalCgst ?? this.totalCgst,
      totalSgst: totalSgst ?? this.totalSgst,
      totalIgst: totalIgst ?? this.totalIgst,
      billDiscountAmount: billDiscountAmount ?? this.billDiscountAmount,
      roundOffAdjustment: roundOffAdjustment ?? this.roundOffAdjustment,
      grandTotal: grandTotal ?? this.grandTotal,
      amountReceived: amountReceived ?? this.amountReceived,
      customFields: customFields ?? this.customFields,
      cashierStaffId: cashierStaffId ?? this.cashierStaffId,
      cashierStaffName: cashierStaffName ?? this.cashierStaffName,
      notes: notes ?? this.notes,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'docType': docType.name,
      'settlementMode': settlementMode.name,
      'invoiceDate': invoiceDate.toIso8601String(),
      'storeProfileId': storeProfileId,
      'storeStateCode': storeStateCode,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'partyGstin': partyGstin,
      'partyStateCode': partyStateCode,
      'partyAddress': partyAddress,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'taxableSubtotal': taxableSubtotal,
      'totalCgst': totalCgst,
      'totalSgst': totalSgst,
      'totalIgst': totalIgst,
      'billDiscountAmount': billDiscountAmount,
      'roundOffAdjustment': roundOffAdjustment,
      'grandTotal': grandTotal,
      'amountReceived': amountReceived,
      'customFields': customFields.toJson(),
      'cashierStaffId': cashierStaffId,
      'cashierStaffName': cashierStaffName,
      'notes': notes,
      'isCancelled': isCancelled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InvoiceDocument.fromJson(Map<String, dynamic> json) {
    return InvoiceDocument(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      docType: InvoiceDocType.values.firstWhere(
        (e) => e.name == json['docType'],
        orElse: () => InvoiceDocType.gstTaxInvoice,
      ),
      settlementMode: SettlementMode.values.firstWhere(
        (e) => e.name == json['settlementMode'],
        orElse: () => SettlementMode.cash,
      ),
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : DateTime.now(),
      storeProfileId: json['storeProfileId'] as String? ?? '',
      storeStateCode: json['storeStateCode'] as String? ?? '27',
      partyId: json['partyId'] as String? ?? '',
      partyName: json['partyName'] as String? ?? 'Cash Customer',
      partyPhone: json['partyPhone'] as String? ?? '',
      partyGstin: json['partyGstin'] as String? ?? '',
      partyStateCode: json['partyStateCode'] as String? ?? '',
      partyAddress: json['partyAddress'] as String? ?? '',
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      taxableSubtotal: (json['taxableSubtotal'] as num?)?.toDouble() ?? 0.0,
      totalCgst: (json['totalCgst'] as num?)?.toDouble() ?? 0.0,
      totalSgst: (json['totalSgst'] as num?)?.toDouble() ?? 0.0,
      totalIgst: (json['totalIgst'] as num?)?.toDouble() ?? 0.0,
      billDiscountAmount: (json['billDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      roundOffAdjustment: (json['roundOffAdjustment'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0.0,
      customFields: json['customFields'] != null
          ? InvoiceCustomFields.fromJson(json['customFields'] as Map<String, dynamic>)
          : const InvoiceCustomFields(),
      cashierStaffId: json['cashierStaffId'] as String? ?? '',
      cashierStaffName: json['cashierStaffName'] as String? ?? 'Cashier',
      notes: json['notes'] as String? ?? '',
      isCancelled: json['isCancelled'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
