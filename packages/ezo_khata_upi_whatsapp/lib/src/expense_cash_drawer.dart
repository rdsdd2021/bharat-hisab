enum ExpenseCategory {
  rent,
  electricity,
  transport,
  teaRefreshments,
  packaging,
  staffSalary,
  maintenance,
  other,
}

class StoreExpenseEntry {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final String paymentMode; // cash, bank_upi
  final DateTime date;
  final String notes;
  final String enteredByStaffId;

  const StoreExpenseEntry({
    required this.id,
    required this.category,
    required this.amount,
    this.paymentMode = 'cash',
    required this.date,
    this.notes = '',
    this.enteredByStaffId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'amount': amount,
        'paymentMode': paymentMode,
        'date': date.toIso8601String(),
        'notes': notes,
        'enteredByStaffId': enteredByStaffId,
      };

  factory StoreExpenseEntry.fromJson(Map<String, dynamic> json) => StoreExpenseEntry(
        id: json['id'] as String? ?? '',
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        paymentMode: json['paymentMode'] as String? ?? 'cash',
        date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
        notes: json['notes'] as String? ?? '',
        enteredByStaffId: json['enteredByStaffId'] as String? ?? '',
      );
}

class CashDrawerReconciliation {
  final double openingCash;
  final double cashSales;
  final double cashUdhaarCollections;
  final double cashExpenses;
  final double cashInAdjustments;
  final double cashOutAdjustments;
  final double actualCountedCash;

  const CashDrawerReconciliation({
    required this.openingCash,
    required this.cashSales,
    required this.cashUdhaarCollections,
    required this.cashExpenses,
    this.cashInAdjustments = 0.0,
    this.cashOutAdjustments = 0.0,
    required this.actualCountedCash,
  });

  double get expectedCashInDrawer =>
      openingCash + cashSales + cashUdhaarCollections + cashInAdjustments - cashExpenses - cashOutAdjustments;

  double get discrepancy => actualCountedCash - expectedCashInDrawer;

  bool get isBalanced => discrepancy.abs() < 0.01;
}
