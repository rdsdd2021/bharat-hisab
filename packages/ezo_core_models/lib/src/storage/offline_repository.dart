import '../models/business_profile.dart';
import '../models/product_item.dart';
import '../models/invoice_document.dart';
import '../models/party_account.dart';
import '../models/khata_ledger_entry.dart';
import '../models/staff_member.dart';
import '../models/merchant_license_key.dart';
import '../models/sync_queue_entry.dart';
import '../services/backend_api_service.dart';
import 'local_database.dart';

class EzoOfflineRepository {
  final LocalDatabase db;
  final BackendApiService apiService;

  EzoOfflineRepository({
    required this.db,
    BackendApiService? apiService,
  }) : apiService = apiService ?? BackendApiService();

  // --- Profile Operations ---
  Future<void> saveProfile(BusinessProfile profile) => db.saveBusinessProfile(profile);
  BusinessProfile? getProfile(String id) => db.getBusinessProfile(id);
  List<BusinessProfile> getAllProfiles() => db.getAllBusinessProfiles();

  // --- Product Operations & Stock ---
  Future<void> upsertProduct(ProductItem product) => db.saveProduct(product);
  Future<void> bulkUpsertProducts(List<ProductItem> products) => db.saveProductsBatch(products);
  ProductItem? getProduct(String id) => db.getProduct(id);
  ProductItem? findProductByBarcode(String barcode) => db.findProductByBarcode(barcode);
  List<ProductItem> getAllProducts() => db.getAllProducts();
  Future<void> deleteProduct(String id) => db.deleteProduct(id);

  List<ProductItem> getLowStockProducts() {
    return db.getAllProducts().where((p) => p.isLowStock).toList();
  }

  List<ProductItem> getOutOfStockProducts() {
    return db.getAllProducts().where((p) => p.isOutOfStock).toList();
  }

  List<ProductItem> getFastMovingProducts({int limit = 10}) {
    final list = db.getAllProducts().toList()
      ..sort((a, b) => b.totalUnitsSold.compareTo(a.totalUnitsSold));
    return list.take(limit).toList();
  }

  // --- Invoice & Stock Deductions ---
  Future<void> commitSalesInvoice(InvoiceDocument invoice) async {
    await db.saveInvoice(invoice);

    // Atomically decrement inventory for billed items
    for (final line in invoice.lineItems) {
      final existing = db.getProduct(line.productId);
      if (existing != null) {
        final updatedStock = existing.currentStock - line.quantity;
        final updatedUnitsSold = existing.totalUnitsSold + line.quantity;
        final updated = existing.copyWith(
          currentStock: updatedStock,
          totalUnitsSold: updatedUnitsSold,
        );
        await db.saveProduct(updated);
      }
    }

    // If Udhaar / credit balance exists, record entry in party Khata
    if (invoice.balanceUdhaarDue > 0 && invoice.partyId.isNotEmpty) {
      final khataEntry = KhataLedgerEntry(
        id: 'khata_${invoice.id}',
        partyId: invoice.partyId,
        entryDate: invoice.invoiceDate,
        debitYouGave: invoice.balanceUdhaarDue,
        creditYouGot: 0.0,
        paymentMode: 'invoice_credit',
        collectedByStaffId: invoice.cashierStaffId,
        collectedByStaffName: invoice.cashierStaffName,
        referenceInvoiceNumber: invoice.invoiceNumber,
        notes: 'Udhaar balance from Bill #${invoice.invoiceNumber}',
        createdAt: DateTime.now(),
      );
      await db.addKhataEntry(khataEntry);
    }
  }

  Future<void> cancelInvoice(String invoiceId) async {
    final invoice = db.getInvoice(invoiceId);
    if (invoice == null || invoice.isCancelled) return;

    final updated = invoice.copyWith(isCancelled: true);
    await db.saveInvoice(updated);

    // Restore stock
    for (final line in invoice.lineItems) {
      final existing = db.getProduct(line.productId);
      if (existing != null) {
        final restoredStock = existing.currentStock + line.quantity;
        final restoredSold = existing.totalUnitsSold - line.quantity;
        await db.saveProduct(
          existing.copyWith(
            currentStock: restoredStock,
            totalUnitsSold: restoredSold < 0 ? 0 : restoredSold,
          ),
        );
      }
    }
  }

  InvoiceDocument? getInvoice(String id) => db.getInvoice(id);
  List<InvoiceDocument> getAllInvoices() => db.getAllInvoices();

