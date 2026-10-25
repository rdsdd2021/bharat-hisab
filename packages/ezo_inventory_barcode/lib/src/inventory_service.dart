import 'package:ezo_core_models/ezo_core_models.dart';

enum StockHealthFilter {
  all,
  lowStock,
  outOfStock,
  fastMoving,
  deadStock,
}

class EzoInventoryService {
  final EzoOfflineRepository repository;

  EzoInventoryService({required this.repository});

  /// Atomically deducts inventory stock when a sales invoice is created
  Future<void> deductStockForSales(InvoiceDocument invoice) async {
    for (final line in invoice.lineItems) {
      final existing = repository.getProduct(line.productId);
      if (existing != null) {
        final updatedStock = existing.currentStock - line.quantity;
        final updatedSold = existing.totalUnitsSold + line.quantity;
        await repository.upsertProduct(
          existing.copyWith(
            currentStock: updatedStock,
            totalUnitsSold: updatedSold,
          ),
        );
      }
    }
  }

  /// Restores inventory stock when a bill is cancelled or a sales return is processed
  Future<void> restoreStockForReturn(InvoiceDocument returnInvoice) async {
    for (final line in returnInvoice.lineItems) {
      final existing = repository.getProduct(line.productId);
      if (existing != null) {
        final restoredStock = existing.currentStock + line.quantity;
        final restoredSold = (existing.totalUnitsSold - line.quantity).clamp(0.0, double.infinity);
        await repository.upsertProduct(
          existing.copyWith(
            currentStock: restoredStock,
            totalUnitsSold: restoredSold,
          ),
        );
      }
    }
  }

  /// Increments stock when a purchase invoice is entered
  Future<void> incrementStockForPurchase(InvoiceDocument purchaseInvoice) async {
    for (final line in purchaseInvoice.lineItems) {
      final existing = repository.getProduct(line.productId);
      if (existing != null) {
        final updatedStock = existing.currentStock + line.quantity;
        await repository.upsertProduct(
          existing.copyWith(
            currentStock: updatedStock,
            purchasePrice: line.unitSellingPrice > 0 ? line.unitSellingPrice : existing.purchasePrice,
          ),
        );
      }
    }
  }

  /// Filters products based on real-time stock velocity & health status
  List<ProductItem> getFilteredProducts({
    StockHealthFilter filter = StockHealthFilter.all,
    String category = '',
    String searchQuery = '',
  }) {
    var products = repository.getAllProducts();

    if (category.isNotEmpty && category != 'All') {
      products = products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      products = products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.skuCode.toLowerCase().contains(query) ||
            p.barcode.toLowerCase().contains(query) ||
            p.regionalName.toLowerCase().contains(query);
      }).toList();
    }

    switch (filter) {
      case StockHealthFilter.all:
        return products;
      case StockHealthFilter.lowStock:
        return products.where((p) => p.isLowStock).toList();
      case StockHealthFilter.outOfStock:
        return products.where((p) => p.isOutOfStock).toList();
      case StockHealthFilter.fastMoving:
        final sorted = products.toList()
          ..sort((a, b) => b.totalUnitsSold.compareTo(a.totalUnitsSold));
        return sorted.where((p) => p.totalUnitsSold > 0).take(20).toList();
      case StockHealthFilter.deadStock:
        return products.where((p) => p.totalUnitsSold == 0 && p.currentStock > 0).toList();
    }
  }

  /// Calculates stock velocity score (units sold per 30 days)
  double calculateStockVelocityScore(ProductItem product, int trackedDays) {
    if (trackedDays <= 0) return 0.0;
    return (product.totalUnitsSold / trackedDays) * 30.0;
  }
}
