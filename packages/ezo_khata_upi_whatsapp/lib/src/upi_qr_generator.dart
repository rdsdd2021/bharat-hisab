class UpiQrGenerator {
  /// Builds strict NPCI-compliant UPI payment URI that pre-locks the payment amount
  static String buildUpiPaymentUri({
    required String merchantUpiId,
    required String merchantName,
    required double amount,
    String note = 'Payment to merchant',
    String? transactionRef,
  }) {
    final cleanUpi = merchantUpiId.trim();
    final cleanAmount = amount.toStringAsFixed(2);
    final encodedName = Uri.encodeComponent(merchantName.trim());
    final encodedNote = Uri.encodeComponent(note.trim());

    final buffer = StringBuffer('upi://pay?pa=$cleanUpi&pn=$encodedName&am=$cleanAmount&cu=INR&tn=$encodedNote');

    if (transactionRef != null && transactionRef.isNotEmpty) {
      buffer.write('&tr=${Uri.encodeComponent(transactionRef)}');
    }

    return buffer.toString();
  }

  /// Validates standard Indian UPI ID (VPA) format
  static bool isValidUpiId(String upiId) {
    final regex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return regex.hasMatch(upiId.trim());
  }
}
