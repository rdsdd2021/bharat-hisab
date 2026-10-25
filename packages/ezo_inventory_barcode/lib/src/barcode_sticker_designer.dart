import 'package:ezo_core_models/ezo_core_models.dart';

class BarcodeStickerDesigner {
  /// Generates a valid 13-digit EAN-13 barcode with standard modulo-10 check digit
  static String generateUniqueEan13({
    String countryPrefix = '890', // India GS1 prefix
    required String storeCode, // 4 digits
    required int itemSequence, // 5 digits
  }) {
    final raw12 = '$countryPrefix${storeCode.padLeft(4, '0')}${itemSequence.toString().padLeft(5, '0')}';
    final truncated12 = raw12.substring(0, 12);

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(truncated12[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    final remainder = sum % 10;
    final checkDigit = (remainder == 0) ? 0 : 10 - remainder;

    return '$truncated12$checkDigit';
  }

  /// Generates standalone SVG graphic for the discount barcode sticker
  static String renderStickerSvg({
    required ProductItem product,
    required String storeName,
    double widthMm = 50,
    double heightMm = 30,
  }) {
    final barcodeValue = product.barcode.isNotEmpty ? product.barcode : product.skuCode;
    final discountPercent = product.discountPercent.round();
    final hasDiscount = discountPercent > 0;

    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120" width="${widthMm}mm" height="${heightMm}mm" style="font-family:Arial,sans-serif; background:#fff; border:1px dashed #ccc;">
  <!-- Store Name Header -->
  <text x="100" y="16" font-size="11" font-weight="bold" text-anchor="middle" fill="#111">$storeName</text>
  
  <!-- Product Name -->
  <text x="100" y="30" font-size="10" text-anchor="middle" fill="#333">${product.name.length > 20 ? product.name.substring(0, 20) : product.name}</text>
  
  <!-- Barcode Visual Bars -->
  <g transform="translate(25, 38)">
    <rect x="0" y="0" width="150" height="34" fill="#fff" />
    <rect x="10" y="0" width="2" height="34" fill="#000" />
    <rect x="14" y="0" width="4" height="34" fill="#000" />
    <rect x="22" y="0" width="2" height="34" fill="#000" />
    <rect x="28" y="0" width="6" height="34" fill="#000" />
    <rect x="38" y="0" width="2" height="34" fill="#000" />
    <rect x="44" y="0" width="4" height="34" fill="#000" />
    <rect x="52" y="0" width="2" height="34" fill="#000" />
    <rect x="60" y="0" width="6" height="34" fill="#000" />
    <rect x="70" y="0" width="4" height="34" fill="#000" />
    <rect x="78" y="0" width="2" height="34" fill="#000" />
    <rect x="84" y="0" width="4" height="34" fill="#000" />
    <rect x="94" y="0" width="2" height="34" fill="#000" />
    <rect x="100" y="0" width="6" height="34" fill="#000" />
    <rect x="110" y="0" width="2" height="34" fill="#000" />
    <rect x="116" y="0" width="4" height="34" fill="#000" />
    <rect x="126" y="0" width="2" height="34" fill="#000" />
    <rect x="132" y="0" width="4" height="34" fill="#000" />
  </g>
  
  <!-- Barcode Value Text -->
  <text x="100" y="82" font-size="9" text-anchor="middle" letter-spacing="2" fill="#222">$barcodeValue</text>
  
  <!-- Pricing & Promotional Discount Badge -->
  ${hasDiscount ? '''
  <rect x="10" y="90" width="180" height="22" rx="3" fill="#fff3e0" stroke="#ff9800" stroke-width="1" />
  <text x="18" y="104" font-size="8" fill="#777" text-decoration="line-through">MRP ₹${product.mrp.toInt()}</text>
  <text x="75" y="105" font-size="11" font-weight="bold" fill="#d32f2f">Offer ₹${product.sellingPrice.toInt()}</text>
  <rect x="140" y="93" width="46" height="15" rx="2" fill="#2e7d32" />
  <text x="163" y="104" font-size="8" font-weight="bold" text-anchor="middle" fill="#fff">SAVE $discountPercent%</text>
  ''' : '''
  <text x="100" y="105" font-size="12" font-weight="bold" text-anchor="middle" fill="#111">PRICE: ₹${product.sellingPrice.toStringAsFixed(2)}</text>
  '''}
</svg>
''';
  }

  /// Generates a printable A4 3x8 sticker sheet (24 labels per page)
  static String renderA4StickerSheetHtml({
    required List<ProductItem> products,
    required String storeName,
    int repeatPerItem = 1,
  }) {
    final buffer = StringBuffer();
    for (final p in products) {
      for (int i = 0; i < repeatPerItem; i++) {
        buffer.write('<div class="sticker-cell">${renderStickerSvg(product: p, storeName: storeName)}</div>');
      }
    }

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>A4 Barcode Sticker Sheet (3x8)</title>
<style>
  @page { size: A4 portrait; margin: 10mm; }
  body { margin: 0; padding: 0; }
  .grid-container {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-gap: 5mm;
  }
  .sticker-cell {
    display: flex;
    justify-content: center;
    align-items: center;
  }
</style>
</head>
<body>
<div class="grid-container">
  $buffer
</div>
</body>
</html>
''';
  }
}
