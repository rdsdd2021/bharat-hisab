# Monorepo Packages API Reference

This document provides a comprehensive API guide and copy-paste code snippets for all 7 domain packages located in [`packages/`](../../packages).

---

## 1. `packages/ezo_core_models`

The foundational domain model library with offline-first storage and sync outbox queue.

### Key Classes & Constructors

#### `ProductItem`
```dart
import 'package:ezo_core_models/ezo_core_models.dart';

final product = ProductItem(
  id: 'prod-001',
  name: 'Tata Salt 1kg',
  regionalName: 'टाटा नमक',
  skuCode: 'TS-1000',
  barcode: '8901030000012',
  hsnSacCode: '25010010',
  category: 'Spices & Staples',
  unit: 'KG',
  mrp: 28.0,
  sellingPrice: 25.0,
  wholesalePrice: 22.0,
  purchasePrice: 20.0,
  gstPercent: 5.0,
  isTaxInclusive: true,
  currentStock: 120.0,
  lowStockThreshold: 15.0,
  showOnOnlineDukan: true,
);

// Computed Getters
print('Margin: Rs. ${product.sellingPrice - product.purchasePrice}');
print('Customer Discount: Rs. ${product.discountOnMrp} (${product.discountPercent}%)');
print('Low stock? ${product.isLowStock}');
```

#### `OfflineRepository`
```dart
final repo = OfflineRepository();
await repo.initialize();

// Save product (Atomically writes and queues SyncQueueEntry)
await repo.saveProduct(product);

// Query catalog
final lowStockItems = repo.getLowStockProducts();
final activeParty = repo.getPartyById('cust-005');
```

---

## 2. `packages/ezo_gst_tax_engine`

High-speed tax calculations, intra/inter-state split, round-off, and GSTR report aggregation.

### Key Usage Snippet

```dart
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';

// 1. Build an individual line item
final lineItem = EzoGstTaxEngine.buildLineItem(
  product: product,
  quantity: 3.0,
  lineDiscountAmount: 0.0,
  isGstInvoice: true,
  isInterStateSupply: false, // Intra-state (CGST + SGST)
);

// 2. Assemble complete InvoiceDocument
final invoice = EzoGstTaxEngine.createInvoiceDocument(
  store: storeProfile,
  party: customerParty,
  docType: InvoiceDocType.gstTaxInvoice,
  settlementMode: SettlementMode.upiQr,
  lineItems: [lineItem],
  billLevelDiscount: 5.0,
  amountReceived: 70.0,
  cashier: currentCashierStaff,
  invoiceDate: DateTime.now(),
);

print('Grand Total: Rs. ${invoice.grandTotal}');
print('CGST: Rs. ${invoice.totalCgst}, SGST: Rs. ${invoice.totalSgst}');
print('Round Off: Rs. ${invoice.roundOffAdjustment}');
print('You Saved: Rs. ${invoice.totalCustomerSavings}');
```

---

## 3. `packages/ezo_thermal_printer_escpos`

Raw byte generators for 58mm and 80mm ESC/POS thermal printers, KOT kitchen slips, and A4/A5 PDF invoices.

### Key Usage Snippet

```dart
import 'package:ezo_thermal_printer_escpos/ezo_thermal_printer_escpos.dart';

// 1. Generate 58mm (Chota) or 80mm (Bada) Thermal Byte Stream
final List<int> escPosBytes = EzoEscPosEngine.generateReceiptBytes(
  invoice: invoice,
  store: storeProfile,
  format: PrintFormat.bada80mm,
  includeUpiQr: true,
  upiId: 'merchant@okaxis',
);

// Send directly over Bluetooth SPP or USB socket
await bluetoothSocket.sink.add(escPosBytes);

// 2. Generate Kitchen Order Ticket (KOT)
final List<int> kotBytes = EzoEscPosEngine.generateKotBytes(
  invoice: invoice,
  tableNumber: 'Table 12',
  serverName: 'Rohan',
);

// 3. Generate A4 Full-Page PDF
final pdfBytes = await EzoPdfEngine.generateA4ModernPdf(
  invoice: invoice,
  store: storeProfile,
);
```

---

## 4. `packages/ezo_inventory_barcode`

