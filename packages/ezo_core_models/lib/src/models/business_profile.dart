import 'white_label_branding.dart';

enum PrintFormat {
  chota58mm,
  bada80mm,
  a4Modern,
  a4Tally,
  a5,
}

enum RegionalLanguage {
  en,
  hi,
  bn,
  mr,
  gu,
  te,
  ta,
  kn,
  ml,
  pa,
}

class BusinessProfile {
  final String id;
  final String storeName;
  final String legalEntityName;
  final String gstin;
  final String stateCode;
  final String stateName;
  final String address;
  final String phone;
  final String email;
  final String upiId;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String logoPath;
  final String signaturePath;
  final String termsAndConditions;
  final bool isGstEnabled;
  final PrintFormat defaultPrintFormat;
  final RegionalLanguage activeLanguageCode;
  final WhiteLabelBranding branding;

  const BusinessProfile({
    required this.id,
    required this.storeName,
    required this.legalEntityName,
    required this.gstin,
    required this.stateCode,
    required this.stateName,
    required this.address,
    required this.phone,
    required this.email,
    required this.upiId,
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.logoPath = '',
    this.signaturePath = '',
    this.termsAndConditions = 'Goods once sold will not be taken back or exchanged.',
    this.isGstEnabled = true,
    this.defaultPrintFormat = PrintFormat.chota58mm,
    this.activeLanguageCode = RegionalLanguage.en,
    this.branding = const WhiteLabelBranding(),
  });

  bool get isGstRegistered => isGstEnabled && gstin.trim().length == 15;

  BusinessProfile copyWith({
    String? id,
    String? storeName,
    String? legalEntityName,
    String? gstin,
    String? stateCode,
    String? stateName,
    String? address,
    String? phone,
    String? email,
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? logoPath,
    String? signaturePath,
    String? termsAndConditions,
    bool? isGstEnabled,
    PrintFormat? defaultPrintFormat,
    RegionalLanguage? activeLanguageCode,
    WhiteLabelBranding? branding,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      gstin: gstin ?? this.gstin,
      stateCode: stateCode ?? this.stateCode,
      stateName: stateName ?? this.stateName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      logoPath: logoPath ?? this.logoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      isGstEnabled: isGstEnabled ?? this.isGstEnabled,
      defaultPrintFormat: defaultPrintFormat ?? this.defaultPrintFormat,
      activeLanguageCode: activeLanguageCode ?? this.activeLanguageCode,
      branding: branding ?? this.branding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeName': storeName,
      'legalEntityName': legalEntityName,
      'gstin': gstin,
      'stateCode': stateCode,
      'stateName': stateName,
      'address': address,
      'phone': phone,
      'email': email,
      'upiId': upiId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'logoPath': logoPath,
      'signaturePath': signaturePath,
      'termsAndConditions': termsAndConditions,
      'isGstEnabled': isGstEnabled,
      'defaultPrintFormat': defaultPrintFormat.name,
      'activeLanguageCode': activeLanguageCode.name,
      'branding': branding.toJson(),
    };
  }

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      legalEntityName: json['legalEntityName'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      stateCode: json['stateCode'] as String? ?? '27',
      stateName: json['stateName'] as String? ?? 'Maharashtra',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      upiId: json['upiId'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      logoPath: json['logoPath'] as String? ?? '',
      signaturePath: json['signaturePath'] as String? ?? '',
      termsAndConditions: json['termsAndConditions'] as String? ?? '',
      isGstEnabled: json['isGstEnabled'] as bool? ?? true,
      defaultPrintFormat: PrintFormat.values.firstWhere(
        (e) => e.name == json['defaultPrintFormat'],
        orElse: () => PrintFormat.chota58mm,
      ),
      activeLanguageCode: RegionalLanguage.values.firstWhere(
        (e) => e.name == json['activeLanguageCode'],
        orElse: () => RegionalLanguage.en,
      ),
      branding: json['branding'] != null
          ? WhiteLabelBranding.fromJson(json['branding'] as Map<String, dynamic>)
          : const WhiteLabelBranding(),
    );
  }
}
