import 'package:ezo_core_models/ezo_core_models.dart';
import 'report_models.dart';

class EzoReportEngine {
  /// 1. GSTR-1 HSN-Wise Summary Aggregator
  static List<Gstr1HsnSummaryRow> generateGstr1HsnSummary(
    List<InvoiceDocument> invoices,
    Map<String, ProductItem> productCatalog,
  ) {
    final Map<String, _HsnAccumulator> accumulator = {};

    for (final inv in invoices) {
      if (inv.isCancelled || inv.docType == InvoiceDocType.kitchenOrderTicketKot) continue;

      for (final line in inv.lineItems) {
        final hsn = line.hsnSacCode.trim().isNotEmpty
            ? line.hsnSacCode.trim()
            : (productCatalog[line.productId]?.hsnSacCode ?? '9999');

        final entry = accumulator.putIfAbsent(
          hsn,
          () => _HsnAccumulator(
            hsn: hsn,
            description: line.itemName,
            uqc: line.unit.label,
          ),
        );

        entry.totalQty += line.quantity;
        entry.totalValue += line.totalAmount;
        entry.taxableValue += line.taxableAmount;
        entry.igst += line.igstAmount;
        entry.cgst += line.cgstAmount;
        entry.sgst += line.sgstAmount;
      }
    }

    return accumulator.values.map((a) {
      return Gstr1HsnSummaryRow(
        hsnSacCode: a.hsn,
        description: a.description,
        uqc: a.uqc,
        totalQuantity: _round2(a.totalQty),
        totalValue: _round2(a.totalValue),
        taxableValue: _round2(a.taxableValue),
        integratedTaxAmount: _round2(a.igst),
        centralTaxAmount: _round2(a.cgst),
        stateTaxAmount: _round2(a.sgst),
      );
    }).toList();
  }

  /// 2. GSTR-1 B2B Invoices (Customers with valid GSTIN)
  static List<Gstr1B2bInvoiceRow> generateGstr1B2bReport(List<InvoiceDocument> invoices) {
    final List<Gstr1B2bInvoiceRow> b2bRows = [];

    for (final inv in invoices) {
      if (inv.isCancelled || inv.partyGstin.trim().length != 15) continue;

      for (final line in inv.lineItems) {
        b2bRows.add(
          Gstr1B2bInvoiceRow(
            customerGstin: inv.partyGstin.trim().toUpperCase(),
            customerLegalName: inv.partyName,
            invoiceNumber: inv.invoiceNumber,
            invoiceDate: inv.invoiceDate,
            invoiceValue: inv.grandTotal,
            placeOfSupply: '${inv.partyStateCode}-${inv.partyAddress}',
            isReverseCharge: false,
            taxableValue: line.taxableAmount,
            gstRate: line.gstPercent,
            igst: line.igstAmount,
            cgst: line.cgstAmount,
            sgst: line.sgstAmount,
          ),
        );
      }
    }
    return b2bRows;
  }

  /// 3. GSTR-3B Monthly Tax Liability & Input Tax Credit (ITC) Summary
  static Gstr3bSummary generateGstr3bSummary({
    required List<InvoiceDocument> salesInvoices,
    required List<InvoiceDocument> purchaseInvoices,
  }) {
    double outwardTaxable = 0.0;
    double igstPayable = 0.0;
    double cgstPayable = 0.0;
    double sgstPayable = 0.0;

    for (final sale in salesInvoices) {
      if (sale.isCancelled) continue;
      outwardTaxable += sale.taxableSubtotal;
      igstPayable += sale.totalIgst;
      cgstPayable += sale.totalCgst;
      sgstPayable += sale.totalSgst;
    }

    double itcIgst = 0.0;
    double itcCgst = 0.0;
    double itcSgst = 0.0;

    for (final purchase in purchaseInvoices) {
      if (purchase.isCancelled) continue;
      itcIgst += purchase.totalIgst;
      itcCgst += purchase.totalCgst;
      itcSgst += purchase.totalSgst;
    }

    return Gstr3bSummary(
      outwardTaxableSupplies: _round2(outwardTaxable),
      igstPayable: _round2(igstPayable),
      cgstPayable: _round2(cgstPayable),
      sgstPayable: _round2(sgstPayable),
      eligibleItcIgst: _round2(itcIgst),
      eligibleItcCgst: _round2(itcCgst),
      eligibleItcSgst: _round2(itcSgst),
    );
  }