Stock deduction engine, velocity categorization, bulk-import CSV parser, and barcode label printer.

### Key Usage Snippet

```dart
import 'package:ezo_inventory_barcode/ezo_inventory_barcode.dart';

// 1. Deduct stock upon invoice settlement
final updatedProducts = InventoryEngine.deductStockForInvoice(
  invoice: invoice,
  catalog: currentCatalog,
);

// 2. Classify inventory velocity
final velocity = InventoryEngine.evaluateVelocity(
  product: product,
  past30DaysSalesCount: 145,
); // FastMoving, Moderate, SlowMoving, DeadStock

// 3. Generate printable 38mm x 25mm barcode stickers
final stickerPdfBytes = await BarcodeStickerEngine.generateStickers(
  products: [product],
  storeName: 'APNA BAZAAR',
  copiesPerProduct: 50,
);

// 4. In-Cart Upsell Recommendation
final upsellItems = UpsellEngine.recommendInCartUpsells(
  cartProducts: [teaLeavesProduct],
  catalog: currentCatalog,
); // Recommends Sugar, Milk Powder, Biscuits
```

---

## 5. `packages/ezo_khata_upi_whatsapp`

Customer/Supplier Udhaar credit bahi, NPCI dynamic UPI string generator, and WhatsApp reminder deep-links.

### Key Usage Snippet

```dart
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';

// 1. Generate Dynamic NPCI UPI QR URI
final upiUri = EzoUpiEngine.buildDynamicUpiUri(
  payeeUpiId: 'store@upi',
  payeeName: 'Sharma General Store',
  amount: 450.00,
  referenceInvoice: 'INV-1092',
  transactionNote: 'Udhaar Clearance INV1092',
);
// Output: upi://pay?pa=store@upi&pn=Sharma+General+Store&am=450.00&tr=INV-1092&tn=Udhaar+Clearance+INV1092&cu=INR

// 2. Generate 1-Click WhatsApp Payment Reminder Link
final whatsappLink = EzoWhatsAppEngine.generateReminderMessage(
  customerName: 'Rahul Verma',
  customerPhone: '+919876543210',
  dueBalance: 850.00,
  storeName: 'Sharma General Store',
  upiPaymentLink: upiUri,
  languageCode: 'hi', // Hindi vernacular message
);
```

---

## 6. `packages/ezo_online_dukan_ai`

WhatsApp storefront builder, Dhanda AI Google Business Profile auditor, and NearSearch local SEO JSON-LD builder.

### Key Usage Snippet

```dart
import 'package:ezo_online_dukan_ai/ezo_online_dukan_ai.dart';

// 1. Audit Google Business Profile Health
final auditReport = DhandaAiEngine.auditGoogleProfile(
  storeProfile: storeProfile,
  reviewCount: 42,
  averageRating: 4.1,
  hasPhotosUpdatedRecently: true,
  hasWorkingHoursListed: true,
);
print('Dhanda AI Score: ${auditReport.overallScore}/100');

// 2. Generate AI reply for customer review
final reply = DhandaAiEngine.generateReviewReply(
  customerReview: 'Great fresh vegetables and quick billing on WhatsApp!',
  starRating: 5,
  storeName: storeProfile.storeName,
);

// 3. Build Google NearSearch Local SEO Schema
final schemaJson = NearSearchEngine.buildJsonLdSchema(
  store: storeProfile,
  catalog: currentCatalog,
);
```

---

## 7. `packages/ezo_l10n_vernacular`

Zero-overhead localization engine supporting 10 Indian regional languages.

### Key Usage Snippet

```dart
import 'package:ezo_l10n_vernacular/ezo_l10n_vernacular.dart';

// Translate string with dynamic variable interpolation
final greeting = EzoL10n.translate(
  'grand_total_label',
  locale: 'hi', // Hindi
); // Output: 'कुल राशि'

final billSaved = EzoL10n.translate(
  'you_saved_banner',
  locale: 'bn', // Bengali
  params: {'amount': '₹45.00'},
); // Output: 'আপনি বাঁচিয়েছেন ₹45.00'
```

---

For complete test suites and behavioral assertions, review [`packages/ezo_e2e_tests/test`](../../packages/ezo_e2e_tests/test).
