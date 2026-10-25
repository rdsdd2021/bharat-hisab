enum SubscriptionTier {
  freeTrial,
  oneYearStandard,
  threeYearPro,
  lifetimeEnterprise,
}

class MerchantLicenseKey {
  final String key;
  final String merchantId;
  final String storeName;
  final SubscriptionTier tier;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int maxAllowedStores;
  final int maxStaffSeats;
  final bool isDhandaAiEnabled;
  final bool isOnlineDukanEnabled;
  final String signatureHash;

  const MerchantLicenseKey({
    required this.key,
    required this.merchantId,
    required this.storeName,
    this.tier = SubscriptionTier.freeTrial,
    required this.issuedAt,
    this.expiresAt,
    this.maxAllowedStores = 1,
    this.maxStaffSeats = 2,
    this.isDhandaAiEnabled = true,
    this.isOnlineDukanEnabled = true,
    this.signatureHash = '',
  });

  bool get isValid {
    if (tier == SubscriptionTier.lifetimeEnterprise) {
      return true;
    }
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isBefore(expiresAt!);
  }

  int get daysRemaining {
    if (tier == SubscriptionTier.lifetimeEnterprise) {
      return 99999;
    }
    if (expiresAt == null) {
      return 0;
    }
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  MerchantLicenseKey copyWith({
    String? key,
    String? merchantId,
    String? storeName,
    SubscriptionTier? tier,
    DateTime? issuedAt,
    DateTime? expiresAt,
    int? maxAllowedStores,
    int? maxStaffSeats,
    bool? isDhandaAiEnabled,
    bool? isOnlineDukanEnabled,
    String? signatureHash,
  }) {
    return MerchantLicenseKey(
      key: key ?? this.key,
      merchantId: merchantId ?? this.merchantId,
      storeName: storeName ?? this.storeName,
      tier: tier ?? this.tier,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxAllowedStores: maxAllowedStores ?? this.maxAllowedStores,
      maxStaffSeats: maxStaffSeats ?? this.maxStaffSeats,
      isDhandaAiEnabled: isDhandaAiEnabled ?? this.isDhandaAiEnabled,
      isOnlineDukanEnabled: isOnlineDukanEnabled ?? this.isOnlineDukanEnabled,
      signatureHash: signatureHash ?? this.signatureHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'merchantId': merchantId,
      'storeName': storeName,
      'tier': tier.name,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'maxAllowedStores': maxAllowedStores,
      'maxStaffSeats': maxStaffSeats,
      'isDhandaAiEnabled': isDhandaAiEnabled,
      'isOnlineDukanEnabled': isOnlineDukanEnabled,
      'signatureHash': signatureHash,
    };
  }

  factory MerchantLicenseKey.fromJson(Map<String, dynamic> json) {
    return MerchantLicenseKey(
      key: json['key'] as String? ?? '',
      merchantId: json['merchantId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.freeTrial,
      ),
      issuedAt: json['issuedAt'] != null
          ? DateTime.parse(json['issuedAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      maxAllowedStores: (json['maxAllowedStores'] as num?)?.toInt() ?? 1,
      maxStaffSeats: (json['maxStaffSeats'] as num?)?.toInt() ?? 2,
      isDhandaAiEnabled: json['isDhandaAiEnabled'] as bool? ?? true,
      isOnlineDukanEnabled: json['isOnlineDukanEnabled'] as bool? ?? true,
      signatureHash: json['signatureHash'] as String? ?? '',
    );
  }
}
