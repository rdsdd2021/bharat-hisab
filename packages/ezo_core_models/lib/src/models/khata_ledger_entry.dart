class KhataLedgerEntry {
  final String id;
  final String partyId;
  final DateTime entryDate;
  final double debitYouGave; // Amount given on credit / goods sold / paid out
  final double creditYouGot; // Amount received from party / goods purchased
  final String paymentMode; // cash, upi, bank_transfer, invoice_credit
  final String collectedByStaffId;
  final String collectedByStaffName;
  final String referenceInvoiceNumber;
  final String notes;
  final DateTime createdAt;

  const KhataLedgerEntry({
    required this.id,
    required this.partyId,
    required this.entryDate,
    this.debitYouGave = 0.0,
    this.creditYouGot = 0.0,
    this.paymentMode = 'cash',
    this.collectedByStaffId = '',
    this.collectedByStaffName = '',
    this.referenceInvoiceNumber = '',
    this.notes = '',
    required this.createdAt,
  });

  double get netEntryAmount => debitYouGave - creditYouGot;

  KhataLedgerEntry copyWith({
    String? id,
    String? partyId,
    DateTime? entryDate,
    double? debitYouGave,
    double? creditYouGot,
    String? paymentMode,
    String? collectedByStaffId,
    String? collectedByStaffName,
    String? referenceInvoiceNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return KhataLedgerEntry(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      entryDate: entryDate ?? this.entryDate,
      debitYouGave: debitYouGave ?? this.debitYouGave,
      creditYouGot: creditYouGot ?? this.creditYouGot,
      paymentMode: paymentMode ?? this.paymentMode,
      collectedByStaffId: collectedByStaffId ?? this.collectedByStaffId,
      collectedByStaffName: collectedByStaffName ?? this.collectedByStaffName,
      referenceInvoiceNumber: referenceInvoiceNumber ?? this.referenceInvoiceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partyId': partyId,
      'entryDate': entryDate.toIso8601String(),
      'debitYouGave': debitYouGave,
      'creditYouGot': creditYouGot,
      'paymentMode': paymentMode,
      'collectedByStaffId': collectedByStaffId,
      'collectedByStaffName': collectedByStaffName,
      'referenceInvoiceNumber': referenceInvoiceNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KhataLedgerEntry.fromJson(Map<String, dynamic> json) {
    return KhataLedgerEntry(
      id: json['id'] as String? ?? '',
      partyId: json['partyId'] as String? ?? '',
      entryDate: json['entryDate'] != null
          ? DateTime.parse(json['entryDate'] as String)
          : DateTime.now(),
      debitYouGave: (json['debitYouGave'] as num?)?.toDouble() ?? 0.0,
      creditYouGot: (json['creditYouGot'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode'] as String? ?? 'cash',
      collectedByStaffId: json['collectedByStaffId'] as String? ?? '',
      collectedByStaffName: json['collectedByStaffName'] as String? ?? '',
      referenceInvoiceNumber: json['referenceInvoiceNumber'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
