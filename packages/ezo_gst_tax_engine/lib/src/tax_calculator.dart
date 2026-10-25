import 'package:ezo_core_models/ezo_core_models.dart';

class EzoGstTaxEngine {
  /// Builds a complete InvoiceLineItem applying precise Indian GST tax rules
  static InvoiceLineItem buildLineItem({
    required ProductItem product,
    required double quantity,
    double? overrideUnitPrice,
    double lineDiscountAmount = 0.0,
    bool isGstInvoice = true,
    bool isInterStateSupply = false,
    String cookingNotes = '',
  }) {
    final effectivePrice = overrideUnitPrice ?? product.sellingPrice;
    final nominalGross = effectivePrice * quantity;
    final grossLine = (nominalGross - lineDiscountAmount).clamp(0.0, double.infinity);

    double taxableAmount = 0.0;
    double totalGst = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double totalAmount = 0.0;

    if (!isGstInvoice || product.gstPercent <= 0.0) {
      taxableAmount = _round2(grossLine);
      totalGst = 0.0;
      totalAmount = taxableAmount;
    } else {
      final gstRate = product.gstPercent;

      if (product.isTaxInclusive) {
        // Taxable = Gross / (1 + GST_Rate/100)
        taxableAmount = _round2(grossLine / (1.0 + (gstRate / 100.0)));
        totalGst = _round2(grossLine - taxableAmount);
        totalAmount = _round2(grossLine);
      } else {
        // Tax-exclusive: Taxable = GrossLine, GST = Taxable * GST_Rate/100
        taxableAmount = _round2(grossLine);
        totalGst = _round2(taxableAmount * (gstRate / 100.0));
        totalAmount = _round2(taxableAmount + totalGst);
      }

      if (isInterStateSupply) {
        // 100% IGST for Inter-State
        igstAmount = totalGst;
        cgstAmount = 0.0;
        sgstAmount = 0.0;
      } else {
        // 50/50 split CGST + SGST for Intra-State
        final halfTax = _round2(totalGst / 2.0);
        cgstAmount = halfTax;
        sgstAmount = _round2(totalGst - halfTax);
        igstAmount = 0.0;
      }
    }

    return InvoiceLineItem(
      productId: product.id,
      itemName: product.name,
      regionalName: product.regionalName,
      hsnSacCode: product.hsnSacCode,
      unit: product.unit,
      quantity: quantity,
      mrp: product.mrp,
      unitSellingPrice: effectivePrice,
      lineDiscountAmount: lineDiscountAmount,
      taxableAmount: taxableAmount,
      gstPercent: isGstInvoice ? product.gstPercent : 0.0,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      totalAmount: totalAmount,
      cookingNotes: cookingNotes,
    );
  }

  /// Assembles line items into an official InvoiceDocument with automatic rounding and savings calculation
  static InvoiceDocument createInvoiceDocument({
    required String id,
    required String invoiceNumber,
    InvoiceDocType docType = InvoiceDocType.gstTaxInvoice,
    SettlementMode settlementMode = SettlementMode.cash,
    required DateTime invoiceDate,
    required BusinessProfile storeProfile,
    PartyAccount? party,
    required List<InvoiceLineItem> lineItems,
    double billLevelDiscount = 0.0,
    double? amountReceived,
    InvoiceCustomFields customFields = const InvoiceCustomFields(),
    StaffMember? cashier,
    String notes = '',
  }) {
    final partyStateCode = party?.stateCode ?? storeProfile.stateCode;

    double taxableSubtotal = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;

    for (final line in lineItems) {
      taxableSubtotal += line.taxableAmount;
      totalCgst += line.cgstAmount;
      totalSgst += line.sgstAmount;
      totalIgst += line.igstAmount;
    }

    taxableSubtotal = _round2(taxableSubtotal);
    totalCgst = _round2(totalCgst);
    totalSgst = _round2(totalSgst);
    totalIgst = _round2(totalIgst);

    final rawTotal = (taxableSubtotal + totalCgst + totalSgst + totalIgst - billLevelDiscount)
        .clamp(0.0, double.infinity);
    final roundedTotal = rawTotal.roundToDouble();
    final roundOffAdjustment = _round2(roundedTotal - rawTotal);
    final grandTotal = roundedTotal;

    final actualReceived = amountReceived ??
        (settlementMode == SettlementMode.creditUdhaar ? 0.0 : grandTotal);

    return InvoiceDocument(
      id: id,
      invoiceNumber: invoiceNumber,
      docType: docType,
      settlementMode: settlementMode,
      invoiceDate: invoiceDate,
      storeProfileId: storeProfile.id,
      storeStateCode: storeProfile.stateCode,
      partyId: party?.id ?? '',
      partyName: party?.name ?? 'Cash Customer',
      partyPhone: party?.phone ?? '',
      partyGstin: party?.gstin ?? '',
      partyStateCode: partyStateCode,
      partyAddress: party?.address ?? '',
      lineItems: lineItems,
      taxableSubtotal: taxableSubtotal,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      billDiscountAmount: billLevelDiscount,
      roundOffAdjustment: roundOffAdjustment,
      grandTotal: grandTotal,
      amountReceived: actualReceived,
      customFields: customFields,
      cashierStaffId: cashier?.id ?? '',
      cashierStaffName: cashier?.fullName ?? 'Store Admin',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  static double _round2(double val) {
    return (val * 100.0).roundToDouble() / 100.0;
  }
}
