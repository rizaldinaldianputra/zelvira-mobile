class DigitalProduct {
  final int id;
  final String sku;
  final String productName;
  final String category;
  final String brand;
  final String type;
  final String sellerName;
  final double price;
  final double sellingPrice;
  final String buyerSkuCode;
  final bool buyerProductStatus;
  final bool sellerProductStatus;
  final bool unlimitedStock;
  final int stock;
  final bool multi;
  final bool faultTolerant;
  final bool cutOff;
  final String? desc;
  final bool isActive;
  final bool isPostpaid;
  final double? admin;
  final double? commission;
  final String? startCutOff;
  final String? endCutOff;

  DigitalProduct({
    required this.id,
    required this.sku,
    required this.productName,
    required this.category,
    required this.brand,
    required this.type,
    required this.sellerName,
    required this.price,
    required this.sellingPrice,
    required this.buyerSkuCode,
    required this.buyerProductStatus,
    required this.sellerProductStatus,
    required this.unlimitedStock,
    required this.stock,
    required this.multi,
    required this.faultTolerant,
    required this.cutOff,
    this.desc,
    required this.isActive,
    required this.isPostpaid,
    this.admin,
    this.commission,
    this.startCutOff,
    this.endCutOff,
  });

  bool get isPrepaid => !isPostpaid;

  factory DigitalProduct.fromJson(Map<String, dynamic> json) {
    final rawSellingPrice = (json['sellingPrice'] ?? json['selling_price'] ?? json['price'] ?? 0).toDouble();
    final rawPrice = (json['price'] ?? rawSellingPrice).toDouble();
    final bool postpaid = json['isPostpaid'] ?? json['is_postpaid'] ?? false;

    return DigitalProduct(
      id: json['id'] ?? 0,
      sku: json['sku'] ?? json['buyerSkuCode'] ?? json['buyer_sku_code'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? '',
      sellerName: json['sellerName'] ?? json['seller_name'] ?? '',
      price: rawSellingPrice > 0 ? rawSellingPrice : rawPrice,
      sellingPrice: rawSellingPrice > 0 ? rawSellingPrice : rawPrice,
      buyerSkuCode: json['buyerSkuCode'] ?? json['buyer_sku_code'] ?? '',
      buyerProductStatus: json['buyerProductStatus'] ?? json['buyer_product_status'] ?? true,
      sellerProductStatus: json['sellerProductStatus'] ?? json['seller_product_status'] ?? true,
      unlimitedStock: json['unlimitedStock'] ?? json['unlimited_stock'] ?? true,
      stock: json['stock'] ?? 0,
      multi: json['multi'] ?? false,
      faultTolerant: json['faultTolerant'] ?? json['fault_tolerant'] ?? false,
      cutOff: json['cutOff'] ?? json['cut_off'] ?? false,
      desc: json['desc'] ?? json['description'],
      isActive: json['isActive'] ??
          ((json['buyerProductStatus'] ?? json['buyer_product_status'] ?? true) &&
              (json['sellerProductStatus'] ?? json['seller_product_status'] ?? true)),
      isPostpaid: postpaid,
      admin: (json['admin'] as num?)?.toDouble(),
      commission: (json['commission'] as num?)?.toDouble(),
      startCutOff: json['startCutOff'] ?? json['start_cut_off'],
      endCutOff: json['endCutOff'] ?? json['end_cut_off'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'productName': productName,
      'category': category,
      'brand': brand,
      'type': type,
      'sellerName': sellerName,
      'price': price,
      'sellingPrice': sellingPrice,
      'buyerSkuCode': buyerSkuCode,
      'buyerProductStatus': buyerProductStatus,
      'sellerProductStatus': sellerProductStatus,
      'unlimitedStock': unlimitedStock,
      'stock': stock,
      'multi': multi,
      'faultTolerant': faultTolerant,
      'cutOff': cutOff,
      'desc': desc,
      'isActive': isActive,
      'isPostpaid': isPostpaid,
      'admin': admin,
      'commission': commission,
      'startCutOff': startCutOff,
      'endCutOff': endCutOff,
    };
  }
}
