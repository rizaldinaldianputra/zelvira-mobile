import 'voucher_model.dart';

class UserVoucherModel {
  final int id;
  final VoucherModel voucher;
  final int usageCount;

  UserVoucherModel({
    required this.id,
    required this.voucher,
    required this.usageCount,
  });

  factory UserVoucherModel.fromJson(Map<String, dynamic> json) {
    return UserVoucherModel(
      id: json['id'] ?? 0,
      voucher: VoucherModel.fromJson(json['voucher'] ?? {}),
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voucher': voucher.toJson(),
      'usageCount': usageCount,
    };
  }
}
