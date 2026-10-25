import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'indian_currency_words.dart';

enum PdfInvoiceTemplate {
  a4ModernGst,
  a4TallyClassicGrid,
  a5LandscapeCompact,
}

class A4A5InvoicePdfBuilder {
  /// Generates self-contained print-ready HTML/CSS for A4 & A5 formats
  static String buildHtmlDocument({
    required InvoiceDocument invoice,
    required BusinessProfile storeProfile,
    PdfInvoiceTemplate template = PdfInvoiceTemplate.a4ModernGst,
  }) {
    switch (template) {
      case PdfInvoiceTemplate.a4ModernGst:
        return _renderModernA4(invoice, storeProfile);
      case PdfInvoiceTemplate.a4TallyClassicGrid:
        return _renderTallyA4(invoice, storeProfile);
      case PdfInvoiceTemplate.a5LandscapeCompact:
        return _renderA5Landscape(invoice, storeProfile);
    }
  }

  static String _renderModernA4(InvoiceDocument invoice, BusinessProfile store) {
    final amountWords = IndianCurrencyWordsFormatter.format(invoice.grandTotal);
    final primaryColor = store.branding.primaryColorHex;
    final slabs = EzoReportEngine.generateTaxSlabBreakup([invoice]);

    final rowsBuffer = StringBuffer();
    for (int i = 0; i < invoice.lineItems.length; i++) {
      final line = invoice.lineItems[i];
      rowsBuffer.write('''
        <tr>
          <td style="text-align:center;">${i + 1}</td>
          <td><b>${line.itemName}</b>${line.cookingNotes.isNotEmpty ? '<br><small>${line.cookingNotes}</small>' : ''}</td>
          <td style="text-align:center;">${line.hsnSacCode}</td>
          <td style="text-align:right;">${line.quantity} ${line.unit.label}</td>
          <td style="text-align:right;">${line.unitSellingPrice.toStringAsFixed(2)}</td>
          <td style="text-align:right;">${line.lineDiscountAmount.toStringAsFixed(2)}</td>
          <td style="text-align:right;">${line.taxableAmount.toStringAsFixed(2)}</td>
          <td style="text-align:center;">${line.gstPercent}%</td>
          <td style="text-align:right;">${line.cgstAmount.toStringAsFixed(2)}</td>
          <td style="text-align:right;">${line.sgstAmount.toStringAsFixed(2)}</td>
          <td style="text-align:right;">${line.igstAmount.toStringAsFixed(2)}</td>
          <td style="text-align:right;"><b>${line.totalAmount.toStringAsFixed(2)}</b></td>
        </tr>
      ''');
    }

    final slabsBuffer = StringBuffer();
    for (final s in slabs) {
      if (s.taxableAmount > 0) {
        slabsBuffer.write('''
          <tr>
            <td style="text-align:center;">${s.gstPercent}%</td>
            <td style="text-align:right;">${s.taxableAmount.toStringAsFixed(2)}</td>
            <td style="text-align:right;">${s.cgst.toStringAsFixed(2)}</td>
            <td style="text-align:right;">${s.sgst.toStringAsFixed(2)}</td>
            <td style="text-align:right;">${s.igst.toStringAsFixed(2)}</td>
            <td style="text-align:right;"><b>${s.totalTax.toStringAsFixed(2)}</b></td>
          </tr>
        ''');
      }
    }

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>${invoice.invoiceNumber} - ${store.storeName}</title>
<style>
  @page { size: A4 portrait; margin: 12mm; }
  body { font-family: 'Helvetica Neue', Arial, sans-serif; font-size: 11px; color: #222; margin: 0; padding: 0; }
  .header-table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
  .header-brand { font-size: 22px; font-weight: bold; color: $primaryColor; }
  .tagline { font-size: 11px; color: #666; margin-top: 2px; }
  .inv-badge { background: $primaryColor; color: #fff; padding: 6px 14px; font-size: 14px; font-weight: bold; border-radius: 4px; display: inline-block; }
  .meta-box { border: 1px solid #ddd; border-radius: 4px; padding: 8px; margin-bottom: 12px; }
  .two-col { width: 100%; border-collapse: collapse; }
  .two-col td { vertical-align: top; width: 50%; }
  table.items-table { width: 100%; border-collapse: collapse; margin-top: 10px; margin-bottom: 12px; }
  table.items-table th { background: #f4f6f9; border: 1px solid #ddd; padding: 6px; font-size: 10px; text-transform: uppercase; color: #333; }
  table.items-table td { border: 1px solid #eee; padding: 6px; }
  .savings-box { background: #e8f5e9; border: 1px solid #a5d6a7; color: #2e7d32; padding: 8px; font-size: 13px; font-weight: bold; text-align: center; border-radius: 4px; margin-bottom: 12px; }
  .total-table { width: 100%; border-collapse: collapse; }
  .total-table td { padding: 4px 8px; }
  .grand-total-row { font-size: 14px; font-weight: bold; background: #fafafa; border-top: 2px solid $primaryColor; }
  .footer-box { border-top: 1px solid #ddd; padding-top: 10px; margin-top: 20px; }
</style>
</head>
<body>

<table class="header-table">
  <tr>
    <td style="width: 65%;">
      <div class="header-brand">${store.storeName}</div>
      <div class="tagline">${store.legalEntityName}</div>
      <div>${store.address}</div>
      <div>Ph: ${store.phone} | Email: ${store.email}</div>
      <div><b>GSTIN:</b> ${store.gstin.isNotEmpty ? store.gstin : 'Unregistered'} | <b>State:</b> ${store.stateName} (${store.stateCode})</div>
    </td>
    <td style="width: 35%; text-align: right;">
      <div class="inv-badge">${invoice.docType == InvoiceDocType.gstTaxInvoice ? 'TAX INVOICE' : 'BILL OF SUPPLY'}</div>
      <div style="margin-top: 6px;"><b>Invoice No:</b> ${invoice.invoiceNumber}</div>
      <div><b>Date:</b> ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}</div>
      ${invoice.customFields.ewayBillNumber.isNotEmpty ? '<div><b>E-Way Bill:</b> ' + invoice.customFields.ewayBillNumber + '</div>' : ''}
    </td>
  </tr>
</table>

<div class="meta-box">
  <table class="two-col">
    <tr>
      <td>
        <b>Billed To (Customer Details):</b><br>
        <b>Name:</b> ${invoice.partyName}<br>
        ${invoice.partyPhone.isNotEmpty ? '<b>Phone:</b> ' + invoice.partyPhone + '<br>' : ''}
        ${invoice.partyAddress.isNotEmpty ? '<b>Address:</b> ' + invoice.partyAddress + '<br>' : ''}
        <b>GSTIN:</b> ${invoice.partyGstin.isNotEmpty ? invoice.partyGstin : 'URP (Consumer)'}<br>
        <b>State:</b> ${invoice.partyStateCode}
      </td>
      <td>
        <b>Shipping & Settlement Details:</b><br>
        <b>Settlement Mode:</b> ${invoice.settlementMode.name.toUpperCase()}<br>
        <b>Place of Supply:</b> ${invoice.partyStateCode}<br>
        ${invoice.customFields.poNumber.isNotEmpty ? '<b>PO Number:</b> ' + invoice.customFields.poNumber + '<br>' : ''}
        ${invoice.customFields.vehicleNumber.isNotEmpty ? '<b>Vehicle No:</b> ' + invoice.customFields.vehicleNumber + '<br>' : ''}
        <b>Cashier / Rep:</b> ${invoice.cashierStaffName}
      </td>
    </tr>
  </table>
</div>

${invoice.customerSavings > 0 ? '<div class="savings-box">🎉 Instant Customer Savings: You Saved Rs. ' + invoice.customerSavings.toStringAsFixed(2) + ' on this bill!</div>' : ''}

<table class="items-table">
  <thead>
    <tr>
      <th style="width: 25px;">#</th>
      <th>Item Description</th>
      <th style="width: 50px;">HSN</th>
      <th style="width: 55px;">Qty</th>
      <th style="width: 55px;">Rate</th>
      <th style="width: 45px;">Disc</th>
      <th style="width: 60px;">Taxable</th>
      <th style="width: 40px;">GST</th>
      <th style="width: 45px;">CGST</th>
      <th style="width: 45px;">SGST</th>
      <th style="width: 45px;">IGST</th>
      <th style="width: 65px;">Total</th>
    </tr>
  </thead>
  <tbody>
    $rowsBuffer
  </tbody>
</table>

<table class="two-col">
  <tr>
    <td style="padding-right: 15px;">
      <b>Amount in Words:</b><br>
      <i>$amountWords</i><br><br>

      <b>Bank Account Details:</b><br>
      Bank Name: ${store.bankName}<br>
      Account No: ${store.accountNumber}<br>
      IFSC Code: ${store.ifscCode}<br>
      UPI VPA: ${store.upiId}<br><br>

      <b>Terms & Conditions:</b><br>
      ${store.termsAndConditions}
    </td>
    <td>
      <table class="total-table">
        <tr><td>Taxable Subtotal:</td><td style="text-align:right;">Rs. ${invoice.taxableSubtotal.toStringAsFixed(2)}</td></tr>
        ${invoice.totalCgst > 0 ? '<tr><td>Total CGST:</td><td style="text-align:right;">Rs. ' + invoice.totalCgst.toStringAsFixed(2) + '</td></tr>' : ''}
        ${invoice.totalSgst > 0 ? '<tr><td>Total SGST:</td><td style="text-align:right;">Rs. ' + invoice.totalSgst.toStringAsFixed(2) + '</td></tr>' : ''}
        ${invoice.totalIgst > 0 ? '<tr><td>Total IGST:</td><td style="text-align:right;">Rs. ' + invoice.totalIgst.toStringAsFixed(2) + '</td></tr>' : ''}
        ${invoice.billDiscountAmount > 0 ? '<tr><td>Bill Discount:</td><td style="text-align:right; color:red;">- Rs. ' + invoice.billDiscountAmount.toStringAsFixed(2) + '</td></tr>' : ''}
        ${invoice.roundOffAdjustment != 0 ? '<tr><td>Round Off:</td><td style="text-align:right;">Rs. ' + invoice.roundOffAdjustment.toStringAsFixed(2) + '</td></tr>' : ''}
        <tr class="grand-total-row">
          <td><b>GRAND TOTAL:</b></td>
          <td style="text-align:right; color:$primaryColor;"><b>Rs. ${invoice.grandTotal.toStringAsFixed(2)}</b></td>
        </tr>
        <tr><td>Amount Received:</td><td style="text-align:right;">Rs. ${invoice.amountReceived.toStringAsFixed(2)}</td></tr>
        ${invoice.balanceUdhaarDue > 0 ? '<tr style="color:red; font-weight:bold;"><td>Balance Udhaar Due:</td><td style="text-align:right;">Rs. ' + invoice.balanceUdhaarDue.toStringAsFixed(2) + '</td></tr>' : ''}
      </table>

      <div style="margin-top: 30px; text-align: right;">
        For <b>${store.storeName}</b><br><br><br>
        Authorised Signatory
      </div>
    </td>
  </tr>
</table>

</body>
</html>
    ''';
  }

  static String _renderTallyA4(InvoiceDocument invoice, BusinessProfile store) {
    // Tally-Style Classic Double Border Grid Preferred by Wholesalers and CAs
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Tally Grid - ${invoice.invoiceNumber}</title>
<style>
  @page { size: A4 portrait; margin: 10mm; }
  body { font-family: 'Courier New', Courier, monospace; font-size: 11px; margin: 0; padding: 0; }
  .grid-container { border: 2px solid #000; padding: 0; width: 100%; }
  .cell-header { text-align: center; border-bottom: 2px solid #000; padding: 6px; }
  .grid-table { width: 100%; border-collapse: collapse; }
  .grid-table th, .grid-table td { border: 1px solid #000; padding: 4px 6px; }
</style>
</head>
<body>
<div class="grid-container">
  <div class="cell-header">
    <div style="font-size:16px; font-weight:bold;">${store.storeName}</div>
    <div>${store.legalEntityName} - ${store.address}</div>
    <div>GSTIN: ${store.gstin} | State Code: ${store.stateCode}</div>
    <div style="font-weight:bold; margin-top:4px;">TAX INVOICE (FORM GST INV-1)</div>
  </div>

  <table class="grid-table">
    <tr>
      <td style="width:50%;">
        <b>Buyer (Bill to):</b><br>
        ${invoice.partyName}<br>
        GSTIN: ${invoice.partyGstin}<br>
        State: ${invoice.partyStateCode}
      </td>
      <td style="width:50%;">
        <b>Invoice No:</b> ${invoice.invoiceNumber}<br>
        <b>Dated:</b> ${invoice.invoiceDate.day}-${invoice.invoiceDate.month}-${invoice.invoiceDate.year}<br>
        <b>Mode of Payment:</b> ${invoice.settlementMode.name.toUpperCase()}
      </td>
    </tr>
  </table>

  <table class="grid-table" style="border-top:2px solid #000;">
    <thead>
      <tr style="background:#eee;">
        <th>Sl.</th>
        <th>Description of Goods</th>
        <th>HSN/SAC</th>
        <th>Quantity</th>
        <th>Rate</th>
        <th>per</th>
        <th>Amount</th>
      </tr>
    </thead>
    <tbody>
      ${invoice.lineItems.asMap().entries.map((e) => '<tr><td>${e.key + 1}</td><td>${e.value.itemName}</td><td>${e.value.hsnSacCode}</td><td style="text-align:right;">${e.value.quantity}</td><td style="text-align:right;">${e.value.unitSellingPrice.toStringAsFixed(2)}</td><td>${e.value.unit.label}</td><td style="text-align:right;">${e.value.totalAmount.toStringAsFixed(2)}</td></tr>').join('')}
      <tr>
        <td colspan="6" style="text-align:right; font-weight:bold;">Total Amount:</td>
        <td style="text-align:right; font-weight:bold;">Rs. ${invoice.grandTotal.toStringAsFixed(2)}</td>
      </tr>
    </tbody>
  </table>

  <div style="padding: 6px;">
    <b>Amount Chargeable (in words):</b> ${IndianCurrencyWordsFormatter.format(invoice.grandTotal)}
  </div>
</div>
</body>
</html>
    ''';
  }

  static String _renderA5Landscape(InvoiceDocument invoice, BusinessProfile store) {
    // Compact Half-Page Landscape Distribution Bill
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>A5 Bill - ${invoice.invoiceNumber}</title>
<style>
  @page { size: A5 landscape; margin: 8mm; }
  body { font-family: Arial, sans-serif; font-size: 10px; margin: 0; padding: 0; }
  .a5-table { width: 100%; border-collapse: collapse; }
  .a5-table th, .a5-table td { border: 1px solid #999; padding: 3px 5px; }
  .header { font-size: 14px; font-weight: bold; }
</style>
</head>
<body>
<div style="display:flex; justify-content:space-between; margin-bottom:6px;">
  <div>
    <span class="header">${store.storeName}</span> | Ph: ${store.phone}<br>
    GSTIN: ${store.gstin} | State: ${store.stateCode}
  </div>
  <div style="text-align:right;">
    <b>Bill No: ${invoice.invoiceNumber}</b><br>
    Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}
  </div>
</div>

<div style="margin-bottom:6px;">
  Customer: <b>${invoice.partyName}</b> | Ph: ${invoice.partyPhone} | GST: ${invoice.partyGstin}
</div>

<table class="a5-table">
  <thead>
    <tr style="background:#f0f0f0;">
      <th>#</th>
      <th>Item</th>
      <th>HSN</th>
      <th>Qty</th>
      <th>Rate</th>
      <th>Taxable</th>
      <th>GST</th>
      <th>Total</th>
    </tr>
  </thead>
  <tbody>
    ${invoice.lineItems.asMap().entries.map((e) => '<tr><td>${e.key + 1}</td><td>${e.value.itemName}</td><td>${e.value.hsnSacCode}</td><td style="text-align:right;">${e.value.quantity}</td><td style="text-align:right;">${e.value.unitSellingPrice.toStringAsFixed(2)}</td><td style="text-align:right;">${e.value.taxableAmount.toStringAsFixed(2)}</td><td style="text-align:center;">${e.value.gstPercent}%</td><td style="text-align:right;">${e.value.totalAmount.toStringAsFixed(2)}</td></tr>').join('')}
  </tbody>
</table>

<div style="display:flex; justify-content:space-between; margin-top:8px;">
  <div>
    Words: <i>${IndianCurrencyWordsFormatter.format(invoice.grandTotal)}</i><br>
    Payment Mode: <b>${invoice.settlementMode.name.toUpperCase()}</b>
  </div>
  <div style="text-align:right; font-size:12px;">
    <b>Grand Total: Rs. ${invoice.grandTotal.toStringAsFixed(2)}</b><br>
    ${invoice.balanceUdhaarDue > 0 ? '<span style="color:red;">Udhaar Due: Rs. ' + invoice.balanceUdhaarDue.toStringAsFixed(2) + '</span>' : ''}
  </div>
</div>
</body>
</html>
    ''';
  }
}