  /// 4. Tax Slab Breakup (0%, 5%, 12%, 18%, 28%)
  static List<TaxSlabBreakupRow> generateTaxSlabBreakup(List<InvoiceDocument> invoices) {
    final Map<double, _TaxSlabAccumulator> slabs = {
      0.0: _TaxSlabAccumulator(0.0),
      5.0: _TaxSlabAccumulator(5.0),
      12.0: _TaxSlabAccumulator(12.0),
      18.0: _TaxSlabAccumulator(18.0),
      28.0: _TaxSlabAccumulator(28.0),
    };

    for (final inv in invoices) {
      if (inv.isCancelled) continue;
      for (final line in inv.lineItems) {
        final rate = line.gstPercent;
        final accum = slabs.putIfAbsent(rate, () => _TaxSlabAccumulator(rate));
        accum.taxable += line.taxableAmount;
        accum.cgst += line.cgstAmount;
        accum.sgst += line.sgstAmount;
        accum.igst += line.igstAmount;
      }
    }

    return slabs.values.map((s) {
      final totalTax = s.cgst + s.sgst + s.igst;
      return TaxSlabBreakupRow(
        gstPercent: s.rate,
        taxableAmount: _round2(s.taxable),
        cgst: _round2(s.cgst),
        sgst: _round2(s.sgst),
        igst: _round2(s.igst),
        totalTax: _round2(totalTax),
      );
    }).toList()
      ..sort((a, b) => a.gstPercent.compareTo(b.gstPercent));
  }

