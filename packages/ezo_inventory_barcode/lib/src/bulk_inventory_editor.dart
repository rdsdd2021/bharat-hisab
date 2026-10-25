import 'package:ezo_core_models/ezo_core_models.dart';

class BulkEditDraftRow {
  final String productId;
  final String name;
  final String skuCode;
  final String category;
  double mrp;
  double sellingPrice;
  double wholesalePrice;
  double purchasePrice;
  double gstPercent;
  double lowStockThreshold;
  double currentStock;
  bool isModified;

  BulkEditDraftRow({
    required this.productId,
    required this.name,
    required this.skuCode,
    required this.category,
    required this.mrp,
    required this.sellingPrice,
    required this.wholesalePrice,
    required this.purchasePrice,
    required this.gstPercent,
    required this.lowStockThreshold,
    required this.currentStock,
    this.isModified = false,
  });

  factory BulkEditDraftRow.fromProduct(ProductItem item) {
    return BulkEditDraftRow(
      productId: item.id,
      name: item.name,
      skuCode: item.skuCode,
      category: item.category,
      mrp: item.mrp,
      sellingPrice: item.sellingPrice,
      wholesalePrice: item.wholesalePrice,
      purchasePrice: item.purchasePrice,
      gstPercent: item.gstPercent,
      lowStockThreshold: item.lowStockThreshold,
      currentStock: item.currentStock,
    );
  }

  ProductItem applyToProduct(ProductItem original) {
    return original.copyWith(
      mrp: mrp,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      purchasePrice: purchasePrice,
      gstPercent: gstPercent,
      lowStockThreshold: lowStockThreshold,
      currentStock: currentStock,
    );
  }
}

class BulkInventoryEditor {
  final List<BulkEditDraftRow> _drafts = [];

  List<BulkEditDraftRow> get drafts => List.unmodifiable(_drafts);

  void loadProducts(List<ProductItem> products) {
    _drafts.clear();
    for (final p in products) {
      _drafts.add(BulkEditDraftRow.fromProduct(p));
    }
  }

  void updateField(
    String productId, {
    double? mrp,
    double? sellingPrice,
    double? wholesalePrice,
    double? purchasePrice,
    double? gstPercent,
    double? lowStockThreshold,
    double? currentStock,
  }) {
    final row = _drafts.firstWhere((d) => d.productId == productId);
    if (mrp != null) {
      row.mrp = mrp;
      row.isModified = true;
    }
    if (sellingPrice != null) {
      row.sellingPrice = sellingPrice;
      row.isModified = true;
    }
    if (wholesalePrice != null) {
      row.wholesalePrice = wholesalePrice;
      row.isModified = true;
    }
    if (purchasePrice != null) {
      row.purchasePrice = purchasePrice;
      row.isModified = true;
    }
    if (gstPercent != null) {
      row.gstPercent = gstPercent;
      row.isModified = true;
    }
    if (lowStockThreshold != null) {
      row.lowStockThreshold = lowStockThreshold;
      row.isModified = true;
    }
    if (currentStock != null) {
      row.currentStock = currentStock;
      row.isModified = true;
    }
  }

  /// Bulk markup tool: Increases Selling Price by X% across all or filtered SKUs
  void applyMarkupPercentage({
    required double percentage,
    String? categoryFilter,
    bool updateMrpAlso = false,
  }) {
    for (final draft in _drafts) {
      if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
        if (draft.category.toLowerCase() != categoryFilter.toLowerCase()) continue;
      }

      final factor = 1.0 + (percentage / 100.0);
      final newSelling = (draft.sellingPrice * factor * 100).round() / 100.0;
      draft.sellingPrice = newSelling;

      if (updateMrpAlso) {
        draft.mrp = (draft.mrp * factor * 100).round() / 100.0;
      }
      draft.isModified = true;
    }
  }

  /// Commits all modified drafts to the offline repository in a single batch
  Future<int> commitBulkEdit(EzoOfflineRepository repository) async {
    final modified = _drafts.where((d) => d.isModified).toList();
    if (modified.isEmpty) return 0;

    final List<ProductItem> toSave = [];
    for (final draft in modified) {
      final orig = repository.getProduct(draft.productId);
      if (orig != null) {
        toSave.add(draft.applyToProduct(orig));
      }
    }

    await repository.bulkUpsertProducts(toSave);

    // Reset modification flags
    for (final draft in modified) {
      draft.isModified = false;
    }

    return toSave.length;
  }
}