  // --- Party & Khata Operations ---
  Future<void> saveParty(PartyAccount party) => db.saveParty(party);
  PartyAccount? getParty(String id) => db.getParty(id);
  List<PartyAccount> getAllParties() => db.getAllParties();
  List<PartyAccount> getCustomerParties() =>
      db.getAllParties().where((p) => p.partyType == PartyType.customer).toList();
  List<PartyAccount> getSupplierParties() =>
      db.getAllParties().where((p) => p.partyType == PartyType.supplier).toList();
  Future<void> deleteParty(String id) => db.deleteParty(id);

  Future<void> recordPartyPayment({
    required String partyId,
    required double amount,
    required String paymentMode,
    required String collectedByStaffId,
    required String collectedByStaffName,
    String reference = '',
    String notes = '',
  }) async {
    final party = db.getParty(partyId);
    if (party == null) return;

    final isCustomer = party.partyType == PartyType.customer;
    final entry = KhataLedgerEntry(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      partyId: partyId,
      entryDate: DateTime.now(),
      debitYouGave: isCustomer ? 0.0 : amount, // Customer paid -> credit received; Supplier paid -> debit given
      creditYouGot: isCustomer ? amount : 0.0,
      paymentMode: paymentMode,
      collectedByStaffId: collectedByStaffId,
      collectedByStaffName: collectedByStaffName,
      referenceInvoiceNumber: reference,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await db.addKhataEntry(entry);
  }

  // --- Staff Operations ---
  Future<void> saveStaff(StaffMember staff) => db.saveStaffMember(staff);
  StaffMember? getStaff(String id) => db.getStaffMember(id);
  List<StaffMember> getAllStaff() => db.getAllStaffMembers();
  Future<void> deleteStaff(String id) => db.deleteStaffMember(id);

  // --- License Key Operations ---
  Future<void> activateLicense(MerchantLicenseKey key) => db.saveLicense(key);
  MerchantLicenseKey? getActiveLicense() => db.getActiveLicense();

  // --- Sync Queue ---
  List<SyncQueueEntry> getPendingSync() => db.getPendingSyncEntries();
  Future<void> markSynced(String id) => db.markSyncSuccess(id);
  Future<void> markSyncFailed(String id, String err) => db.markSyncFailed(id, err);

  // --- Reset / Switch Operations ---
  Future<void> clearAll() => db.clearAll();
  Future<void> clearProductsAndParties() => db.clearProductsAndParties();

  // --- Cloud Sync & Backend Integrations ---
  Future<AuthResult> registerCloud({
    required String phone,
    required String pin,
    required String storeName,
    String? ownerName,
    String? vertical,
    String? stateCode,
    String? stateName,
    bool isGstEnabled = true,
  }) async {
    final result = await apiService.register(
      phone: phone,
      pin: pin,
      storeName: storeName,
      ownerName: ownerName,
      vertical: vertical,
      stateCode: stateCode,
      stateName: stateName,
      isGstEnabled: isGstEnabled,
    );

    if (result.success && result.profile != null && result.staff != null) {
      await db.saveBusinessProfile(result.profile!);
      await db.saveStaffMember(result.staff!);
      if (result.license != null) {
        await db.saveLicense(result.license!);
      }
    }
    return result;
  }

  Future<AuthResult> loginCloud({
    required String phone,
    required String pin,
  }) async {
    final result = await apiService.login(phone: phone, pin: pin);
    if (result.success && result.profile != null && result.staff != null) {
      await db.saveBusinessProfile(result.profile!);
      await db.saveStaffMember(result.staff!);
      if (result.license != null) {
        await db.saveLicense(result.license!);
      }
      if (result.initialProducts.isNotEmpty) {
        await db.saveProductsBatch(result.initialProducts);
      }
      for (final party in result.initialParties) {
        await db.saveParty(party);
      }
      for (final invoice in result.initialInvoices) {
        await db.saveInvoice(invoice);
      }
      for (final entry in result.initialKhataEntries) {
        await db.addKhataEntry(entry);
      }
    }
    return result;
  }

  Future<bool> syncWithCloud(String merchantId) async {
    try {
      final pending = db.getPendingSyncEntries();
      if (pending.isNotEmpty) {
        final pushed = await apiService.pushMutations(
          merchantId: merchantId,
          mutations: pending,
        );
        if (pushed) {
          for (final entry in pending) {
            await db.markSyncSuccess(entry.id);
          }
        }
      }

      // Pull updates
      final updates = await apiService.pullUpdates(merchantId: merchantId);
      if (updates != null && updates['success'] == true) {
        final products = (updates['products'] as List<dynamic>? ?? [])
            .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
            .toList();
        if (products.isNotEmpty) {
          await db.saveProductsBatch(products);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Explicitly flushes all in-memory repository mutations to physical disk storage
  Future<void> flushToDisk() => db.flushToDisk();
}