  /// 5. Profit & Loss Statement (Gross Revenue - COGS - Expenses)
  static ProfitAndLossStatement generateProfitAndLoss({
    required List<InvoiceDocument> sales,
    required Map<String, ProductItem> productsMap,
    required double totalExpenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    double grossRevenue = 0.0;
    double cogs = 0.0;

    for (final inv in sales) {
      if (inv.isCancelled) continue;
      if (inv.invoiceDate.isBefore(startDate) || inv.invoiceDate.isAfter(endDate)) continue;

      grossRevenue += inv.grandTotal;

      for (final line in inv.lineItems) {
        final prod = productsMap[line.productId];
        final unitCost = prod?.purchasePrice ?? 0.0;
        cogs += (unitCost * line.quantity);
      }
    }

    final grossProfit = grossRevenue - cogs;
    final netProfit = grossProfit - totalExpenses;
    final grossMargin = grossRevenue > 0 ? (grossProfit / grossRevenue) * 100.0 : 0.0;
    final netMargin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100.0 : 0.0;

    return ProfitAndLossStatement(
      startDate: startDate,
      endDate: endDate,
      grossRevenue: _round2(grossRevenue),
      costOfGoodsSold: _round2(cogs),
      grossProfit: _round2(grossProfit),
      operatingExpenses: _round2(totalExpenses),
      netProfit: _round2(netProfit),
      grossMarginPercent: _round2(grossMargin),
      netMarginPercent: _round2(netMargin),
    );
  }

  /// 6. Bill-Wise Profit Margin Report
  static List<BillWiseProfitRow> generateBillWiseProfit(
    List<InvoiceDocument> sales,
    Map<String, ProductItem> productsMap,
  ) {
    return sales.where((i) => !i.isCancelled).map((inv) {
      double cost = 0.0;
      for (final line in inv.lineItems) {
        final prod = productsMap[line.productId];
        cost += (prod?.purchasePrice ?? 0.0) * line.quantity;
      }
      final profit = inv.grandTotal - cost;
      final margin = inv.grandTotal > 0 ? (profit / inv.grandTotal) * 100.0 : 0.0;

      return BillWiseProfitRow(
        invoiceNumber: inv.invoiceNumber,
        date: inv.invoiceDate,
        customerName: inv.partyName,
        sellingTotal: _round2(inv.grandTotal),
        costTotal: _round2(cost),
        grossProfit: _round2(profit),
        marginPercent: _round2(margin),
      );
    }).toList();
  }

  /// 7. Customer Khata Ageing Report (0-30, 31-60, 61-90, 90+ days)
  static List<CustomerAgeingRow> generateCustomerAgeingReport(List<PartyAccount> customers) {
    final now = DateTime.now();
    final List<CustomerAgeingRow> rows = [];

    for (final customer in customers) {
      if (customer.partyType != PartyType.customer || customer.netBalance <= 0) continue;

      double d0To30 = 0.0;
      double d31To60 = 0.0;
      double d61To90 = 0.0;
      double d90Plus = 0.0;

      for (final entry in customer.ledgerEntries) {
        if (entry.debitYouGave > 0) {
          final ageDays = now.difference(entry.entryDate).inDays;
          if (ageDays <= 30) {
            d0To30 += entry.debitYouGave;
          } else if (ageDays <= 60) {
            d31To60 += entry.debitYouGave;
          } else if (ageDays <= 90) {
            d61To90 += entry.debitYouGave;
          } else {
            d90Plus += entry.debitYouGave;
          }
        }
      }

      // If no itemized entries, assign opening balance to 90+ days
      if (d0To30 == 0 && d31To60 == 0 && d61To90 == 0 && d90Plus == 0) {
        d90Plus = customer.netBalance;
      }

      rows.add(
        CustomerAgeingRow(
          customerId: customer.id,
          customerName: customer.name,
          phone: customer.phone,
          totalDue: _round2(customer.netBalance),
          days0To30: _round2(d0To30),
          days31To60: _round2(d31To60),
          days61To90: _round2(d61To90),
          days90Plus: _round2(d90Plus),
        ),
      );
    }
    return rows;
  }

  /// 8. Salesperson-Wise Billing & Udhaar Collection Report
  static List<SalespersonPerformanceRow> generateSalespersonPerformance({
    required List<InvoiceDocument> invoices,
    required List<KhataLedgerEntry> collections,
    required List<StaffMember> staffMembers,
  }) {
    final Map<String, _StaffAccumulator> map = {};

    for (final staff in staffMembers) {
      map[staff.id] = _StaffAccumulator(staffId: staff.id, staffName: staff.fullName);
    }

    for (final inv in invoices) {
      if (inv.isCancelled) continue;
      final staffId = inv.cashierStaffId;
      final accum = map.putIfAbsent(
        staffId,
        () => _StaffAccumulator(staffId: staffId, staffName: inv.cashierStaffName),
      );
      accum.billsCount++;
      accum.totalBilled += inv.grandTotal;

      if (inv.settlementMode == SettlementMode.cash) {
        accum.cash += inv.amountReceived;
      } else if (inv.settlementMode == SettlementMode.upiQr) {
        accum.upi += inv.amountReceived;
      } else if (inv.settlementMode == SettlementMode.creditUdhaar) {
        accum.udhaar += inv.balanceUdhaarDue;
        accum.cash += inv.amountReceived;
      }
    }

    for (final col in collections) {
      if (col.creditYouGot > 0) {
        final accum = map.putIfAbsent(
          col.collectedByStaffId,
          () => _StaffAccumulator(
            staffId: col.collectedByStaffId,
            staffName: col.collectedByStaffName,
          ),
        );
        if (col.paymentMode == 'upi') {
          accum.upi += col.creditYouGot;
        } else {
          accum.cash += col.creditYouGot;
        }
      }
    }

    return map.values.map((s) {
      return SalespersonPerformanceRow(
        staffId: s.staffId,
        staffName: s.staffName.isNotEmpty ? s.staffName : 'Unknown Staff',
        billsGenerated: s.billsCount,
        totalBilledAmount: _round2(s.totalBilled),
        cashCollected: _round2(s.cash),
        upiCollected: _round2(s.upi),
        udhaarBooked: _round2(s.udhaar),
      );
    }).toList();
  }

  /// 9. Stock Valuation Summary
  static StockValuationSummary generateStockValuation(List<ProductItem> products) {
    double totalQty = 0.0;
    double costVal = 0.0;
    double retailVal = 0.0;

    for (final p in products) {
      totalQty += p.currentStock;
      costVal += p.stockAssetValueAtCost;
      retailVal += p.stockRetailValue;
    }

    return StockValuationSummary(
      totalSkus: products.length,
      totalQuantity: _round2(totalQty),
      totalAssetValueAtCost: _round2(costVal),
      totalRetailValue: _round2(retailVal),
      potentialGrossProfit: _round2(retailVal - costVal),
    );
  }

  /// Universal CSV Formatter for export
  static String exportToCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }
    return buffer.toString();
  }

  static String _escapeCsvCell(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  static double _round2(double val) {
    return (val * 100.0).roundToDouble() / 100.0;
  }
}

class _HsnAccumulator {
  final String hsn;
  final String description;
  final String uqc;
  double totalQty = 0.0;
  double totalValue = 0.0;
  double taxableValue = 0.0;
  double igst = 0.0;
  double cgst = 0.0;
  double sgst = 0.0;

  _HsnAccumulator({
    required this.hsn,
    required this.description,
    required this.uqc,
  });
}

class _TaxSlabAccumulator {
  final double rate;
  double taxable = 0.0;
  double cgst = 0.0;
  double sgst = 0.0;
  double igst = 0.0;

  _TaxSlabAccumulator(this.rate);
}

class _StaffAccumulator {
  final String staffId;
  final String staffName;
  int billsCount = 0;
  double totalBilled = 0.0;
  double cash = 0.0;
  double upi = 0.0;
  double udhaar = 0.0;

  _StaffAccumulator({required this.staffId, required this.staffName});
}
