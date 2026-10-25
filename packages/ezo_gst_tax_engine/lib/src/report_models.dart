class Gstr1HsnSummaryRow {
  final String hsnSacCode;
  final String description;
  final String uqc;
  final double totalQuantity;
  final double totalValue;
  final double taxableValue;
  final double integratedTaxAmount;
  final double centralTaxAmount;
  final double stateTaxAmount;
  final double cessAmount;

  const Gstr1HsnSummaryRow({
    required this.hsnSacCode,
    required this.description,
    required this.uqc,
    required this.totalQuantity,
    required this.totalValue,
    required this.taxableValue,
    required this.integratedTaxAmount,
    required this.centralTaxAmount,
    required this.stateTaxAmount,
    this.cessAmount = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'hsnSacCode': hsnSacCode,
        'description': description,
        'uqc': uqc,
        'totalQuantity': totalQuantity,
        'totalValue': totalValue,
        'taxableValue': taxableValue,
        'integratedTaxAmount': integratedTaxAmount,
        'centralTaxAmount': centralTaxAmount,
        'stateTaxAmount': stateTaxAmount,
        'cessAmount': cessAmount,
      };
}

class Gstr1B2bInvoiceRow {
  final String customerGstin;
  final String customerLegalName;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double invoiceValue;
  final String placeOfSupply;
  final bool isReverseCharge;
  final double taxableValue;
  final double gstRate;
  final double igst;
  final double cgst;
  final double sgst;

  const Gstr1B2bInvoiceRow({
    required this.customerGstin,
    required this.customerLegalName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceValue,
    required this.placeOfSupply,
    this.isReverseCharge = false,
    required this.taxableValue,
    required this.gstRate,
    required this.igst,
    required this.cgst,
    required this.sgst,
  });

  Map<String, dynamic> toJson() => {
        'customerGstin': customerGstin,
        'customerLegalName': customerLegalName,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        'invoiceValue': invoiceValue,
        'placeOfSupply': placeOfSupply,
        'isReverseCharge': isReverseCharge,
        'taxableValue': taxableValue,
        'gstRate': gstRate,
        'igst': igst,
        'cgst': cgst,
        'sgst': sgst,
      };
}

class Gstr3bSummary {
  final double outwardTaxableSupplies;
  final double igstPayable;
  final double cgstPayable;
  final double sgstPayable;
  final double cessPayable;
  final double eligibleItcIgst;
  final double eligibleItcCgst;
  final double eligibleItcSgst;

  const Gstr3bSummary({
    required this.outwardTaxableSupplies,
    required this.igstPayable,
    required this.cgstPayable,
    required this.sgstPayable,
    this.cessPayable = 0.0,
    this.eligibleItcIgst = 0.0,
    this.eligibleItcCgst = 0.0,
    this.eligibleItcSgst = 0.0,
  });

  double get netIgstPayable => (igstPayable - eligibleItcIgst).clamp(0.0, double.infinity);
  double get netCgstPayable => (cgstPayable - eligibleItcCgst).clamp(0.0, double.infinity);
  double get netSgstPayable => (sgstPayable - eligibleItcSgst).clamp(0.0, double.infinity);
  double get totalNetTaxPayable => netIgstPayable + netCgstPayable + netSgstPayable + cessPayable;
}

class TaxSlabBreakupRow {
  final double gstPercent;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;

  const TaxSlabBreakupRow({
    required this.gstPercent,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalTax,
  });
}

class ProfitAndLossStatement {
  final DateTime startDate;
  final DateTime endDate;
  final double grossRevenue;
  final double costOfGoodsSold;
  final double grossProfit;
  final double operatingExpenses;
  final double netProfit;
  final double grossMarginPercent;
  final double netMarginPercent;

  const ProfitAndLossStatement({
    required this.startDate,
    required this.endDate,
    required this.grossRevenue,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.netProfit,
    required this.grossMarginPercent,
    required this.netMarginPercent,
  });
}

class BillWiseProfitRow {
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final double sellingTotal;
  final double costTotal;
  final double grossProfit;
  final double marginPercent;

  const BillWiseProfitRow({
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.sellingTotal,
    required this.costTotal,
    required this.grossProfit,
    required this.marginPercent,
  });
}

class CustomerAgeingRow {
  final String customerId;
  final String customerName;
  final String phone;
  final double totalDue;
  final double days0To30;
  final double days31To60;
  final double days61To90;
  final double days90Plus;

  const CustomerAgeingRow({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.totalDue,
    required this.days0To30,
    required this.days31To60,
    required this.days61To90,
    required this.days90Plus,
  });
}

class SalespersonPerformanceRow {
  final String staffId;
  final String staffName;
  final int billsGenerated;
  final double totalBilledAmount;
  final double cashCollected;
  final double upiCollected;
  final double udhaarBooked;

  const SalespersonPerformanceRow({
    required this.staffId,
    required this.staffName,
    required this.billsGenerated,
    required this.totalBilledAmount,
    required this.cashCollected,
    required this.upiCollected,
    required this.udhaarBooked,
  });
}

class StockValuationSummary {
  final int totalSkus;
  final double totalQuantity;
  final double totalAssetValueAtCost;
  final double totalRetailValue;
  final double potentialGrossProfit;

  const StockValuationSummary({
    required this.totalSkus,
    required this.totalQuantity,
    required this.totalAssetValueAtCost,
    required this.totalRetailValue,
    required this.potentialGrossProfit,
  });
}
