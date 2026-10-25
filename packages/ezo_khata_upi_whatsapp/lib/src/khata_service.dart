import 'package:ezo_core_models/ezo_core_models.dart';
import 'whatsapp_reminder_builder.dart';

class EzoKhataService {
  final EzoOfflineRepository repository;

  EzoKhataService({required this.repository});

  /// Records Udhaar debit entry automatically when an invoice has unpaid balance
  Future<void> postInvoiceUdhaarEntry(InvoiceDocument invoice) async {
    if (invoice.balanceUdhaarDue <= 0 || invoice.partyId.isEmpty) return;

    final entry = KhataLedgerEntry(
      id: 'khata_${invoice.id}',
      partyId: invoice.partyId,
      entryDate: invoice.invoiceDate,
      debitYouGave: invoice.balanceUdhaarDue,
      creditYouGot: 0.0,
      paymentMode: 'invoice_credit',
      collectedByStaffId: invoice.cashierStaffId,
      collectedByStaffName: invoice.cashierStaffName,
      referenceInvoiceNumber: invoice.invoiceNumber,
      notes: 'Bill #${invoice.invoiceNumber}',
      createdAt: DateTime.now(),
    );

    await repository.db.addKhataEntry(entry);
  }

  /// Records incoming customer payment and generates a WhatsApp receipt message
  Future<String> recordCustomerPayment({
    required String customerId,
    required double amount,
    required String paymentMode,
    required BusinessProfile storeProfile,
    required StaffMember cashier,
    String notes = '',
  }) async {
    final customer = repository.getParty(customerId);
    if (customer == null) throw ArgumentError('Customer not found');

    await repository.recordPartyPayment(
      partyId: customerId,
      amount: amount,
      paymentMode: paymentMode,
      collectedByStaffId: cashier.id,
      collectedByStaffName: cashier.fullName,
      notes: notes,
    );

    final updatedCustomer = repository.getParty(customerId)!;
    return WhatsAppReminderBuilder.buildPaymentReceiptText(
      customer: updatedCustomer,
      storeProfile: storeProfile,
      amountPaid: amount,
      paymentMode: paymentMode,
      remainingBalance: updatedCustomer.netBalance,
    );
  }

  /// Returns customers whose payments are due today or overdue
  List<PartyAccount> getOverdueCustomers() {
    return repository
        .getCustomerParties()
        .where((c) => c.isPaymentDueTodayOrOverdue)
        .toList();
  }

  /// Returns top customers by pending Udhaar balance
  List<PartyAccount> getTopDebtors({int limit = 10}) {
    final list = repository.getCustomerParties().where((c) => c.netBalance > 0).toList()
      ..sort((a, b) => b.netBalance.compareTo(a.netBalance));
    return list.take(limit).toList();
  }

  /// Returns all suppliers with pending payables
  List<PartyAccount> getPendingSuppliers() {
    return repository.getSupplierParties().where((s) => s.netBalance > 0).toList();
  }
}
