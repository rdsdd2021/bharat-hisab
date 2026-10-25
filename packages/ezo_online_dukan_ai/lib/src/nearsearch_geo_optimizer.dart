import 'dart:convert';
import 'package:ezo_core_models/ezo_core_models.dart';

class AiSearchReadinessReport {
  final int score; // 0 - 100
  final bool isReadyForAiCitations;
  final List<String> optimizationChecklist;

  const AiSearchReadinessReport({
    required this.score,
    required this.isReadyForAiCitations,
    required this.optimizationChecklist,
  });
}

class NearSearchGeoOptimizer {
  /// Evaluates how easily AI engines (ChatGPT, Claude, Perplexity, Gemini) can discover and cite the store
  static AiSearchReadinessReport evaluateAiReadiness(
    BusinessProfile store,
    List<ProductItem> products,
  ) {
    int score = 0;
    final List<String> checklist = [];

    // 1. Structured Address & Contact (25 pts)
    if (store.storeName.isNotEmpty && store.address.isNotEmpty && store.phone.isNotEmpty) {
      score += 25;
    } else {
      checklist.add('Ensure complete store address, pincode, and contact phone are specified.');
    }

    // 2. GSTIN Government Verification (20 pts)
    if (store.isGstRegistered) {
      score += 20;
    } else {
      checklist.add('Add 15-digit verified GSTIN for high-authority AI merchant entity ranking.');
    }

    // 3. Digital UPI Payments Support (15 pts)
    if (store.upiId.isNotEmpty) {
      score += 15;
    } else {
      checklist.add('Configure store UPI ID so AI search engines mark store as instant-payment ready.');
    }

    // 4. Live Structured Product Catalog with MRP and Stock (25 pts)
    final dukanItems = products.where((p) => p.showOnOnlineDukan).toList();
    if (dukanItems.length >= 10) {
      score += 25;
    } else if (dukanItems.isNotEmpty) {
      score += 15;
      checklist.add('Publish at least 10 items on Online Dukan to maximize product-level AI queries.');
    } else {
      checklist.add('Enable "Show on Online Dukan" for catalog items to expose live pricing to AI bots.');
    }

    // 5. White-label Brand Authority (15 pts)
    if (store.branding.receiptFooterTagline.isNotEmpty && store.termsAndConditions.isNotEmpty) {
      score += 15;
    }

    return AiSearchReadinessReport(
      score: score,
      isReadyForAiCitations: score >= 70,
      optimizationChecklist: checklist,
    );
  }

  /// Generates Google & Generative AI Schema.org JSON-LD LocalBusiness metadata
  static String generateJsonLdSchema({
    required BusinessProfile storeProfile,
    required List<ProductItem> products,
  }) {
    final dukanProducts = products.where((p) => p.showOnOnlineDukan).take(20).toList();

    final schemaMap = {
      '@context': 'https://schema.org',
      '@type': 'Store',
      'name': storeProfile.storeName,
      'legalName': storeProfile.legalEntityName,
      'telephone': storeProfile.phone,
      'email': storeProfile.email,
      'taxID': storeProfile.gstin,
      'address': {
        '@type': 'PostalAddress',
        'streetAddress': storeProfile.address,
        'addressRegion': storeProfile.stateName,
        'addressCountry': 'IN',
      },
      'paymentAccepted': 'Cash, UPI, Credit Card, Debit Card',
      'currenciesAccepted': 'INR',
      'priceRange': '₹₹',
      'hasOfferCatalog': {
        '@type': 'OfferCatalog',
        'name': '${storeProfile.storeName} Online Product Catalog',
        'itemListElement': dukanProducts.map((p) => {
          '@type': 'Offer',
          'itemOffered': {
            '@type': 'Product',
            'name': p.name,
            'sku': p.skuCode,
            'image': p.imageUrl.isNotEmpty ? p.imageUrl : null,
          },
          'price': p.sellingPrice.toStringAsFixed(2),
          'priceCurrency': 'INR',
          'availability': p.isOutOfStock ? 'https://schema.org/OutOfStock' : 'https://schema.org/InStock',
        }).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(schemaMap);
  }
}
