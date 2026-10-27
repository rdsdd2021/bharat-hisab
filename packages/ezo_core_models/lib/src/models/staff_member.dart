enum StaffRole {
  ownerAdmin,
  storeManager,
  fieldSalesperson,
  counterCashier,
}

class StaffMember {
  final String id;
  final String storeProfileId;
  final String fullName;
  final String phone;
  final String pinCode; // 4-6 digit quick login PIN
  final StaffRole role;
  final bool canEditPrices;
  final bool canGiveDiscounts;
  final bool canDeleteBills;
  final bool canViewProfitReports;
  final bool canCollectUdhaar;
  final bool isActive;
  final DateTime? createdAt;

  const StaffMember({
    required this.id,
    required this.storeProfileId,
    required this.fullName,
    required this.phone,
    required this.pinCode,
    this.role = StaffRole.counterCashier,
    this.canEditPrices = false,
    this.canGiveDiscounts = true,
    this.canDeleteBills = false,
    this.canViewProfitReports = false,
    this.canCollectUdhaar = true,
    this.isActive = true,
    this.createdAt,
  });

  /// Factory helper for creating owner with full permissions
  factory StaffMember.owner({
    required String id,
    required String storeProfileId,
    required String fullName,
    required String phone,
    required String pinCode,
  }) {
    return StaffMember(
      id: id,
      storeProfileId: storeProfileId,
      fullName: fullName,
      phone: phone,
      pinCode: pinCode,
      role: StaffRole.ownerAdmin,
      canEditPrices: true,
      canGiveDiscounts: true,
      canDeleteBills: true,
      canViewProfitReports: true,
      canCollectUdhaar: true,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  StaffMember copyWith({
    String? id,
    String? storeProfileId,
    String? fullName,
    String? phone,
    String? pinCode,
    StaffRole? role,
    bool? canEditPrices,
    bool? canGiveDiscounts,
    bool? canDeleteBills,
    bool? canViewProfitReports,
    bool? canCollectUdhaar,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      storeProfileId: storeProfileId ?? this.storeProfileId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      pinCode: pinCode ?? this.pinCode,
      role: role ?? this.role,
      canEditPrices: canEditPrices ?? this.canEditPrices,
      canGiveDiscounts: canGiveDiscounts ?? this.canGiveDiscounts,
      canDeleteBills: canDeleteBills ?? this.canDeleteBills,
      canViewProfitReports: canViewProfitReports ?? this.canViewProfitReports,
      canCollectUdhaar: canCollectUdhaar ?? this.canCollectUdhaar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeProfileId': storeProfileId,
      'fullName': fullName,
      'phone': phone,
      'pinCode': pinCode,
      'role': role.name,
      'canEditPrices': canEditPrices,
      'canGiveDiscounts': canGiveDiscounts,
      'canDeleteBills': canDeleteBills,
      'canViewProfitReports': canViewProfitReports,
      'canCollectUdhaar': canCollectUdhaar,
      'isActive': isActive,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String? ?? '',
      storeProfileId: json['storeProfileId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pinCode: json['pinCode'] as String? ?? '1234',
      role: StaffRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => StaffRole.counterCashier,
      ),
      canEditPrices: json['canEditPrices'] as bool? ?? false,
      canGiveDiscounts: json['canGiveDiscounts'] as bool? ?? true,
      canDeleteBills: json['canDeleteBills'] as bool? ?? false,
      canViewProfitReports: json['canViewProfitReports'] as bool? ?? false,
      canCollectUdhaar: json['canCollectUdhaar'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
