import 'khata_ledger_entry.dart';

enum PartyType {
  customer,
  supplier,
}

class PartyAccount {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String gstin;
  final String stateCode;
  final String address;
  final PartyType partyType;
  final double creditLimit;
  final DateTime? nextReminderDate;
  final double openingBalance;
  final List<KhataLedgerEntry> ledgerEntries;

  const PartyAccount({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.gstin = '',
    this.stateCode = '27',
    this.address = '',
    this.partyType = PartyType.customer,
    this.creditLimit = 0.0,
    this.nextReminderDate,
    this.openingBalance = 0.0,
    this.ledgerEntries = const [],
  });

  /// Computed net balance based on opening balance and all ledger entries.
  /// For Customer:
  ///   Positive value = Customer owes you (Receivable / Udhaar)
  ///   Negative value = Advance received from customer
  /// For Supplier:
  ///   Positive value = You owe supplier (Payable)
  ///   Negative value = Advance paid to supplier
  double get netBalance {
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final entry in ledgerEntries) {
      totalDebit += entry.debitYouGave;
      totalCredit += entry.creditYouGot;
    }

    if (partyType == PartyType.customer) {
      // Net receivable = opening balance + (sales debit - payments credit)
      return openingBalance + (totalDebit - totalCredit);
    } else {
      // Net payable = opening balance + (purchases credit - payments debit)
      return openingBalance + (totalCredit - totalDebit);
    }
  }

  bool get isOverCreditLimit {
    if (creditLimit <= 0) return false;
    return netBalance > creditLimit;
  }

  bool get isPaymentDueTodayOrOverdue {
    if (nextReminderDate == null || netBalance <= 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(
      nextReminderDate!.year,
      nextReminderDate!.month,
      nextReminderDate!.day,
    );
    return !reminderDay.isAfter(today);
  }

  PartyAccount copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gstin,
    String? stateCode,
    String? address,
    PartyType? partyType,
    double? creditLimit,
    DateTime? nextReminderDate,
    double? openingBalance,
    List<KhataLedgerEntry>? ledgerEntries,
  }) {
    return PartyAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      stateCode: stateCode ?? this.stateCode,
      address: address ?? this.address,
      partyType: partyType ?? this.partyType,
      creditLimit: creditLimit ?? this.creditLimit,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      openingBalance: openingBalance ?? this.openingBalance,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'stateCode': stateCode,
      'address': address,
      'partyType': partyType.name,
      'creditLimit': creditLimit,
      'nextReminderDate': nextReminderDate?.toIso8601String(),
      'openingBalance': openingBalance,
      'ledgerEntries': ledgerEntries.map((e) => e.toJson()).toList(),
    };
  }

  factory PartyAccount.fromJson(Map<String, dynamic> json) {
    return PartyAccount(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      stateCode: json['stateCode'] as String? ?? '27',
      address: json['address'] as String? ?? '',
      partyType: PartyType.values.firstWhere(
        (e) => e.name == json['partyType'],
        orElse: () => PartyType.customer,
      ),
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      nextReminderDate: json['nextReminderDate'] != null
          ? DateTime.tryParse(json['nextReminderDate'] as String)
          : null,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      ledgerEntries: (json['ledgerEntries'] as List<dynamic>?)
              ?.map((e) => KhataLedgerEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
