import 'package:ezo_core_models/ezo_core_models.dart';

class UpsellRecommender {
  /// Inspects cart items and recommends complementary high-margin or linked cross-sell items
  static List<ProductItem> getUpsellSuggestions({
    required List<InvoiceLineItem> cartLines,
    required List<ProductItem> catalog,
    int maxSuggestions = 4,
  }) {
    if (cartLines.isEmpty || catalog.isEmpty) return const [];

    final cartProductIds = cartLines.map((l) => l.productId).toSet();
    final Map<String, ProductItem> catalogMap = {for (var p in catalog) p.id: p};
    final Set<String> candidateIds = {};

    // 1. First priority: Direct upsellProductIds specified on items in cart
    for (final line in cartLines) {
      final prod = catalogMap[line.productId];
      if (prod != null) {
        for (final upId in prod.upsellProductIds) {
          if (!cartProductIds.contains(upId) && catalogMap.containsKey(upId)) {
            candidateIds.add(upId);
          }
        }
      }
    }

    // 2. Second priority: Complementary high-velocity items in same or matching category
    if (candidateIds.length < maxSuggestions) {
      final cartCategories = cartLines.map((l) {
        return catalogMap[l.productId]?.category ?? '';
      }).where((c) => c.isNotEmpty).toSet();

      final sameCatCandidates = catalog.where((p) {
        return !cartProductIds.contains(p.id) &&
            !candidateIds.contains(p.id) &&
            !p.isOutOfStock &&
            cartCategories.contains(p.category);
      }).toList()
        ..sort((a, b) => b.totalUnitsSold.compareTo(a.totalUnitsSold));

      for (final p in sameCatCandidates) {
        candidateIds.add(p.id);
        if (candidateIds.length >= maxSuggestions) break;
      }
    }

    // 3. Fallback: Top-selling items overall
    if (candidateIds.length < maxSuggestions) {
      final topSellers = catalog.where((p) {
        return !cartProductIds.contains(p.id) &&
            !candidateIds.contains(p.id) &&
            !p.isOutOfStock;
      }).toList()
        ..sort((a, b) => b.totalUnitsSold.compareTo(a.totalUnitsSold));

      for (final p in topSellers) {
        candidateIds.add(p.id);
        if (candidateIds.length >= maxSuggestions) break;
      }
    }

    return candidateIds
        .map((id) => catalogMap[id])
        .whereType<ProductItem>()
        .take(maxSuggestions)
        .toList();
  }
}
