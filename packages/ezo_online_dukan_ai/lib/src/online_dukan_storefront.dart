import 'dart:convert';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';
import 'package:ezo_khata_upi_whatsapp/ezo_khata_upi_whatsapp.dart';

class OnlineDukanCartItem {
  final ProductItem product;
  final double quantity;

  const OnlineDukanCartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.sellingPrice * quantity;
}

class OnlineDukanOrder {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OnlineDukanCartItem> items;
  final String paymentMode; // 'cod', 'upi'
  final DateTime createdAt;

  const OnlineDukanOrder({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    this.paymentMode = 'cod',
    required this.createdAt,
  });

  double get totalPayable {
    double sum = 0.0;
    for (final i in items) {
      sum += i.lineTotal;
    }
    return sum;
  }

  /// Formats WhatsApp order message sent by customer to the merchant's WhatsApp
  String toWhatsAppOrderMessage(BusinessProfile store) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *NEW ONLINE DUKAN ORDER*');
    buffer.writeln('Order ID: #$orderId');
    buffer.writeln('Customer: $customerName');
    buffer.writeln('Phone: $customerPhone');
    buffer.writeln('Delivery Address: $deliveryAddress');
    buffer.writeln();
    buffer.writeln('📦 *Items Ordered:*');

    for (final item in items) {
      buffer.writeln(' • ${item.product.name} x ${item.quantity.toInt()} = ₹${item.lineTotal.toStringAsFixed(2)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('💰 *Total Payable: ₹${totalPayable.toStringAsFixed(2)}*');
    buffer.writeln('💳 *Payment Method:* ${paymentMode.toUpperCase()}');

    if (store.upiId.isNotEmpty) {
      final upiUri = UpiQrGenerator.buildUpiPaymentUri(
        merchantUpiId: store.upiId,
        merchantName: store.storeName,
        amount: totalPayable,
        note: 'Online Order #$orderId',
      );
      buffer.writeln();
      buffer.writeln('👉 *Instant UPI Payment Link:*');
      buffer.writeln(upiUri);
    }

    return buffer.toString();
  }

  /// Converts this incoming Online Dukan order directly into a POS InvoiceDocument in 1 click
  InvoiceDocument convertToPosInvoice(BusinessProfile storeProfile) {
    final lineItems = items.map((cartItem) {
      return EzoGstTaxEngine.buildLineItem(
        product: cartItem.product,
        quantity: cartItem.quantity,
        isGstInvoice: storeProfile.isGstRegistered,
        isInterStateSupply: false,
      );
    }).toList();

    return EzoGstTaxEngine.createInvoiceDocument(
      id: 'inv_dukan_$orderId',
      invoiceNumber: 'DUKAN-$orderId',
      invoiceDate: DateTime.now(),
      storeProfile: storeProfile,
      lineItems: lineItems,
      settlementMode: paymentMode == 'upi' ? SettlementMode.upiQr : SettlementMode.cash,
      amountReceived: paymentMode == 'upi' ? totalPayable : 0.0,
      notes: 'Online Dukan Order #$orderId. Delivery to: $deliveryAddress',
      customFields: InvoiceCustomFields(
        extraCustomPairs: {'Source': 'Online Dukan', 'CustomerPhone': customerPhone},
      ),
    );
  }
}

class OnlineDukanStorefrontManager {
  final EzoOfflineRepository repository;

  OnlineDukanStorefrontManager({required this.repository});

  /// Returns all products active on the merchant's 24x7 Online Dukan
  List<ProductItem> getDukanCatalog() {
    return repository
        .getAllProducts()
        .where((p) => p.showOnOnlineDukan && !p.isOutOfStock)
        .toList();
  }

  /// Generates full JSON payload for web/WhatsApp catalog sync
  String generateCatalogJson(BusinessProfile store) {
    final catalog = getDukanCatalog();
    final data = {
      'storeId': store.id,
      'storeName': store.storeName,
      'phone': store.phone,
      'address': store.address,
      'upiId': store.upiId,
      'totalProducts': catalog.length,
      'products': catalog.map((p) => {
        'id': p.id,
        'name': p.name,
        'category': p.category,
        'mrp': p.mrp,
        'sellingPrice': p.sellingPrice,
        'discountPercent': p.discountPercent.round(),
        'unit': p.unit.label,
        'imageUrl': p.imageUrl,
        'currentStock': p.currentStock,
      }).toList(),
    };
    return jsonEncode(data);
  }
}
