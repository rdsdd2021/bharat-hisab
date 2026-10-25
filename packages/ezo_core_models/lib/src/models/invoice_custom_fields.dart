class InvoiceCustomFields {
  final String batchNumber;
  final String poNumber;
  final String ewayBillNumber;
  final String ticketOrImeiNumber;
  final String vehicleNumber;
  final String tableNumber;
  final Map<String, String> extraCustomPairs;

  const InvoiceCustomFields({
    this.batchNumber = '',
    this.poNumber = '',
    this.ewayBillNumber = '',
    this.ticketOrImeiNumber = '',
    this.vehicleNumber = '',
    this.tableNumber = '',
    this.extraCustomPairs = const {},
  });

  bool get isEmpty =>
      batchNumber.isEmpty &&
      poNumber.isEmpty &&
      ewayBillNumber.isEmpty &&
      ticketOrImeiNumber.isEmpty &&
      vehicleNumber.isEmpty &&
      tableNumber.isEmpty &&
      extraCustomPairs.isEmpty;

  bool get isNotEmpty => !isEmpty;

  InvoiceCustomFields copyWith({
    String? batchNumber,
    String? poNumber,
    String? ewayBillNumber,
    String? ticketOrImeiNumber,
    String? vehicleNumber,
    String? tableNumber,
    Map<String, String>? extraCustomPairs,
  }) {
    return InvoiceCustomFields(
      batchNumber: batchNumber ?? this.batchNumber,
      poNumber: poNumber ?? this.poNumber,
      ewayBillNumber: ewayBillNumber ?? this.ewayBillNumber,
      ticketOrImeiNumber: ticketOrImeiNumber ?? this.ticketOrImeiNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      extraCustomPairs: extraCustomPairs ?? this.extraCustomPairs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber,
      'poNumber': poNumber,
      'ewayBillNumber': ewayBillNumber,
      'ticketOrImeiNumber': ticketOrImeiNumber,
      'vehicleNumber': vehicleNumber,
      'tableNumber': tableNumber,
      'extraCustomPairs': extraCustomPairs,
    };
  }

  factory InvoiceCustomFields.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomFields(
      batchNumber: json['batchNumber'] as String? ?? '',
      poNumber: json['poNumber'] as String? ?? '',
      ewayBillNumber: json['ewayBillNumber'] as String? ?? '',
      ticketOrImeiNumber: json['ticketOrImeiNumber'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      tableNumber: json['tableNumber'] as String? ?? '',
      extraCustomPairs: (json['extraCustomPairs'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }
}
