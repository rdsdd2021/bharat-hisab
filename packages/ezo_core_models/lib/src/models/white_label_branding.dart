class WhiteLabelBranding {
  final String brandAppName;
  final String resellerCompanyName;
  final String supportWhatsApp;
  final String primaryColorHex;
  final String accentColorHex;
  final String receiptFooterTagline;

  const WhiteLabelBranding({
    this.brandAppName = 'EZO Billing',
    this.resellerCompanyName = 'EZO Technologies Pvt Ltd',
    this.supportWhatsApp = '919876543210',
    this.primaryColorHex = '#1E88E5',
    this.accentColorHex = '#FF6F00',
    this.receiptFooterTagline = 'Thank you for shopping! Powered by EZO POS',
  });

  WhiteLabelBranding copyWith({
    String? brandAppName,
    String? resellerCompanyName,
    String? supportWhatsApp,
    String? primaryColorHex,
    String? accentColorHex,
    String? receiptFooterTagline,
  }) {
    return WhiteLabelBranding(
      brandAppName: brandAppName ?? this.brandAppName,
      resellerCompanyName: resellerCompanyName ?? this.resellerCompanyName,
      supportWhatsApp: supportWhatsApp ?? this.supportWhatsApp,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      receiptFooterTagline: receiptFooterTagline ?? this.receiptFooterTagline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandAppName': brandAppName,
      'resellerCompanyName': resellerCompanyName,
      'supportWhatsApp': supportWhatsApp,
      'primaryColorHex': primaryColorHex,
      'accentColorHex': accentColorHex,
      'receiptFooterTagline': receiptFooterTagline,
    };
  }

  factory WhiteLabelBranding.fromJson(Map<String, dynamic> json) {
    return WhiteLabelBranding(
      brandAppName: json['brandAppName'] as String? ?? 'EZO Billing',
      resellerCompanyName: json['resellerCompanyName'] as String? ?? 'EZO Technologies',
      supportWhatsApp: json['supportWhatsApp'] as String? ?? '',
      primaryColorHex: json['primaryColorHex'] as String? ?? '#1E88E5',
      accentColorHex: json['accentColorHex'] as String? ?? '#FF6F00',
      receiptFooterTagline: json['receiptFooterTagline'] as String? ?? 'Thank you for visiting!',
    );
  }
}
