# Indian GST & Tax Mathematics Specification

This guide details the mathematical rules, statutory formulas, state code classification, and reporting logic implemented inside [`packages/ezo_gst_tax_engine`](../../packages/ezo_gst_tax_engine).

---

## 1. Statutory Foundations: CGST, SGST & IGST

Under the Indian Goods and Services Tax (GST) Act:
1. **Intra-State Supply**: When the supplier's location (store) and the recipient's place of supply (customer) are in the **same State or Union Territory**:
   - Central GST (CGST) = 50% of Total Tax
   - State/UT GST (SGST) = 50% of Total Tax
   - Integrated GST (IGST) = ₹0.00
2. **Inter-State Supply**: When the store and customer are in **different States or Union Territories**:
   - Integrated GST (IGST) = 100% of Total Tax
   - Central GST (CGST) = ₹0.00
   - State GST (SGST) = ₹0.00

### 1.1 State Code Decision Logic

Every Indian GSTIN begins with a **2-digit State Code** (e.g., `27` for Maharashtra, `29` for Karnataka, `07` for Delhi).

```dart
final bool isInterState = store.stateCode.trim() != (party?.stateCode ?? store.stateCode).trim();

if (isInterState) {
  igstAmount = totalGst;
  cgstAmount = 0.0;
  sgstAmount = 0.0;
} else {
  igstAmount = 0.0;
  cgstAmount = totalGst / 2.0;
  sgstAmount = totalGst / 2.0;
}
```

---

## 2. Invoicing Tax Calculation Formulas

EZO supports both **Tax-Inclusive Pricing** (Retail / Kirana / FMCG) and **Tax-Exclusive Pricing** (Wholesale / Hardware / B2B Distribution).

### 2.1 Tax-Inclusive MRP Reverse Math

When a product's price tag includes all taxes (e.g., MRP ₹118 with 18% GST):

$$\text{Gross Line Amount} = \text{Unit Price} \times \text{Quantity} - \text{Line Discount}$$

$$\text{Taxable Value} = \frac{\text{Gross Line Amount}}{1 + \left(\frac{\text{GST Rate}}{100}\right)}$$

$$\text{Total GST} = \text{Gross Line Amount} - \text{Taxable Value}$$

#### Worked Example:
- Item: Amul Butter 500g
- Unit Price (MRP Inclusive): ₹275.00
- GST Slab: 12%
- Quantity: 2
- Gross Line: $275 \times 2 = ₹550.00$
- Taxable Value: $\frac{550}{1 + 0.12} = \frac{550}{1.12} = ₹491.07$
- Total GST: $550 - 491.07 = ₹58.93$
- Intra-State Split: CGST (6%) = ₹29.465, SGST (6%) = ₹29.465

---

### 2.2 Tax-Exclusive Pricing Math

When a quote is given excluding tax (e.g., Wholesale Price ₹1,000 + 18% GST):

$$\text{Taxable Value} = \text{Unit Price} \times \text{Quantity} - \text{Line Discount}$$

$$\text{Total GST} = \text{Taxable Value} \times \left(\frac{\text{GST Rate}}{100}\right)$$

$$\text{Gross Line Amount} = \text{Taxable Value} + \text{Total GST}$$

#### Worked Example:
- Item: Havells LED Floodlight 50W
- Unit Wholesale Price: ₹1,200.00
- GST Slab: 18%
- Quantity: 5
- Taxable Value: $1,200 \times 5 = ₹6,000.00$
- Total GST: $6,000 \times 0.18 = ₹1,080.00$
- Intra-State Split: CGST (9%) = ₹540.00, SGST (9%) = ₹540.00
- Gross Line Total: $6,000 + 1,080 = ₹7,080.00$

---

## 3. Automatic Nearest-Rupee Round-Off Adjustment

Indian commercial law and currency circulation discourage fractional paise in cash transactions. EZO automatically calculates the exact round-off delta:

$$\text{Raw Total} = \sum \text{Taxable Values} + \sum \text{CGST} + \sum \text{SGST} + \sum \text{IGST} - \text{Bill Discount}$$

$$\text{Final Grand Total} = \text{round}(\text{Raw Total})$$

$$\text{Round-Off Adjustment} = \text{Final Grand Total} - \text{Raw Total}$$

#### Edge Case Handling:
- If Raw Total = ₹1,248.40 $\rightarrow$ Final Grand Total = ₹1,248.00 $\rightarrow$ Round-Off = **-₹0.40**
- If Raw Total = ₹1,248.65 $\rightarrow$ Final Grand Total = ₹1,249.00 $\rightarrow$ Round-Off = **+₹0.35**

---

## 4. "You Saved" Consumer Psychology Math

To drive customer loyalty on retail thermal receipts, EZO calculates the cumulative consumer savings comparing the Maximum Retail Price (MRP) against actual billed prices:

$$\text{Savings}_{\text{line}} = (\text{Item MRP} - \text{Unit Selling Price}) \times \text{Quantity} + \text{Line Discount}$$

$$\text{Total Customer Savings} = \sum \text{Savings}_{\text{line}} + \text{Bill Level Discount}$$

When Total Savings $> 0$, the thermal printer renders a high-visibility boxed callout:
```
================================
  *** YOU SAVED Rs. 142.50 ***
================================
```

---

## 5. HSN / SAC Summary Generator for GSTR-1

Section 12 of Indian GSTR-1 requires reporting aggregate values grouped by Harmonized System of Nomenclature (HSN) or Service Accounting Code (SAC):

```dart
class HsnSummaryItem {
  final String hsnSacCode;
  final double gstRate;
  final double totalQuantity;
  final double totalTaxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTaxAmount;
}
```

The engine aggregates every invoice line across the billing period and outputs a ready-to-file table formatted for the **GSTN Offline Tool** (Excel/JSON).

---

## 6. The 50+ Business & Tax Reports Suite

Implemented in `EzoReportEngine`, the monorepo provides instant analytics without external BI tools:

| Report Category | Key Reports | Export Formats |
|---|---|---|
| **Tax Compliance** | GSTR-1 B2B (Table 4), GSTR-1 B2C Large (Table 5), GSTR-1 B2C Small (Table 7), GSTR-3B Summary, HSN Table 12, Non-GST Bills Summary | CSV, Excel, PDF |
| **Sales Analytics** | Daily Sales Register, Cashier Shift Register, Settlement Mode Breakdown (Cash vs UPI vs Card vs Udhaar), Hourly Peak Sales | Screen, Print, PDF |
| **Product & Stock** | Slow-Moving / Dead Stock (0 sales in 30 days), Fast-Moving Velocity, Reorder Threshold Alerts, Category Sales Contribution | CSV, PDF |
| **Ledger & Khata** | Customer Udhaar Aging (0-30, 31-60, 61-90+ days), Supplier Payables, High-Balance Risk Accounts | WhatsApp PDF, CSV |

---

For code implementations and unit tests, see [`packages/ezo_gst_tax_engine/test/ezo_gst_tax_engine_test.dart`](../../packages/ezo_gst_tax_engine/test/ezo_gst_tax_engine_test.dart).
