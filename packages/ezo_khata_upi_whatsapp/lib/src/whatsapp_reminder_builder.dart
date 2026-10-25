import 'package:ezo_core_models/ezo_core_models.dart';
import 'upi_qr_generator.dart';

class WhatsAppReminderBuilder {
  /// Formats a personalized, high-converting WhatsApp payment reminder
  static String buildReminderText({
    required PartyAccount customer,
    required BusinessProfile storeProfile,
    String portalBaseUrl = 'https://in.co.ezo/khata',
  }) {
    final balance = customer.netBalance;
    final upiLink = storeProfile.upiId.isNotEmpty
        ? UpiQrGenerator.buildUpiPaymentUri(
            merchantUpiId: storeProfile.upiId,
            merchantName: storeProfile.storeName,
            amount: balance,
            note: 'Udhaar Clearance for ${customer.name}',
          )
        : '';

    final dueDateStr = customer.nextReminderDate != null
        ? '${customer.nextReminderDate!.day}/${customer.nextReminderDate!.month}/${customer.nextReminderDate!.year}'
        : 'Immediate';

    final onlineLedgerUrl = '$portalBaseUrl/${storeProfile.id}/${customer.id}';

    final buffer = StringBuffer();
    buffer.writeln('🙏 Namaste *${customer.name}*,');
    buffer.writeln();
    buffer.writeln('This is a gentle payment reminder from *${storeProfile.storeName}*.');
    buffer.writeln();
    buffer.writeln('💰 *Total Overdue Balance:* ₹${balance.toStringAsFixed(2)}');
    buffer.writeln('📅 *Payment Due Date:* $dueDateStr');
    buffer.writeln();

    if (upiLink.isNotEmpty) {
      buffer.writeln('🚀 *1-Tap Instant UPI Payment:*');
      buffer.writeln(upiLink);
      buffer.writeln();
    }

    buffer.writeln('📄 *View Your Complete Online Khata Ledger Statement:*');
    buffer.writeln(onlineLedgerUrl);
    buffer.writeln();
    buffer.writeln('If you have already paid, please ignore this message.');
    buffer.writeln('Warm Regards,');
    buffer.writeln('*${storeProfile.storeName}*');
    if (storeProfile.phone.isNotEmpty) {
      buffer.writeln('📞 Ph: ${storeProfile.phone}');
    }

    return buffer.toString();
  }

  /// Generates a 1-tap WhatsApp click-to-chat URL: https://wa.me/91<phone>?text=...
  static String buildWaMeLink({
    required PartyAccount customer,
    required BusinessProfile storeProfile,
    String portalBaseUrl = 'https://in.co.ezo/khata',
  }) {
    var rawPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length == 10) {
      rawPhone = '91$rawPhone';
    }
    final message = buildReminderText(
      customer: customer,
      storeProfile: storeProfile,
      portalBaseUrl: portalBaseUrl,
    );

    return 'https://wa.me/$rawPhone?text=${Uri.encodeComponent(message)}';
  }

  /// Builds an instant WhatsApp payment acknowledgement receipt
  static String buildPaymentReceiptText({
    required PartyAccount customer,
    required BusinessProfile storeProfile,
    required double amountPaid,
    required String paymentMode,
    required double remainingBalance,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('✅ *Payment Received with Thanks!*');
    buffer.writeln();
    buffer.writeln('Dear *${customer.name}*,');
    buffer.writeln('We have successfully received your payment of *₹${amountPaid.toStringAsFixed(2)}* via *${paymentMode.toUpperCase()}*.');
    buffer.writeln();
    buffer.writeln('📊 *Remaining Balance:* ₹${remainingBalance.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('Thank you for shopping with *${storeProfile.storeName}*!');
    return buffer.toString();
  }
}
