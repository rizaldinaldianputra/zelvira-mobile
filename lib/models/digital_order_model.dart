class DigitalOrderRequest {
  final String skuCode;
  final String customerNo;
  final String? email;
  final String? refId;
  final double? amount;

  DigitalOrderRequest({
    required this.skuCode,
    required this.customerNo,
    this.email,
    this.refId,
    this.amount,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'skuCode': skuCode,
      'customerNo': customerNo,
    };
    if (email != null) map['email'] = email;
    if (refId != null) map['refId'] = refId;
    if (amount != null) map['amount'] = amount;
    return map;
  }
}

class DigitalOrderResponse {
  final int? id;
  final String orderNumber;
  final String? customerEmail;
  final String customerNo;
  final String skuCode;
  final String productName;
  final String? category;
  final String? brand;
  final double price;
  final String paymentStatus;
  final String? paymentToken;
  final String? paymentUrl;
  final String? digiflazzStatus;
  final String? digiflazzSn;
  final String? digiflazzMessage;

  DigitalOrderResponse({
    this.id,
    required this.orderNumber,
    this.customerEmail,
    required this.customerNo,
    required this.skuCode,
    required this.productName,
    this.category,
    this.brand,
    required this.price,
    required this.paymentStatus,
    this.paymentToken,
    this.paymentUrl,
    this.digiflazzStatus,
    this.digiflazzSn,
    this.digiflazzMessage,
  });

  factory DigitalOrderResponse.fromJson(Map<String, dynamic> json) {
    return DigitalOrderResponse(
      id: json['id'],
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? '',
      customerEmail: json['customerEmail'] ?? json['customer_email'],
      customerNo: json['customerNo'] ?? json['customer_no'] ?? '',
      skuCode: json['skuCode'] ?? json['sku_code'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      category: json['category'],
      brand: json['brand'],
      price: (json['price'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? json['payment_status'] ?? 'PENDING',
      paymentToken: json['paymentToken'] ?? json['payment_token'],
      paymentUrl: json['paymentUrl'] ?? json['payment_url'],
      digiflazzStatus: json['digiflazzStatus'] ?? json['digiflazz_status'],
      digiflazzSn: json['digiflazzSn'] ?? json['digiflazz_sn'],
      digiflazzMessage: json['digiflazzMessage'] ?? json['digiflazz_message'],
    );
  }
}

class DigiflazzTransactionResponse {
  final String refId;
  final String customerNo;
  final String buyerSkuCode;
  final String? customerName;
  final String message;
  final String status;
  final String rc;
  final String sn;
  final String buyerLastSaldo;
  final double price;
  final double? sellingPrice;
  final double? admin;
  final double? amount;
  final dynamic desc;
  final String tele;
  final String wa;

  DigiflazzTransactionResponse({
    required this.refId,
    required this.customerNo,
    required this.buyerSkuCode,
    this.customerName,
    required this.message,
    required this.status,
    required this.rc,
    required this.sn,
    required this.buyerLastSaldo,
    required this.price,
    this.sellingPrice,
    this.admin,
    this.amount,
    this.desc,
    required this.tele,
    required this.wa,
  });

  double get totalAmountToPay {
    if (sellingPrice != null && sellingPrice! > 0) return sellingPrice!;
    if (amount != null && amount! > 0) return amount!;
    if (price > 0) return price + (admin ?? 0.0);
    return admin ?? 0.0;
  }

  String? get formattedDesc {
    if (desc == null) return null;
    if (desc is String) return desc as String;
    if (desc is Map) {
      final map = desc as Map;
      final buffer = StringBuffer();
      if (map.containsKey('tarif')) buffer.writeln('Tarif: ${map['tarif']}');
      if (map.containsKey('daya')) buffer.writeln('Daya: ${map['daya']} VA');
      if (map.containsKey('lembar_tagihan')) {
        buffer.writeln('Jumlah Lembar: ${map['lembar_tagihan']}');
      }
      if (map.containsKey('detail') && map['detail'] is List) {
        final details = map['detail'] as List;
        for (var d in details) {
          if (d is Map) {
            if (d.containsKey('periode')) buffer.writeln('Periode: ${d['periode']}');
            if (d.containsKey('nilai_tagihan')) buffer.writeln('Tagihan: Rp ${d['nilai_tagihan']}');
            if (d.containsKey('admin')) buffer.writeln('Admin: Rp ${d['admin']}');
            if (d.containsKey('denda') && d['denda'] != '0' && d['denda'] != 0) {
              buffer.writeln('Denda: Rp ${d['denda']}');
            }
          }
        }
      }
      final result = buffer.toString().trim();
      return result.isNotEmpty ? result : null;
    }
    return desc.toString();
  }

  factory DigiflazzTransactionResponse.fromJson(Map<String, dynamic> json) {
    return DigiflazzTransactionResponse(
      refId: json['refId'] ?? json['ref_id'] ?? '',
      customerNo: json['customerNo'] ?? json['customer_no'] ?? '',
      buyerSkuCode: json['buyerSkuCode'] ?? json['buyer_sku_code'] ?? '',
      customerName: json['customerName'] ?? json['customer_name'],
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      rc: json['rc'] ?? '',
      sn: json['sn'] ?? '',
      buyerLastSaldo: (json['buyerLastSaldo'] ?? json['buyer_last_saldo'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] ?? json['selling_price'] as num?)?.toDouble(),
      admin: (json['admin'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      desc: json['desc'],
      tele: json['tele'] ?? '',
      wa: json['wa'] ?? '',
    );
  }
}

class DigiflazzResponse<T> {
  final T data;
  
  DigiflazzResponse({required this.data});
  
  factory DigiflazzResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return DigiflazzResponse(
      data: fromJsonT(json['data']),
    );
  }
}
