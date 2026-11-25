class VoucherModel {
  final int id;
  final String code;
  final double discountAmount;
  final double minPurchase;
  final String discountType;
  final double? maxDiscount;
  final String? validUntil;
  final bool isActive;
  final String targetMembership;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.minPurchase,
    this.discountType = 'FIXED',
    this.maxDiscount,
    this.validUntil,
    required this.isActive,
    required this.targetMembership,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      minPurchase: (json['minPurchase'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] ?? 'FIXED',
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      validUntil: json['validUntil'],
      isActive: json['isActive'] ?? false,
      targetMembership: json['targetMembership'] ?? 'ALL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountAmount': discountAmount,
      'minPurchase': minPurchase,
      'discountType': discountType,
      'maxDiscount': maxDiscount,
      'validUntil': validUntil,
      'isActive': isActive,
      'targetMembership': targetMembership,
    };
  }
}
