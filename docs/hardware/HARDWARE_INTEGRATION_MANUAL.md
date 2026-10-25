# POS Hardware Integration Manual

This manual provides low-level specifications, protocol references, and integration guides for connecting POS peripherals (Thermal Printers, Barcode Scanners, Electronic Weighing Scales, and Cash Drawers) using [`packages/ezo_thermal_printer_escpos`](../../packages/ezo_thermal_printer_escpos).

---

## 1. Supported Thermal Printer Formats

EZO POS decouples invoice data from rendering, supporting both embedded mobile thermal printers and desktop laser printers:

| Profile Identifier | Physical Paper Width | Printable Width | Line Pitch / Density | Characters Per Line (Font A / B) | Typical Hardware Device |
|---|---|---|---|---|---|
| `58mm_chota` | 58 mm (2.28 in) | 48 mm (384 dots) | 203 DPI (8 dots/mm) | **32 chars** (Font A: 12×24)<br/>**42 chars** (Font B: 9×17) | Sunmi V2, Bluetooth Pocket Printer, Chota Billing Machine |
| `80mm_bada` | 80 mm (3.15 in) | 72 mm (576 dots) | 203 DPI (8 dots/mm) | **46–48 chars** (Font A: 12×24)<br/>**64 chars** (Font B: 9×17) | Epson TM-T82, TVS RP-3200, Bada Desktop Billing Machine |
| `a4_modern` | 210 × 297 mm | Standard Margin | 300+ DPI Vector | Full Page Grid | Office Inkjet/Laser (Modern Card UI) |
| `a4_tally` | 210 × 297 mm | Compact Margin | 300+ DPI Vector | Traditional Accounting Grid | Tally-Style Bordered Tax Invoice |
| `a5` | 148 × 210 mm | Half Page | 300+ DPI Vector | Compact Landscape Grid | Wholesale & Medical Pharma Distributors |

---

## 2. Low-Level ESC/POS Protocol Specifications

The `EzoEscPosEngine` produces raw byte streams compliant with standard **Epson ESC/POS** command sets:

### 2.1 Essential Command Byte Sequences

```dart
// 1. Hardware Initialization (Clears buffer, resets line spacing)
final List<int> cmdInit = [0x1B, 0x40]; // ESC @

// 2. Text Alignment
final List<int> cmdAlignLeft   = [0x1B, 0x61, 0x00]; // ESC a 0
final List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
final List<int> cmdAlignRight  = [0x1B, 0x61, 0x02]; // ESC a 2

// 3. Typography Modifiers
final List<int> cmdBoldOn      = [0x1B, 0x45, 0x01]; // ESC E 1
final List<int> cmdBoldOff     = [0x1B, 0x45, 0x00]; // ESC E 0
final List<int> cmdDoubleSize  = [0x1D, 0x21, 0x11]; // GS ! 17 (Double width & height)
final List<int> cmdNormalSize  = [0x1D, 0x21, 0x00]; // GS ! 0

// 4. Cash Drawer Kick Pulse (Pin 2 / 24V)
final List<int> cmdKickDrawer  = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // ESC p 0 25 250

// 5. Paper Feed & Partial Guillotine Cut
final List<int> cmdFeedAndCut  = [0x1B, 0x64, 0x03, 0x1D, 0x56, 0x41, 0x00]; // ESC d 3, GS V A 0
```

---

## 3. Dynamic NPCI UPI QR Code Generation on Thermal Receipts

Rather than forcing the merchant to display a static laminated QR standee with unknown amounts, EZO generates a **dynamic, transaction-specific NPCI UPI QR code** at the bottom of every bill.

### 3.1 NPCI Specification Compliant URI

```
upi://pay?pa=merchant@okaxis&pn=SuperMart&am=1248.00&tr=INV-2026-0042&tn=Bill+INV0042&cu=INR
```

