import 'package:test/test.dart';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_online_dukan_ai/ezo_online_dukan_ai.dart';

void main() {
  const store = BusinessProfile(
    id: 'store_mumbai',
    storeName: 'Bombay Supermart',
    legalEntityName: 'Bombay Retail Pvt Ltd',
    gstin: '27AABCU9876E1Z5',
    stateCode: '27',
    stateName: 'Maharashtra',
    address: 'Andheri West, Mumbai',
    phone: '9820098200',
    email: 'contact@bombaysuper.com',
    upiId: 'bombaysuper@hdfcbank',
    bankName: 'HDFC Bank',
    accountNumber: '5010022334455',
    ifscCode: 'HDFC0000001',
  );

  const product1 = ProductItem(
    id: 'p_atta',
    name: 'Aashirvaad Atta 10kg',
    skuCode: 'ATTA-10',
    mrp: 450.0,
    sellingPrice: 410.0,
    showOnOnlineDukan: true,
  );

  const product2 = ProductItem(
    id: 'p_oil',
    name: 'Fortune Sunflower Oil 5L',
    skuCode: 'OIL-5L',
    mrp: 750.0,
    sellingPrice: 680.0,
    showOnOnlineDukan: true,
  );

  group('Online Dukan Storefront & Orders', () {
    test('Builds WhatsApp order message and converts directly to POS Invoice', () {
      final order = OnlineDukanOrder(
        orderId: 'OD-7788',
        customerName: 'Priya Sharma',
        customerPhone: '9988776655',
        deliveryAddress: 'Flat 402, Green Valley, Andheri',
        items: const [
          OnlineDukanCartItem(product: product1, quantity: 2),
          OnlineDukanCartItem(product: product2, quantity: 1),
        ],
        paymentMode: 'upi',
        createdAt: DateTime.now(),
      );

      // Total = 410*2 + 680 = 1500
      expect(order.totalPayable, equals(1500.0));

      final waMessage = order.toWhatsAppOrderMessage(store);
      expect(waMessage.contains('*NEW ONLINE DUKAN ORDER*'), isTrue);
      expect(waMessage.contains('Priya Sharma'), isTrue);
      expect(waMessage.contains('₹1500.00'), isTrue);
      expect(waMessage.contains('upi://pay?pa=bombaysuper@hdfcbank'), isTrue);

      final invoice = order.convertToPosInvoice(store);
      expect(invoice.grandTotal, equals(1500.0));
      expect(invoice.lineItems.length, equals(2));
      expect(invoice.settlementMode, equals(SettlementMode.upiQr));
      expect(invoice.amountReceived, equals(1500.0));
    });
  });

  group('Dhanda AI Marketing Suite', () {
    test('Audits GBP profile and computes 0-100 score and Map Pack rank', () {
      final audit = DhandaAiMarketingSuite.auditGoogleBusinessProfile(
        storeProfile: store,
        totalGoogleReviews: 120,
        averageStarRating: 4.8,
        monthlyPostsCount: 6,
        uploadedPhotosCount: 35,
        isGstinVerified: true,
      );

      expect(audit.overallScore, greaterThanOrEqualTo(80));
      expect(audit.estimatedRank, equals(LocalPackRankEstimate.top3MapPack));
      expect(audit.prioritizedActionPlan.isNotEmpty, isTrue);
    });

    test('Generates keyword-optimized review responses', () {
      final positiveReply = DhandaAiMarketingSuite.generateReviewReply(
        customerName: 'Kunal',
        starRating: 5,
        reviewText: 'Great selection of groceries!',
        storeName: 'Bombay Supermart',
        storeCategory: 'Supermarket',
      );
      expect(positiveReply.contains('5-star rating'), isTrue);
      expect(positiveReply.contains('Bombay Supermart'), isTrue);

      final negativeReply = DhandaAiMarketingSuite.generateReviewReply(
        customerName: 'Raj',
        starRating: 2,
        reviewText: 'Long queue at billing counter',
        storeName: 'Bombay Supermart',
        storeCategory: 'Supermarket',
      );
      expect(negativeReply.contains('deeply apologize'), isTrue);
    });
  });

  group('NearSearch Generative Engine Optimization', () {
    test('Evaluates AI Readiness and generates JSON-LD LocalBusiness Schema', () {
      final report = NearSearchGeoOptimizer.evaluateAiReadiness(store, [product1, product2]);
      expect(report.score, greaterThanOrEqualTo(70));
      expect(report.isReadyForAiCitations, isTrue);

      final jsonLd = NearSearchGeoOptimizer.generateJsonLdSchema(
        storeProfile: store,
        products: [product1, product2],
      );

      expect(jsonLd.contains('"@type": "Store"'), isTrue);
      expect(jsonLd.contains('Bombay Supermart'), isTrue);
      expect(jsonLd.contains('Aashirvaad Atta 10kg'), isTrue);
      expect(jsonLd.contains('410.00'), isTrue);
    });
  });
}
