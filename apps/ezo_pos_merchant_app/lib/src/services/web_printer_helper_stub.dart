// Stub implementation for native mobile / desktop (no-op)
void triggerWebPrintReceipt({
  required String asciiReceipt,
  required String invoiceNumber,
  required int rollWidthMm,
}) {
  // No-op on non-web platforms; native Bluetooth/USB drivers handle printing.
}
