import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/business_profile.dart';
import '../models/staff_member.dart';
import '../models/merchant_license_key.dart';
import '../models/product_item.dart';
import '../models/party_account.dart';
import '../models/invoice_document.dart';
import '../models/khata_ledger_entry.dart';
import '../models/sync_queue_entry.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? token;
  final BusinessProfile? profile;
  final StaffMember? staff;
  final List<StaffMember> initialStaffList;
  final MerchantLicenseKey? license;
  final List<ProductItem> initialProducts;
  final List<PartyAccount> initialParties;
  final List<InvoiceDocument> initialInvoices;
  final List<KhataLedgerEntry> initialKhataEntries;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.token,
    this.profile,
    this.staff,
    this.initialStaffList = const [],
    this.license,
    this.initialProducts = const [],
    this.initialParties = const [],
    this.initialInvoices = const [],
    this.initialKhataEntries = const [],
  });
}

class BackendApiService {
  static String defaultBaseUrl = 'http://localhost:5000';
  static const String localLanUrl = 'http://192.168.31.33:5000';
  static const String emulatorUrl = 'http://10.0.2.2:5000';

  static void configureForDevice({bool isEmulator = false, bool isPhysicalPhone = false, String? customUrl}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      defaultBaseUrl = customUrl;
    } else if (isPhysicalPhone) {
      defaultBaseUrl = localLanUrl;
    } else if (isEmulator) {
      defaultBaseUrl = emulatorUrl;
    } else {
      defaultBaseUrl = 'http://localhost:5000';
    }
  }

  final String baseUrl;
  final http.Client _client;

  BackendApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  /// Register a new store owner in the central cloud backend
  Future<AuthResult> register({
    required String phone,
    required String pin,
    required String storeName,
    String? ownerName,
    String? vertical,
    String? stateCode,
    String? stateName,
    bool isGstEnabled = true,
  }) async {
    try {
      final response = await _client.post(
        _uri('/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone.trim(),
          'pin': pin.trim(),
          'storeName': storeName.trim(),
          'ownerName': ownerName?.trim() ?? 'Store Owner',
          'vertical': vertical ?? 'kiranaGrocery',
          'stateCode': stateCode ?? '27',
          'stateName': stateName ?? 'Maharashtra',
          'isGstEnabled': isGstEnabled,
        }),
      ).timeout(const Duration(milliseconds: 1500));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final profile = BusinessProfile.fromJson(data['profile'] as Map<String, dynamic>);
        final staff = StaffMember.fromJson(data['staff'] as Map<String, dynamic>);
        final license = data['license'] != null
            ? MerchantLicenseKey.fromJson(data['license'] as Map<String, dynamic>)
            : null;

        return AuthResult(
          success: true,
          token: data['token'] as String?,
          profile: profile,
          staff: staff,
          license: license,
        );
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'Registration failed (${response.statusCode}).',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error connecting to cloud server: $e',
      );
    }
  }

  /// Log in with phone number and PIN
  Future<AuthResult> login({
    required String phone,
    required String pin,
  }) async {
    try {
      final response = await _client.post(
        _uri('/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone.trim(),
          'pin': pin.trim(),
        }),
      ).timeout(const Duration(milliseconds: 1500));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final profile = BusinessProfile.fromJson(data['profile'] as Map<String, dynamic>);
        final staff = StaffMember.fromJson(data['staff'] as Map<String, dynamic>);
        final license = data['license'] != null
            ? MerchantLicenseKey.fromJson(data['license'] as Map<String, dynamic>)
            : null;

        final products = (data['products'] as List<dynamic>? ?? [])
            .map((p) => ProductItem.fromJson(p as Map<String, dynamic>))
            .toList();

        final parties = (data['parties'] as List<dynamic>? ?? [])
            .map((p) => PartyAccount.fromJson(p as Map<String, dynamic>))
            .toList();

        final invoices = (data['invoices'] as List<dynamic>? ?? [])
            .map((i) => InvoiceDocument.fromJson(i as Map<String, dynamic>))
            .toList();

        final khataEntries = (data['khataEntries'] as List<dynamic>? ?? [])
            .map((k) => KhataLedgerEntry.fromJson(k as Map<String, dynamic>))
            .toList();

        final allStaff = (data['allStaff'] as List<dynamic>? ?? [])
            .map((s) => StaffMember.fromJson(s as Map<String, dynamic>))
            .toList();

        return AuthResult(
          success: true,
          token: data['token'] as String?,
          profile: profile,
          staff: staff,
          initialStaffList: allStaff,
          license: license,
          initialProducts: products,
          initialParties: parties,
          initialInvoices: invoices,
          initialKhataEntries: khataEntries,
        );
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'Invalid phone number or PIN.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Network error connecting to cloud server: $e',
      );
    }
  }

  /// Push local outbox mutations to the cloud
  Future<bool> pushMutations({
    required String merchantId,
    required List<SyncQueueEntry> mutations,
  }) async {
    if (mutations.isEmpty) return true;
    try {
      final payload = mutations.map((m) {
        return {
          'id': m.id,
          'entityType': m.entityType,
          'operation': m.operation.name,
          'payload': jsonDecode(m.payloadJson),
          'clientTimestamp': m.createdAt.toIso8601String(),
        };
      }).toList();

      final response = await _client.post(
        _uri('/api/v1/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'merchantId': merchantId,
          'mutations': payload,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Pull latest updates for a merchant from the cloud
  Future<Map<String, dynamic>?> pullUpdates({required String merchantId}) async {
    try {
      final response = await _client.get(
        _uri('/api/v1/sync/pull', {'merchantId': merchantId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch live merchant fleet telemetry for Superadmin portal
  Future<Map<String, dynamic>?> getAdminMerchants({String masterToken = '889900'}) async {
    try {
      final response = await _client.get(
        _uri('/api/v1/admin/merchants'),
        headers: {'Authorization': 'Bearer $masterToken'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Issue a new commercial license key via Superadmin portal
  Future<MerchantLicenseKey?> issueLicense({
    required String masterToken,
    required String tier,
    required int maxAllowedStores,
    required int maxStaffSeats,
    required bool isDhandaAiEnabled,
    required bool isOnlineDukanEnabled,
    String? storeName,
    String? merchantId,
  }) async {
    try {
      final response = await _client.post(
        _uri('/api/v1/admin/license/issue'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $masterToken',
        },
        body: jsonEncode({
          'tier': tier,
          'maxAllowedStores': maxAllowedStores,
          'maxStaffSeats': maxStaffSeats,
          'isDhandaAiEnabled': isDhandaAiEnabled,
          'isOnlineDukanEnabled': isOnlineDukanEnabled,
          'storeName': storeName,
          'merchantId': merchantId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MerchantLicenseKey.fromJson(data['license'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
