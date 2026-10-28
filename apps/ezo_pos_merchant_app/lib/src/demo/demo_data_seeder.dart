import 'package:ezo_core_models/ezo_core_models.dart';
import 'package:ezo_gst_tax_engine/ezo_gst_tax_engine.dart';

class DemoDataSeeder {
  static Future<void> seedDemoStore(EzoOfflineRepository repo) async {
    await seedVerticalStore(
      repo: repo,
      vertical: IndustryVertical.kiranaGrocery,
      storeName: 'Bharat Mega Mart & Cafe',
      gstin: '27AABCE1234F1Z5',
      phone: '9876543210',
      stateCode: '27',
      stateName: 'Maharashtra',
      printFormat: PrintFormat.chota58mm,
      language: RegionalLanguage.en,
    );
  }

  static Future<void> seedVerticalStore({
    required EzoOfflineRepository repo,
    required IndustryVertical vertical,
    String? storeName,
    String? gstin,
    String? phone,
    String? stateCode,
    String? stateName,
    PrintFormat? printFormat,
    RegionalLanguage? language,
  }) async {
    final verticals = IndustryVerticalInfo.getAllVerticals();
    final info = verticals.firstWhere(
      (v) => v.vertical == vertical,
      orElse: () => verticals.first,
    );

    // Clean existing catalog and parties for fresh vertical seeding
    await repo.clearProductsAndParties();

    final activeStoreName = (storeName != null && storeName.trim().isNotEmpty)
        ? storeName.trim()
        : (vertical == IndustryVertical.restaurantCafe
            ? 'The Spice Bistro & Cafe'
            : (vertical == IndustryVertical.pharmacyHealth
                ? 'Sanjivani Medicos & Wellness'
                : (vertical == IndustryVertical.garmentsApparel
                    ? 'FabStyle Boutique & Garments'
                    : (vertical == IndustryVertical.electronicsMobiles
                        ? 'TechZone Mobiles & Electronics'
                        : info.title))));

    final activeGstin = (gstin != null && gstin.trim().isNotEmpty)
        ? gstin.trim()
        : '27AABCE1234F1Z5';

    final activePhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim()
        : '9876543210';

    final activeStateCode = stateCode ?? '27';
    final activeStateName = stateName ?? 'Maharashtra';
    final activeFormat = printFormat ?? info.recommendedPrintFormat;
    final activeLang = language ?? RegionalLanguage.en;

    final profile = BusinessProfile(
      id: 'active_store',
      storeName: activeStoreName,
      legalEntityName: '$activeStoreName Pvt Ltd',
      gstin: activeGstin,
      stateCode: activeStateCode,
      stateName: activeStateName,
      address: 'Shop 12-14, Commercial Hub, Pune - 411038',
      phone: activePhone,
      email: 'pune.store@bharathisab.com',
      upiId: 'bharatmart@icici',
      bankName: 'ICICI Bank Ltd',
      accountNumber: '002105012345',
      ifscCode: 'ICIC0000021',
      termsAndConditions: vertical == IndustryVertical.restaurantCafe
          ? '1. Food once prepared cannot be cancelled.\n2. Please alert server to dietary restrictions.\n3. GST 5% charged as per Restaurant Service guidelines.'
          : '1. Goods once sold will not be exchanged without invoice.\n2. Warranty handled by manufacturer.',
      isGstEnabled: activeGstin.trim().length == 15,
      defaultPrintFormat: activeFormat,
      activeLanguageCode: activeLang,
      industryVertical: vertical,
      branding: WhiteLabelBranding(
        brandAppName: 'Bharat Hisab',
        resellerCompanyName: 'Bharat Hisab Technologies',
        supportWhatsApp: '91$activePhone',
        primaryColorHex: vertical == IndustryVertical.restaurantCafe
            ? '#EA580C'
            : (vertical == IndustryVertical.pharmacyHealth
                ? '#059669'
                : (vertical == IndustryVertical.garmentsApparel
                    ? '#7C3AED'
                    : (vertical == IndustryVertical.electronicsMobiles ? '#0284C7' : '#1E88E5'))),
        accentColorHex: '#FF6F00',
        receiptFooterTagline: vertical == IndustryVertical.restaurantCafe
            ? 'Thank you for dining with us! Visit again soon!'
            : 'Thank you for shopping with us! Have a great day!',
      ),
    );
    await repo.saveProfile(profile);

    // Save default staff if not present
    if (repo.getAllStaff().isEmpty) {
      final admin = StaffMember.owner(
        id: 'staff_owner',
        storeProfileId: profile.id,
        fullName: 'Vikram Joshi (Owner)',
        phone: activePhone,
        pinCode: '1111',
      );
      final cashier = StaffMember(
        id: 'staff_cashier',
        storeProfileId: profile.id,
        fullName: 'Sunil Verma (Cashier)',
        phone: '9822114455',
        pinCode: '1234',
        role: StaffRole.counterCashier,
        canEditPrices: false,
        canDeleteBills: false,
        canViewProfitReports: false,
        canCollectUdhaar: true,
        createdAt: DateTime.now(),
      );
      await repo.saveStaff(admin);
      await repo.saveStaff(cashier);
    }

    // Activate 3-year Pro license if not active
    if (repo.getActiveLicense() == null) {
      final license = MerchantLicenseKey(
        key: 'BH-PRO-2026-9999',
        merchantId: profile.id,
        storeName: profile.storeName,
        tier: SubscriptionTier.threeYearPro,
        issuedAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2029, 1, 1),
        maxAllowedStores: 3,
        maxStaffSeats: 5,
        isDhandaAiEnabled: true,
        isOnlineDukanEnabled: true,
      );
      await repo.activateLicense(license);
    }

    // Seed vertical-tailored products
    await repo.bulkUpsertProducts(info.sampleCatalog);

    // Seed vertical-tailored parties
    for (final party in info.sampleParties) {
      await repo.saveParty(party);
    }

    // Seed an initial demo invoice so reports and dashboards have real data
    if (info.sampleCatalog.isNotEmpty) {
      final firstProd = info.sampleCatalog.first;
      final line = EzoGstTaxEngine.buildLineItem(
        product: firstProd,
        quantity: 1.0,
        isGstInvoice: profile.isGstRegistered,
        isInterStateSupply: false,
      );
      final invoice = EzoGstTaxEngine.createInvoiceDocument(
        id: 'inv_init_01',
        invoiceNumber: 'BH-5001',
        invoiceDate: DateTime.now(),
        storeProfile: profile,
        cashier: repo.getAllStaff().first,
        party: info.sampleParties.isNotEmpty ? info.sampleParties.first : null,
        lineItems: [line],
        docType: vertical == IndustryVertical.restaurantCafe
            ? InvoiceDocType.kitchenOrderTicketKot
            : InvoiceDocType.gstTaxInvoice,
        settlementMode: SettlementMode.cash,
        amountReceived: line.totalAmount,
      );
      await repo.commitSalesInvoice(invoice);
    }
  }
}