- `pa`: Merchant Virtual Payment Address (VPA).
- `pn`: Legal Payee Name.
- `am`: Exact Rounded Bill Total (Paise formatted to 2 decimals).
- `tr`: Unique Invoice Reference for auto-reconciliation.
- `tn`: Transaction note printed on customer's Google Pay / PhonePe passbook.

### 3.2 ESC/POS Native 2D QR Code Commands

```dart
// GS ( k: Model 2 QR Code Setup & Print
List<int> buildNativeQrCommands(String upiUri) {
  final List<int> bytes = [];
  final uriBytes = utf8.encode(upiUri);
  final int len = uriBytes.length + 3;
  final int pL = len % 256;
  final int pH = len ~/ 256;

  // Set QR Model 2
  bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
  // Set Module Size (Dot size = 6 for 80mm, 4 for 58mm)
  bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x05]);
  // Set Error Correction Level M (15%)
  bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
  // Store Data in Symbol Storage Area
  bytes.addAll([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
  bytes.addAll(uriBytes);
  // Print QR Symbol
  bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
  return bytes;
}
```

---

## 4. Restaurant Kitchen Order Ticket (KOT) Specifications

In restaurants and cafes, the POS dispatches a **Kitchen Order Ticket (KOT)** directly to the kitchen thermal printer immediately upon order booking, before billing settlement.

### 4.1 Sample KOT Print Layout (58mm / 32 Chars)

```text
================================
     ** KITCHEN ORDER TICKET **
================================
KOT #: KOT-084    TYPE: DINE-IN
TABLE: Table 04   SERVER: Amit
DATE: 26-Oct-2026 13:45
--------------------------------
QTY  ITEM                  NOTES
--------------------------------
 2   Paneer Butter Masala  Medium Spicy
 4   Butter Naan           Crisp
 1   Jeera Rice
 2   Fresh Lime Soda       Sweet
--------------------------------
TOTAL ITEMS: 9
================================
```

---

## 5. Electronic Weighing Scale Integration (RS-232 / USB Serial)

Kirana stores and supermarkets weigh loose items (Potatoes, Rice, Dry Fruits, Sweets). EZO connects to weighing scales via USB-to-UART or Serial RS-232 adapters.

### 5.1 Communication Protocols
- **Baud Rate**: Typically `9600 bps`, Data Bits: `8`, Parity: `None`, Stop Bits: `1`.
- **Transmission Modes**:
  1. **Continuous Stream**: The scale continuously outputs `ST,GS,+001.250kg\r\n`.
  2. **Polled Mode**: The POS sends `W\r\n` (Weight enquiry) and awaits response.

### 5.2 Real-Time Weight Parsing Logic

```dart
double parseScaleReading(String rawBuffer) {
  // Regex extracting signed floating point before 'kg' or 'g'
  final regex = RegExp(r'([+\-]?\d+\.?\d*)\s*(kg|g)', caseSensitive: false);
  final match = regex.firstMatch(rawBuffer);
  if (match != null) {
    double value = double.tryParse(match.group(1) ?? '0.0') ?? 0.0;
    if (match.group(2)?.toLowerCase() == 'g') {
      value /= 1000.0; // Normalize grams to kg
    }
    return value;
  }
  return 0.0;
}
```

---

## 6. Barcode Scanner Configuration

EZO POS supports all standard **1D Laser / CCD** and **2D Image QR/DataMatrix** barcode scanners.

### 6.1 Recommended Scanner Configuration
- **Interface**: USB HID (Keyboard Wedge mode) or Bluetooth HID.
- **Suffix Character**: Set the scanner's hardware configuration to append **Enter (`\r\n` or ASCII 13)** after each decode.
- **Auto-Billing Mode**: In the EZO billing screen, incoming barcode events with an Enter suffix immediately increment cart quantity or add the matching SKU in `< 5ms`.

---

For printer testing scripts and drivers, see [`packages/ezo_thermal_printer_escpos`](../../packages/ezo_thermal_printer_escpos).
