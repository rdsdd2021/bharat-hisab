import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';

void main() {
  const store = BusinessProfile(
    id: 'store_pune',
    storeName: 'Royal Kirana',
    legalEntityName: 'Royal Kirana Stores',
    gstin: '27ABCDE1234F1Z5',
    stateCode: '27',
    stateName: 'Maharashtra',
    address: 'Kothrud, Pune',
    phone: '9822001122',
    email: 'royal@kirana.com',
    upiId: 'royalkirana@okaxis',
    bankName: 'Axis Bank',
    accountNumber: '9123456789',
    ifscCode: 'UTIB0000123',
  );

  group('NPCI UPI URI Generator Tests', () {
    test('Builds valid NPCI payment URI locking exact amount and parameters', () {
      final uri = UpiQrGenerator.buildUpiPaymentUri(
        merchantUpiId: 'royalkirana@okaxis',
        merchantName: 'Royal Kirana',
        amount: 1450.50,
        note: 'Udhaar Clearance',
        transactionRef: 'TXN-999',
      );

      expect(uri.startsWith('upi://pay?'), isTrue);
      expect(uri.contains('pa=royalkirana@okaxis'), isTrue);
      expect(uri.contains('am=1450.50'), isTrue);
      expect(uri.contains('cu=INR'), isTrue);
      expect(uri.contains('tr=TXN-999'), isTrue);

      expect(UpiQrGenerator.isValidUpiId('royalkirana@okaxis'), isTrue);
      expect(UpiQrGenerator.isValidUpiId('invalid-upi'), isFalse);
    });
  });

  group('WhatsApp Reminder & Receipt Builder Tests', () {
    test('Formats WhatsApp reminder with UPI link and wa.me deep-link', () {
      final customer = PartyAccount(
        id: 'cust_ramesh',
        name: 'Ramesh Gupta',
        phone: '9890123456',
        nextReminderDate: DateTime(2026, 10, 25),
        openingBalance: 2500.0,
      );

      final reminder = WhatsAppReminderBuilder.buildReminderText(
        customer: customer,
        storeProfile: store,
      );

      expect(reminder.contains('*Ramesh Gupta*'), isTrue);
      expect(reminder.contains('₹2500.00'), isTrue);
      expect(reminder.contains('royalkirana@okaxis'), isTrue);
      expect(reminder.contains('https://in.co.ezo/khata/store_pune/cust_ramesh'), isTrue);

      final waLink = WhatsAppReminderBuilder.buildWaMeLink(
        customer: customer,
        storeProfile: store,
      );
      expect(waLink.startsWith('https://wa.me/919890123456?text='), isTrue);
    });
  });

  group('EzoKhataService Ledger & Payments Tests', () {
    test('Records Udhaar, incoming payment, and computes balance', () async {
      final db = LocalDatabase();
      final repo = EzoOfflineRepository(db: db);
      final khataService = EzoKhataService(repository: repo);

      final customer = PartyAccount(
        id: 'c1',
        name: 'Suresh Kumar',
        phone: '9876500000',
        openingBalance: 500.0,
      );
      await repo.saveParty(customer);

      final staff = StaffMember(
        id: 'staff_1',
        storeProfileId: 'store_pune',
        fullName: 'Vikas Cashier',
        phone: '9000000000',
        pinCode: '1234',
        createdAt: DateTime(2026, 1, 1),
      );

      // Record invoice Udhaar of 800
      final inv = InvoiceDocument(
        id: 'inv_khata_1',
        invoiceNumber: 'INV-100',
        invoiceDate: DateTime.now(),
        storeProfileId: 'store_pune',
        storeStateCode: '27',
        partyId: 'c1',
        grandTotal: 1000.0,
        amountReceived: 200.0, // 800 Udhaar
        createdAt: DateTime.now(),
      );
      await khataService.postInvoiceUdhaarEntry(inv);

      var updated = repo.getParty('c1')!;
      // Opening 500 + 800 Udhaar = 1300 net due
      expect(updated.netBalance, equals(1300.0));

      // Customer makes payment of 1000
      final receiptMsg = await khataService.recordCustomerPayment(
        customerId: 'c1',
        amount: 1000.0,
        paymentMode: 'upi',
        storeProfile: store,
        cashier: staff,
      );

      updated = repo.getParty('c1')!;
      // 1300 - 1000 = 300 remaining
      expect(updated.netBalance, equals(300.0));
      expect(receiptMsg.contains('Remaining Balance:* ₹300.00'), isTrue);
    });
  });

  group('Cash Drawer Reconciliation Tests', () {
    test('Calculates expected cash and balances drawer properly', () {
      const recon = CashDrawerReconciliation(
        openingCash: 5000.0,
        cashSales: 12000.0,
        cashUdhaarCollections: 3000.0,
        cashExpenses: 1500.0,
        actualCountedCash: 18500.0,
      );

      // Expected = 5000 + 12000 + 3000 - 1500 = 18500
      expect(recon.expectedCashInDrawer, equals(18500.0));
      expect(recon.discrepancy, equals(0.0));
      expect(recon.isBalanced, isTrue);
    });
  });
}
